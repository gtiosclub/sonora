//
//  StreakAchievementService.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 11/16/26.
//

import FirebaseFirestore

enum StreakAchievementService {
    /// Streak tiers every 5 days: 5, 10, 15, ...
    static let streakTierSize = 5

    /// A user holds one streak badge at a time, stored at Users/{uid}/EarnedAchievements/streak
    private static func streakBadgeRef(userId: String) -> DocumentReference {
        Firestore.firestore()
            .collection("Users").document(userId)
            .collection("EarnedAchievements").document(AchievementDefinition.Category.streak.rawValue)
    }

    /// The badge for the highest tier this streak has reached, or nil under 5 days
    static func streakAchievement(for streak: Int) -> AchievementDefinition? {
        let tier = streak / streakTierSize * streakTierSize
        guard tier > 0 else { return nil }
        return AchievementDefinition(
            id: "streak-\(tier)",
            name: "\(tier)-day streak",
            description: "Practice \(tier) days in a row",
            artworkName: "🔥",
            category: .streak,
            target: tier
        )
    }

    /// The definition for a saved streak badge ("streak-10" -> 10-day streak)
    static func streakAchievement(for earned: EarnedAchievement) -> AchievementDefinition? {
        Int(earned.achievementId.replacingOccurrences(of: "streak-", with: "")).flatMap(streakAchievement(for:))
    }

    /// Makes the user's streak badge in Firebase match their current streak:
    /// new tier -> replace, same tier -> keep (and its earnedAt), under 5 days -> delete
    static func syncStreakAchievement(userId: String, streak: Int) async throws {
        let ref = streakBadgeRef(userId: userId)
        guard let badge = streakAchievement(for: streak) else {
            try await ref.delete()
            return
        }

        let current = try? await ref.getDocument().data(as: EarnedAchievement.self)
        guard current?.achievementId != badge.id else { return }

        let earned = EarnedAchievement(userId: userId, achievementId: badge.id, earnedAt: Date())
        try ref.setData(from: earned)
    }

    /// The user's current streak badge, or nil if they don't have one
    static func fetchStreakAchievement(userId: String) async throws -> EarnedAchievement? {
        let snapshot = try await streakBadgeRef(userId: userId).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: EarnedAchievement.self)
    }
}
