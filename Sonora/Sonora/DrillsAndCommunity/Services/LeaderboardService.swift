//
//  LeaderboardService.swift
//  Sonora
//
//  Created by Eshaan Dixit on 11/28/26.
//

import FirebaseFirestore

// MARK: - Models

enum LeaderboardPeriod: String, CaseIterable, Identifiable {
    case weekly, lifetime
    var id: Self { self }

    var title: String {
        switch self {
        case .weekly: "This week"
        case .lifetime: "All-time"
        }
    }
}

enum LeaderboardScope: String, CaseIterable, Identifiable {
    case everyone, friends
    var id: Self { self }

    var title: String {
        switch self {
        case .everyone: "Everyone"
        case .friends: "Friends"
        }
    }
}

struct LeaderboardEntry: Identifiable, Equatable {
    let userId: String
    let username: String
    /// Shared ranks for ties: 1, 2, 2, 4.
    let rank: Int
    let xp: Int

    var id: String { userId }
}

/// What the leaderboard screen needs: the ranked list and the signed-in user's own spot.
struct Leaderboard: Equatable {
    let entries: [LeaderboardEntry]
    /// Always present, even when the user is outside `entries`.
    let currentUser: LeaderboardEntry
}

// MARK: - Weeks

/// Leaderboard weeks run Sunday 00:00 to Sunday 00:00 US Eastern time
/// (America/New_York, so daylight saving is handled).
enum LeaderboardWeek {
    static let timeZone = TimeZone(identifier: "America/New_York")!

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 1 // Sunday
        return calendar
    }

    /// Sunday 00:00 ET of the week containing `date`.
    static func start(of date: Date = .now) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)!.start
    }

    /// When the current weekly leaderboard resets.
    static func nextReset(after date: Date = .now) -> Date {
        calendar.date(byAdding: .day, value: 7, to: start(of: date))!
    }

    /// The week's ID, e.g. "2026-11-29" (that Sunday's date in ET). Used as the Firestore document ID.
    static func key(for date: Date = .now) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: start(of: date))
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    /// `WeeklyXP/{weekKey}/users/{userId}`: one document per user per week. A new
    /// week writes to a new collection, so the reset needs no server job and old
    /// weeks are kept (for weekly wins).
    static func usersCollection(weekKey: String) -> CollectionReference {
        Firestore.firestore().collection("WeeklyXP").document(weekKey).collection("users")
    }

    /// Fields to merge into a user's weekly document when they earn `xp`.
    static func xpUpdate(userId: String, weekKey: String, xp: Int) -> [String: Any] {
        [
            "userId": userId,
            "weekStart": weekKey,
            "xp": FieldValue.increment(Int64(max(0, xp))),
        ]
    }
}

// MARK: - Loading

enum LeaderboardService {
    static let pageSize = 50

    static func load(
        period: LeaderboardPeriod,
        scope: LeaderboardScope,
        userId: String,
        friendIds: [String] = []
    ) async throws -> Leaderboard {
        switch scope {
        case .everyone: try await loadEveryone(period: period, userId: userId)
        case .friends: try await loadGroup(period: period, userIds: [userId] + friendIds, currentUserId: userId)
        }
    }

    /// Accepted friends' user IDs for the signed-in user.
    static func friendIds(for userId: String) async throws -> [String] {
        try await FriendshipService().fetchFriends().compactMap { $0.otherUserId(for: userId) }
    }

    // MARK: Everyone

    private static func loadEveryone(period: LeaderboardPeriod, userId: String) async throws -> Leaderboard {
        let source = XPSource(period: period)

        let top = try await source.collection
            .order(by: source.field, descending: true)
            .limit(to: pageSize)
            .getDocuments()
            .documents
            .map { (userId: $0.documentID, xp: ($0.get(source.field) as? Int) ?? 0) }

        // My XP, and my global rank: 1 + how many users have strictly more XP.
        let myXP = (try await source.collection.document(userId).getDocument().get(source.field) as? Int) ?? 0
        let higher = try await source.collection
            .whereField(source.field, isGreaterThan: myXP)
            .count
            .getAggregation(source: .server)
            .count
            .intValue

        let names = try await usernames(for: top.map(\.userId) + [userId])
        let entries = ranked(top).map { row in
            LeaderboardEntry(userId: row.userId, username: names[row.userId] ?? "Player", rank: row.rank, xp: row.xp)
        }
        let me = LeaderboardEntry(userId: userId, username: names[userId] ?? "You", rank: higher + 1, xp: myXP)
        return Leaderboard(entries: entries, currentUser: me)
    }

    // MARK: Friends

    /// Ranks a fixed group (you + friends), including members with 0 XP.
    private static func loadGroup(period: LeaderboardPeriod, userIds: [String], currentUserId: String) async throws -> Leaderboard {
        let source = XPSource(period: period)
        let ids = Array(Set(userIds))

        var xpById: [String: Int] = [:]
        for chunk in ids.chunked(into: 30) { // Firestore "in" queries take at most 30 IDs
            let snapshot = try await source.collection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            for doc in snapshot.documents {
                xpById[doc.documentID] = (doc.get(source.field) as? Int) ?? 0
            }
        }

        let names = try await usernames(for: ids)
        let all = ranked(ids.map { (userId: $0, xp: xpById[$0] ?? 0) }).map { row in
            LeaderboardEntry(userId: row.userId, username: names[row.userId] ?? "Player", rank: row.rank, xp: row.xp)
        }
        let me = all.first { $0.userId == currentUserId }
            ?? LeaderboardEntry(userId: currentUserId, username: names[currentUserId] ?? "You", rank: all.count + 1, xp: 0)
        return Leaderboard(entries: Array(all.prefix(pageSize)), currentUser: me)
    }

    // MARK: Helpers

    /// Where each period's XP lives in Firestore.
    private struct XPSource {
        let collection: CollectionReference
        let field: String

        init(period: LeaderboardPeriod) {
            switch period {
            case .lifetime:
                collection = Firestore.firestore().collection("UserProgress")
                field = "lifetimeXP"
            case .weekly:
                collection = LeaderboardWeek.usersCollection(weekKey: LeaderboardWeek.key())
                field = "xp"
            }
        }
    }

    /// Sorts by XP (highest first) and assigns shared ranks: 1, 2, 2, 4.
    /// Ties are listed alphabetically by user ID so the order is stable.
    static func ranked(_ rows: [(userId: String, xp: Int)]) -> [(userId: String, xp: Int, rank: Int)] {
        let sorted = rows.sorted { $0.xp != $1.xp ? $0.xp > $1.xp : $0.userId < $1.userId }
        var result: [(userId: String, xp: Int, rank: Int)] = []
        for (index, row) in sorted.enumerated() {
            let rank = (index > 0 && row.xp == sorted[index - 1].xp) ? result[index - 1].rank : index + 1
            result.append((row.userId, row.xp, rank))
        }
        return result
    }

    /// Usernames from `Users/{userId}`, looked up 30 at a time.
    private static func usernames(for userIds: [String]) async throws -> [String: String] {
        var names: [String: String] = [:]
        for chunk in Array(Set(userIds)).chunked(into: 30) {
            let snapshot = try await Firestore.firestore().collection("Users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            for doc in snapshot.documents {
                if let name = doc.get("username") as? String { names[doc.documentID] = name }
            }
        }
        return names
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0 ..< Swift.min($0 + size, count)]) }
    }
}
