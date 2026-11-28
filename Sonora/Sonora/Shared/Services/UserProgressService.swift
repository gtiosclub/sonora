//
//  UserProgressService.swift
//  Sonora
//
//  Created by Sean Kim on 11/12/26.
//

import FirebaseFirestore

enum UserProgressService {
    private static var progress: CollectionReference {
        Firestore.firestore().collection("UserProgress")
    }

    static func record(userId: String, sessions: Int = 0, drills: Int = 0, xp: Int) async throws {
        // One batch so lifetime and weekly XP are written together.
        let batch = Firestore.firestore().batch()
        batch.setData([
            "id": userId,
            "completedSessions": FieldValue.increment(Int64(sessions)),
            "completedDrills": FieldValue.increment(Int64(drills)),
            "lifetimeXP": FieldValue.increment(Int64(xp))
        ], forDocument: progress.document(userId), merge: true)
        if xp > 0 {
            let week = LeaderboardWeek.key()
            batch.setData(LeaderboardWeek.xpUpdate(userId: userId, weekKey: week, xp: xp),
                          forDocument: LeaderboardWeek.usersCollection(weekKey: week).document(userId), merge: true)
        }
        try await batch.commit()
    }

    static func fetch(for userId: String) async throws -> UserProgress {
        let snapshot = try await progress.document(userId).getDocument()
        guard snapshot.exists else { return UserProgress(id: userId) }
        return try snapshot.data(as: UserProgress.self)
    }

    // MARK: - Sessions

    /// Call once per participant, on that participant's own device, after the
    /// session's scores exist. Adds +1 completedSessions and the session's XP.
    ///
    /// Safe to call twice: the session document remembers who has been counted
    /// (`countedFor`), so a repeat call does nothing.
    ///
    /// Order matters: this reads the user's CURRENT SkillProfile to measure
    /// improvement, so call it BEFORE saving the new scores into SkillProfile.
    static func recordSessionCompletion(
        sessionID: String,
        userId: String,
        scores: SessionSkillScore
    ) async throws {
        // Old SkillProfile docs may not decode; fall back to the sign-up defaults.
        let previous = (try? await SkillProfileService.fetch(for: userId))
            ?? SkillProfile.makeNew(userId: userId)
        let xp = XPService.sessionXP(scores: scores, previous: previous)

        let db = Firestore.firestore()
        let sessionRef = db.collection("Sessions").document(sessionID)
        let progressRef = progress.document(userId)
        let week = LeaderboardWeek.key()
        let weeklyRef = LeaderboardWeek.usersCollection(weekKey: week).document(userId)
        let weeklyUpdate = LeaderboardWeek.xpUpdate(userId: userId, weekKey: week, xp: xp)

        // A transaction reads and writes as one step, so two calls can't both pass the check.
        _ = try await db.runTransaction { txn, errorPointer in
            let snap: DocumentSnapshot
            do { snap = try txn.getDocument(sessionRef) }
            catch { errorPointer?.pointee = error as NSError; return nil }

            guard snap.exists else {
                errorPointer?.pointee = NSError(
                    domain: "UserProgressService", code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Session \(sessionID) not found"])
                return nil
            }

            let counted = snap.get("countedFor") as? [String] ?? []
            guard !counted.contains(userId) else { return nil } // already counted

            txn.updateData(
                ["countedFor": FieldValue.arrayUnion([userId])],
                forDocument: sessionRef
            )
            txn.setData([
                "id": userId,
                "completedSessions": FieldValue.increment(Int64(1)),
                "lifetimeXP": FieldValue.increment(Int64(max(0, xp)))
            ], forDocument: progressRef, merge: true)
            if xp > 0 { txn.setData(weeklyUpdate, forDocument: weeklyRef, merge: true) }
            return nil
        }
        
        do {
            try await AchievementService.evaluate(userId: userId, sourceId: sessionID)
        }
        catch {
            print("Achievement check failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Drills

    /// Call once when a drill finishes. Adds +1 completedDrills and the drill's XP.
    ///
    /// Safe to call twice: a marker document at
    /// `UserProgress/{uid}/countedDrills/{drillId}` records that this drill was counted.
    static func recordDrillCompletion(_ drill: Drill) async throws {
        let xp = XPService.drillXP(for: drill)

        let db = Firestore.firestore()
        let progressRef = progress.document(drill.userId)
        let markerRef = progressRef.collection("countedDrills").document(drill.id)
        let week = LeaderboardWeek.key()
        let weeklyRef = LeaderboardWeek.usersCollection(weekKey: week).document(drill.userId)
        let weeklyUpdate = LeaderboardWeek.xpUpdate(userId: drill.userId, weekKey: week, xp: xp)

        _ = try await db.runTransaction { txn, errorPointer in
            let marker: DocumentSnapshot
            do { marker = try txn.getDocument(markerRef) }
            catch { errorPointer?.pointee = error as NSError; return nil }

            guard !marker.exists else { return nil } // already counted

            txn.setData(["countedAt": Timestamp(date: Date())], forDocument: markerRef)
            txn.setData([
                "id": drill.userId,
                "completedDrills": FieldValue.increment(Int64(1)),
                "lifetimeXP": FieldValue.increment(Int64(max(0, xp)))
            ], forDocument: progressRef, merge: true)
            if xp > 0 { txn.setData(weeklyUpdate, forDocument: weeklyRef, merge: true) }
            return nil
        }
        
        do {
            try await AchievementService.evaluate(userId: drill.userId, sourceId: drill.id)
        }
        catch {
            print("Achievement check failed: \(error.localizedDescription)")
        }
    }
}
