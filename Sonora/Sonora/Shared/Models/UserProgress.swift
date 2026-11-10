//
//  UserProgress.swift
//  Sonora
//

import Foundation

/// A user's cumulative totals used to evaluate achievement requirements.
struct UserProgress: Identifiable, Codable, Equatable {
    /// Matches the user's ID.
    var id: String

    var completedSessions: Int = 0

    /// All XP earned over time, independent of any spendable balance.
    var lifetimeXP: Int = 0

    var completedDrills: Int = 0
    var weeklyWins: Int = 0
}
