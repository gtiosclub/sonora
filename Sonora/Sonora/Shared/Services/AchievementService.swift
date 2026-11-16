//
//  AchievementService.swift
//  Sonora
//
//  Created by Sean Kim on 11/16/26.
//

import FirebaseFirestore

enum AchievementService {
    private static func earnedRef(_ userId: String) -> CollectionReference {
        Firestore.firestore().collection("UserProgress").document(userId)
            .collection("earnedAchievements")
    }

    /// Gives the user any badge whose target they've reached and that they don't have yet.
    /// `sourceId` is the session or drill that triggered the check.
    static func evaluate(userId: String, sourceId: String? = nil) async throws {
        let progress = try await UserProgressService.fetch(for: userId)
        let have = Set(try await earnedRef(userId).getDocuments().documents.map(\.documentID))

        let batch = Firestore.firestore().batch()
        var awarded = 0
        for def in AchievementCatalog.all where !have.contains(def.id) {
            guard total(for: def.category, in: progress) >= def.target else { continue }
            let earned = EarnedAchievement(userId: userId, achievementId: def.id,
                                           earnedAt: Date(), sourceId: sourceId)
            try batch.setData(from: earned, forDocument: earnedRef(userId).document(def.id))
            awarded += 1
        }
        if awarded > 0 { try await batch.commit() }
    }

    /// Every badge this user has earned.
    static func fetchEarned(userId: String) async throws -> [EarnedAchievement] {
        try await earnedRef(userId).getDocuments().documents
            .map { try $0.data(as: EarnedAchievement.self) }
    }

    private static func total(for category: AchievementDefinition.Category, in p: UserProgress) -> Int {
        switch category {
        case .sessions:   p.completedSessions
        case .drills:     p.completedDrills
        case .xp:         p.lifetimeXP
        case .weeklyWins: p.weeklyWins
        case .streak:     0   // not tracked in UserProgress yet
        }
    }
}
