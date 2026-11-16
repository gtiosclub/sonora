//
//  AchievementDefinition.swift
//  Sonora
//

import Foundation

/// A shared badge and the milestone required to earn it.
struct AchievementDefinition: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var description: String
    var artworkName: String
    var category: Category

    /// The minimum total needed in the selected category.
    var target: Int

    enum Category: String, Codable, CaseIterable {
        case sessions
        case xp
        case drills
        case weeklyWins
        case streak
    }
}
