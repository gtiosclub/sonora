//
//  User.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/13/26.
//

import Foundation

struct User: Codable, Equatable, Identifiable {
    var id: String {userId} // conform to identifiable
    // MARK: MANDATORY
    var userId: String
    var username: String
    var email: String
    var lastLogin: Date
    var streak: Int
    var skillProfile: SkillProfile
    // MARK: MANDATORY
    
    // MARK: FOR STREAK LOGIC
    var lastDrillDate: Date?
    
    mutating func checkStreak() {
        guard let lastDrillDate = lastDrillDate else {
            streak = 0
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDrillDay = calendar.startOfDay(for: lastDrillDate)

        let daysSinceLastDrill = calendar.dateComponents(
            [.day],
            from: lastDrillDay,
            to: today
        ).day ?? 0

        if daysSinceLastDrill > 1 {
            streak = 0
        }
    }
}

