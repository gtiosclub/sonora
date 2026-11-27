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

/// One row of the redesigned heatmap (already in display order).
struct HeatMapRow: Identifiable {
    let name: String
    let colors: [RGBColor]
    var id: String { name }
}

@MainActor
final class SpeakingProgressViewModel: ObservableObject {

    let title = "Speaking Progress"
    let subtitle = "Your growth, session by session"

    let heatMapViewModel: HeatMapViewModel
    private let sessionScores: [SessionSkillScore]

    /// Index of the tapped heatmap column (nil = nothing selected).
    @Published var selectedSession: Int?

    /// Row order in the new design (the heatmap data itself keeps its own order).
    static let displayOrder = ["Clarity", "Content", "Engagement", "Confidence"]

    init(sessionScores: [SessionSkillScore]? = nil) {
        // nil -> sample data (swap for real data once Firebase is connected)
        let scores = sessionScores ?? exampleSessionScores
        self.sessionScores = scores
        // Plum gradient from the new design (light lavender -> deep plum #504E76)
        self.heatMapViewModel = HeatMapViewModel(
            sessionScores: scores,
            lowestColor: RGBColor(red: 0.89, green: 0.89, blue: 0.96),
            highestColor: RGBColor(red: 80 / 255, green: 78 / 255, blue: 118 / 255)
        )
    }

    var hasSessions: Bool { !sessionScores.isEmpty }

    // MARK: - Heatmap (new design)

    /// Heatmap rows reordered to Clarity, Content, Engaging, Confidence.
    var heatMapRows: [HeatMapRow] {
        let grid = heatMapViewModel.grid
        let names = heatMapViewModel.skills
        return Self.displayOrder.compactMap { name in
            guard let i = names.firstIndex(of: name), i < grid.count else { return nil }
            return HeatMapRow(name: name, colors: grid[i])
        }
    }

    /// Short label next to the heatmap rows.
    static func heatMapLabel(_ name: String) -> String { name == "Engagement" ? "Engaging" : name }

    /// Title in the detail card.
    static func cardTitle(_ name: String) -> String {
        switch name {
        case "Clarity": return "Speaking Clarity"
        case "Engagement": return "Engaging"
        default: return name
        }
    }

    // MARK: - Session selection

    var selectorTitle: String {
        selectedSession.map { "Session #\($0 + 1)" } ?? "Select a session"
    }

    func selectSession(_ index: Int) {
        selectedSession = (selectedSession == index) ? nil : index
    }

    /// Tapping the green bar: collapse if open, otherwise open the latest session.
    func toggleSelector() {
        if selectedSession != nil {
            selectedSession = nil
        } else {
            let count = heatMapViewModel.displayedSessions.count
            selectedSession = count > 0 ? count - 1 : nil
        }
    }

    /// Skill rows for one heatmap column, in display order.
    func skills(forSession index: Int) -> [SkillSummary] {
        let sessions = heatMapViewModel.displayedSessions
        guard sessions.indices.contains(index) else { return [] }
        let s = sessions[index]
        let byName: [String: Skill] = [
            "Clarity": s.clarity, "Content": s.content,
            "Engagement": s.engagement, "Confidence": s.confidence
        ]
        return Self.displayOrder.compactMap { name in byName[name].map { summary(name, $0) } }
    }

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
