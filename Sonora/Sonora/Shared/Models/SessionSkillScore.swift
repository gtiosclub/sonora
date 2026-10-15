//
//  SessionSkillScore.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/1/26.
//

import Foundation

/// Skill scores earned in ONE session (the x-axis of the heatmap).
struct SessionSkillScore: Identifiable, Codable, Equatable {
    var id: String //session_id
    var userId: String

    var content: Skill
    var engagement: Skill
    var clarity: Skill
    var confidence: Skill

    func value(for skill: Skill) -> Int {
        return skill.score
    }
}

