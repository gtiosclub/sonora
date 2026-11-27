//
//  AchievementCatalog.swift
//  Sonora
//
//  Created by Sean Kim on 11/16/26.
//

import Foundation

enum AchievementCatalog {
    static let thresholds = [1, 3, 5, 10, 25, 50, 75, 100]

    private static let drillNames   = ["First Drill", "Warming Up", "High Five", "Drill Regular",
                                       "Drill Pro", "Drill Master", "Drill Legend", "Drill Centurion"]
    private static let drillEmojis  = ["🎯", "🔥", "⭐️", "🏅", "🏆", "💎", "👑", "🚀"]

    private static let sessionNames  = ["First Session", "Getting Going", "High Five", "Regular Speaker",
                                        "Seasoned Speaker", "Stage Veteran", "Crowd Favorite", "Centurion"]
    private static let sessionEmojis = ["🎤", "🗣️", "📣", "🎙️", "🌟", "💫", "🥇", "🦁"]

    static let all: [AchievementDefinition] = {
        var list: [AchievementDefinition] = []
        for (i, n) in thresholds.enumerated() {
            list.append(AchievementDefinition(
                id: "drills_\(n)", name: drillNames[i],
                description: "Complete \(n) drill\(n == 1 ? "" : "s")",
                emoji: drillEmojis[i], artworkName: "",
                category: .drills, target: n))
            list.append(AchievementDefinition(
                id: "sessions_\(n)", name: sessionNames[i],
                description: "Complete \(n) session\(n == 1 ? "" : "s")",
                emoji: sessionEmojis[i], artworkName: "",
                category: .sessions, target: n))
        }
        return list
    }()
}
