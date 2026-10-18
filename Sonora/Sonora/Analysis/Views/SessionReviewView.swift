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

    @State private var feedback = SessionFeedback.loading
    @State private var transcript = Transcript(words: [])
    @State private var report = AnalysisReport(
        scores: SessionScores(engaging: 0, confidence: 0, clarity: 0, content: 0),
        summary: "",
        metrics: [],
        findings: []
    )

    private let analyzer = SessionAnalyzer()

    var body: some View {
        // SessionFeedbackView owns the push to the transcript screen; we just feed it data.
        NavigationStack {
            SessionFeedbackView(
                feedback: feedback,
                transcript: transcript,
                report: report,
                videoURL: videoURL
            )
        }
        .task { await load() }
    }

    private func load() async {
        // Offline-safe scores first, so the screen isn't empty.
        if let savedTranscript {
            apply(analyzer.score(transcript: savedTranscript, speechType: speechType))
        }
        // Then upgrade with the live pipelines.
        guard let videoURL,
              let result = try? await analyzer.analyze(videoURL: videoURL, speechType: speechType)
        else { return }
        apply(result)
    }

    private func apply(_ result: SessionAnalyzer.Result) {
        transcript = result.transcript
        report = result.report
        feedback = .make(result, speechType: speechType)
    }
}
