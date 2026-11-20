//
//  EarnedAchievement.swift
//  Sonora
//

import Foundation

/// A user's ownership of a badge, stored separately from its shared definition.
struct EarnedAchievement: Identifiable, Codable, Equatable {
    /// Unique within this user's earned-achievement collection.
    var id: String { achievementId }
    var userId: String
    var achievementId: String
    var earnedAt: Date

    /// The session, completed drill attempt, or leaderboard week that earned it.
    var sourceId: String? = nil
}
