//
//  SessionFeedback+Rubric.swift
//  Sonora
//
//  Bridges the rubric scoring output (SessionScorer.Result) into the display
//  model SessionFeedbackView (screen 4) renders.
//

import SwiftUI

extension SessionFeedback {

    /// Shown while the pipelines are still running.
    static let loading = SessionFeedback(
        sessionType: "Session",
        duration: "—",
        overallScore: 0,
        pointsChange: 0,
        skills: [],
        timeline: [],
        moment: ReviewMoment(timestamp: "0:00", message: "Analyzing…", position: 0),
        recentScores: [0, 0],
        progressChange: 0
    )

    /// Builds screen-4 display data from an analysis result. Shows the four
    /// rubric categories as the skill bars; Content reads "Not scored yet" because
    /// it needs the LLM layer.
    static func make(_ result: SessionAnalyzer.Result, speechType: SpeechType) -> SessionFeedback {
        let scores = result.report.scores
        let skills = [
            categoryBar("Speaking clarity", scores.clarity),
            categoryBar("Confidence", scores.confidence),
            categoryBar("Engaging", scores.engagement),
            pendingBar("Content")   // LLM not wired yet
        ]

        let duration = max(result.transcript.words.last?.end ?? 0, 1)
        let moment: ReviewMoment
        if let first = result.report.findings.first {
            moment = ReviewMoment(
                timestamp: first.start.asClock,
                message: first.message,
                position: min(max(first.start / duration, 0), 1)
            )
        } else {
            moment = ReviewMoment(timestamp: "0:00", message: "No moments flagged — nice work!", position: 0)
        }

        return SessionFeedback(
            sessionType: speechType.rawValue.capitalized,
            duration: duration.asSpoken,
            overallScore: result.overall,
            pointsChange: 0,
            skills: skills,
            timeline: [TimelineSegment(start: 0, end: 1, color: Theme.blueLight)],
            moment: moment,
            // No session history yet, so the Progress sparkline is a flat placeholder.
            recentScores: Array(repeating: Double(result.overall), count: 6),
            progressChange: 0
        )
    }

    // MARK: - Helpers

    private static func categoryBar(_ name: String, _ value: Int) -> SkillMetric {
        let good = value >= 80
        return SkillMetric(
            name: name,
            progress: Double(value) / 100,
            valueLabel: "\(value)",
            barColor: good ? Theme.blue : Theme.orange,
            labelColor: good ? Theme.blue : Theme.orangeText
        )
    }

    private static func pendingBar(_ name: String) -> SkillMetric {
        SkillMetric(
            name: name,
            progress: 0,
            valueLabel: "Not scored yet",
            barColor: Theme.track,
            labelColor: Theme.textSecondary
        )
    }
}
