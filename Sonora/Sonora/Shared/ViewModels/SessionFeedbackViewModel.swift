//
//  SessionFeedbackViewModel.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/7/26.
//

import Foundation
import Observation

@Observable
final class SessionFeedbackViewModel {

    // MARK: - Inputs
    let session: Session
    let feedback: SessionFeedback

    /// Navigation hooks, set by whoever presents this screen.
    var onReviewMoment: (ReviewMoment) -> Void
    var onSeeRecommendations: () -> Void

    init(
        session: Session,
        feedback: SessionFeedback,
        onReviewMoment: @escaping (ReviewMoment) -> Void = { _ in },
        onSeeRecommendations: @escaping () -> Void = {}
    ) {
        self.session = session
        self.feedback = feedback
        self.onReviewMoment = onReviewMoment
        self.onSeeRecommendations = onSeeRecommendations
    }

    // MARK: - Header
    var subtitle: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return "\(session.mode.rawValue.capitalized) · \(minutes) min \(seconds) sec"
    }

    // MARK: - Overall
    var overallScoreText: String { "\(feedback.overallScore)" }

    /// nil when there is no previous session to compare to.
    var deltaText: String? {
        guard let previous = feedback.previousScore else { return nil }
        let diff = feedback.overallScore - previous
        let arrow = diff >= 0 ? "↑" : "↓"
        return "\(arrow) \(abs(diff)) points"
    }

    var deltaIsPositive: Bool {
        (feedback.overallScore - (feedback.previousScore ?? feedback.overallScore)) >= 0
    }

    // MARK: - Summary
    var summary: String { feedback.summary }
    var strength: String { feedback.strength }
    var focusArea: String { feedback.focusArea }

    // MARK: - Skills
    private let maxPaceWPM = 190.0

    var paceText: String { "\(feedback.paceWPM) WPM" }
    var paceFraction: Double { min(Double(feedback.paceWPM) / maxPaceWPM, 1) }

    var voiceFraction: Double { feedback.voiceModulation }
    var voiceNeedsWork: Bool { feedback.voiceModulation < 0.6 }
    var voiceLabel: String { voiceNeedsWork ? "Needs variety" : "Strong" }

    var postureFraction: Double { feedback.posture }
    var postureText: String { "\(Int((feedback.posture * 100).rounded()))%" }

    // MARK: - Moments
    var durationSeconds: Int { session.durationSeconds ?? 0 }
    var featuredMoment: ReviewMoment? { feedback.moments.first }

    func timestamp(for moment: ReviewMoment) -> String {
        String(format: "%d:%02d", moment.startSeconds / 60, moment.startSeconds % 60)
    }

    func reviewTapped(_ moment: ReviewMoment) { onReviewMoment(moment) }

    // MARK: - Progress
    var recentScores: [Int] { feedback.recentScores }

    /// Percent change from the oldest to newest score in the window.
    var progressText: String? {
        guard let first = feedback.recentScores.first,
              let last = feedback.recentScores.last,
              first > 0 else { return nil }
        let change = Int((Double(last - first) / Double(first) * 100).rounded())
        return "\(change >= 0 ? "+" : "")\(change)%"
    }

    var progressLabel: String { "LAST \(feedback.recentScores.count) SESSIONS" }

    // MARK: - Actions
    func seeRecommendationsTapped() { onSeeRecommendations() }
}
