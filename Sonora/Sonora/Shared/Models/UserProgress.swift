//
//  UserProgress.swift
//  Sonora
//

import Foundation

/// A user's cumulative totals used to evaluate achievement requirements.
struct UserProgress: Identifiable, Codable, Equatable {
    /// Needed because declaring `init(from:)` below turns off the automatic memberwise init.
    init(
        id: String,
        completedSessions: Int = 0,
        lifetimeXP: Int = 0,
        completedDrills: Int = 0,
        weeklyWins: Int = 0
    ) {
        self.id = id
        self.completedSessions = completedSessions
        self.lifetimeXP = lifetimeXP
        self.completedDrills = completedDrills
        self.weeklyWins = weeklyWins
    }

    /// Missing fields decode as 0, since a document made by an increment write may lack some counters.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        completedSessions = try c.decodeIfPresent(Int.self, forKey: .completedSessions) ?? 0
        lifetimeXP = try c.decodeIfPresent(Int.self, forKey: .lifetimeXP) ?? 0
        completedDrills = try c.decodeIfPresent(Int.self, forKey: .completedDrills) ?? 0
        weeklyWins = try c.decodeIfPresent(Int.self, forKey: .weeklyWins) ?? 0
    }
    
    /// Matches the user's ID.
    var id: String

    var completedSessions: Int = 0

    /// All XP earned over time, independent of any spendable balance.
    var lifetimeXP: Int = 0

    var completedDrills: Int = 0
    var weeklyWins: Int = 0
}
