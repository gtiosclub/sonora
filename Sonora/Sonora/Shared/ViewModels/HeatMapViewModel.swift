//
//  HeatMapViewModel.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/1/26.
//

import Foundation
import Combine

enum HeatMapMetric: String, CaseIterable, Identifiable {
    case improvement = "Improvement"  // change vs. the previous session
    case score = "Score"              // raw 0-100 score

    var id: String { rawValue }
}

final class HeatMapViewModel: ObservableObject {
    @Published var sessionScores: [SessionSkillScore]
    @Published var metric: HeatMapMetric = .improvement
    @Published var lowestColor: RGBColor
    @Published var highestColor: RGBColor

    let skills = Skill.allCases

    var legendLabels: (low: String, high: String) {
        switch metric {
        case .improvement: return ("Declined", "Improved")
        case .score: return ("Low", "High")
        }
    }
    
    init(
        sessionScores: [SessionSkillScore] = [],
        lowestColor: RGBColor = RGBColor(red: 0.55, green: 0.63, blue: 1.00),
        highestColor: RGBColor = RGBColor(red: 1.00, green: 0.70, blue: 0.25)
    ) {
        self.sessionScores = sessionScores
        self.lowestColor = lowestColor
        self.highestColor = highestColor
    }

    /// Rows = skills (y-axis), columns = sessions (x-axis, oldest to newest).
    var grid: [[RGBColor]] {
        Self.heatMapFormation(
            lowest: lowestColor,
            highest: highestColor,
            sessions: sessionScores,
            metric: metric
        )
    }

    /// The most recent sessions shown, in the same order as the grid's columns.
    var displayedSessions: [SessionSkillScore] {
        Self.prepare(sessionScores)
    }

    // MARK: - HeatMapFormation

    /// Input:  lowest color, highest color, 5-15 sessions
    /// Output: 2D array of colors, [skillRow][sessionColumn]
    static func heatMapFormation(
        lowest: RGBColor,
        highest: RGBColor,
        sessions: [SessionSkillScore],
        metric: HeatMapMetric
    ) -> [[RGBColor]] {
        let sessions = prepare(sessions)
        guard !sessions.isEmpty else { return [] }

        // 1. Raw numbers: one row per skill, one column per session
        let values: [[Double]] = Skill.allCases.map { skill in
            let scores = sessions.map { Double($0.value(for: skill)) }
            switch metric {
            case .score:
                return scores
            case .improvement:
                // First session has nothing to compare to, so its change is 0
                return scores.indices.map { i in i == 0 ? 0 : scores[i] - scores[i - 1] }
            }
        }

        // 2. Normalize each number to 0...1
        let normalized: [[Double]]
        switch metric {
        case .score:
            normalized = values.map { $0.map { $0 / 100.0 } }
        case .improvement:
            // Symmetric around 0, so "no change" lands in the middle of the gradient
            let maxAbs = values.flatMap { $0 }.map { abs($0) }.max() ?? 0
            normalized = values.map {
                $0.map { maxAbs == 0 ? 0.5 : (($0 / maxAbs) + 1) / 2 }
            }
        }

        // 3. Map 0...1 onto the lowest-highest color gradient
        return normalized.map { row in
            row.map { RGBColor.interpolate(from: lowest, to: highest, t: $0) }
        }
    }

    /// Sort oldest to newest and keep the latest 15.
    private static func prepare(_ sessions: [SessionSkillScore]) -> [SessionSkillScore] {
        Array(sessions.sorted { $0.date < $1.date }.suffix(15))
    }
}
