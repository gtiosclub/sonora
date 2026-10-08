//
//  SessionSkillScore.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/1/26.
//

import Foundation

/// The skills shown on the heatmap's y-axis. Matches SkillProfile.
enum Skill: String, CaseIterable, Identifiable {
    case content, engagement, speakingClarity, confidence

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .content: return "Content"
        case .engagement: return "Engagement"
        case .speakingClarity: return "Clarity"
        case .confidence: return "Confidence"
        }
    }
}

/// Skill scores earned in ONE session (the x-axis of the heatmap).
struct SessionSkillScore: Identifiable, Codable, Equatable {
    var id: String
    var sessionId: String
    var userId: String
    var date: Date

    var content: Int
    var engagement: Int
    var speakingClarity: Int
    var confidence: Int

    func value(for skill: Skill) -> Int {
        switch skill {
        case .content: return content
        case .engagement: return engagement
        case .speakingClarity: return speakingClarity
        case .confidence: return confidence
        }
    }
}
