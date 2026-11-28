//
//  DrillSessionStore.swift
//  Sonora
//
//  Created by Eshaan Dixit on 11/28/26.
//

import FirebaseFirestore

/// Loads the real sessions drills are generated from.
enum DrillSessionStore {
    /// The user's most recent completed sessions in `mode` that the analysis
    /// pipeline has finished with: they need a summary and this user's own
    /// skill scores, since the drill writer works from both.
    static func recentAnalyzedSessions(
        userId: String,
        mode: Session.Mode,
        limit: Int = 5
    ) async throws -> [Session] {
        // Same single-field query as HomeViewModel, so no composite index is
        // needed; the rest is filtered on the device.
        let snapshot = try await Firestore.firestore().collection("Sessions")
            .whereField("participants", arrayContains: userId)
            .getDocuments()

        let sessions = snapshot.documents
            .compactMap { try? $0.data(as: Session.self) }
            .filter { session in
                session.mode == mode
                    && session.status == .completed
                    && !(session.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    // Scores are stored once per session, so skip ones that
                    // belong to the other participant.
                    && session.sessionSkillScore?.userId == userId
            }
            .sorted { ($0.startTime ?? $0.createdAt) > ($1.startTime ?? $1.createdAt) }

        return Array(sessions.prefix(limit))
    }
}
