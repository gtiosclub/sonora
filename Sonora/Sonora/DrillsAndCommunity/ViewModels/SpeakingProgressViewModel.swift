//
//  SpeakingProgressViewModel.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/13/26.
//

//  ViewModel for the Speaking Progress screen: owns the
//  Heatmap's ViewModel and turns the latest session into skill rows.

import Foundation
import Combine

struct SkillSummary: Identifiable, Equatable {
    let name: String
    let score: Int          // 0-100
    let tip: String

    var id: String { name }
    var clampedScore: Int { min(max(score, 0), 100) }
    var fraction: Double { Double(clampedScore) / 100 }
    var scoreText: String { "\(clampedScore)/100" }
}

@MainActor
final class SpeakingProgressViewModel: ObservableObject {

    let title = "Speaking Progress"
    let subtitle = "Your growth, session by session"

    let heatMapViewModel: HeatMapViewModel
    private let sessionScores: [SessionSkillScore]

    init(sessionScores: [SessionSkillScore]? = nil) {
        // nil -> sample data (swap for real data once Firebase is connected)
        let scores = sessionScores ?? exampleSessionScores
        self.sessionScores = scores
        self.heatMapViewModel = HeatMapViewModel(sessionScores: scores)
    }

    var hasSessions: Bool { !sessionScores.isEmpty }

    /// Skill rows for the most recent session (same skill order as the heatmap).
    var latestSkills: [SkillSummary] {
        guard let last = sessionScores.last else { return [] }
        return [
            summary("Content", last.content),
            summary("Engagement", last.engagement),
            summary("Clarity", last.clarity),
            summary("Confidence", last.confidence)
        ]
    }

    // MARK: - Helpers
    /// Uses the Skill's own summary (e.g. AI-generated) when present,
    /// otherwise falls back to placeholder coaching text.
    private func summary(_ name: String, _ skill: Skill) -> SkillSummary {
        let stored = skill.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let tipText = stored.isEmpty ? tip(for: name, score: skill.score) : stored
        return SkillSummary(name: name, score: skill.score, tip: tipText)
    }

    /// Placeholder coaching text by score tier (low / medium / high).
    /// Swap for AI-generated summaries once they exist on the skill data.
    private func tip(for skill: String, score: Int) -> String {
        let tier = score >= 85 ? 2 : (score >= 70 ? 1 : 0)
        let tips: [String: [String]] = [
            "Content": [
                "Add a clear main idea and back it up with examples.",
                "Strong main ideas. Try adding more supporting examples.",
                "Excellent structure and well-supported points."
            ],
            "Engagement": [
                "Try more eye contact and varied expressions.",
                "Good audience engagement. Keep varying your delivery.",
                "Great energy and audience connection."
            ],
            "Clarity": [
                "Slow down and finish each sentence clearly.",
                "Clear overall. Watch filler words and trailing sentences.",
                "Very clear and easy to follow."
            ],
            "Confidence": [
                "Practice pausing and keeping a steady pace.",
                "Growing confidence. Keep your pace steady under pressure.",
                "Calm, steady and confident delivery."
            ]
        ]
        return tips[skill]?[tier] ?? ""
    }
}
