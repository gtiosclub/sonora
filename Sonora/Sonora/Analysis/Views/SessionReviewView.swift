//
//  SessionReviewView.swift
//  Sonora
//

import SwiftUI

/// Container for a finished session: shows the feedback summary (screen 4) and
/// pushes to the transcript/playback screen (screen 2/3). It owns the data loading
/// so the presentational views stay pure (they just take a value).
///
/// Pass a recording `videoURL` to analyze live. `savedTranscript` is an optional
/// offline fallback that's scored immediately while the live run catches up.
struct SessionReviewView: View {
    let videoURL: URL?
    var savedTranscript: Transcript? = nil
    var speechType: SpeechType = .interview

    // Held in @State so the analysis survives view re-creations: the heavy pipeline
    // runs once in a Task the model owns, instead of being tied to (and cancelled
    // with) this view's .task.
    @State private var model = SessionReviewModel()

    var body: some View {
        // SessionFeedbackView owns the push to the transcript screen; we just feed it data.
        NavigationStack {
            SessionFeedbackView(
                feedback: model.feedback,
                transcript: model.transcript,
                report: model.report,
                videoURL: videoURL
            )
        }
        .task {
            model.start(videoURL: videoURL, savedTranscript: savedTranscript, speechType: speechType)
        }
    }
}

/// Owns the analysis for one review screen. Runs at most once; keeps the expensive
/// pipeline off the view's lifecycle so navigation churn can't cancel and restart it.
@MainActor
@Observable
final class SessionReviewModel {
    private(set) var feedback = SessionFeedback.loading
    private(set) var transcript = Transcript(words: [])
    private(set) var report = AnalysisReport(
        scores: SessionScores(engagement: 0, confidence: 0, clarity: 0, content: nil),
        summary: "",
        metrics: [],
        findings: []
    )

    private var started = false
    private let analyzer = SessionAnalyzer()

    /// Kicks off loading once. Safe to call repeatedly (e.g. from a re-run `.task`).
    func start(videoURL: URL?, savedTranscript: Transcript?, speechType: SpeechType) {
        guard !started else { return }
        started = true
        // Unstructured Task owned by the model, so a cancelled view `.task` doesn't
        // abort the in-flight analysis.
        Task { await load(videoURL: videoURL, savedTranscript: savedTranscript, speechType: speechType) }
    }

    private func load(videoURL: URL?, savedTranscript: Transcript?, speechType: SpeechType) async {
        // Offline-safe scores first, so the screen isn't empty. Scoring is pure CPU,
        // so run it off the main actor to keep the transition smooth.
        if let savedTranscript {
            let analyzer = analyzer
            let base = await Task.detached {
                analyzer.score(transcript: savedTranscript, speechType: speechType)
            }.value
            apply(base, speechType: speechType)
        }

        // Then upgrade with the live pipelines (audio + Deepgram + video + content LLM).
        guard let videoURL,
              let result = try? await analyzer.analyze(videoURL: videoURL, speechType: speechType)
        else { return }
        apply(result, speechType: speechType)
    }

    private func apply(_ result: SessionAnalyzer.Result, speechType: SpeechType) {
        transcript = result.transcript
        report = result.report
        feedback = .make(result, speechType: speechType)
    }
}
