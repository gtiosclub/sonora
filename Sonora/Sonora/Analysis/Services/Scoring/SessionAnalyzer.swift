//
//  SessionAnalyzer.swift
//  Sonora
//

import Foundation

/// Coordinates the full analysis for one recording: runs the speech and video
/// pipelines, then applies the rubric. The presentation layer calls this instead
/// of wiring the pipelines and scorer together itself.
struct SessionAnalyzer {

    struct Result {
        let transcript: Transcript
        let report: AnalysisReport   // scores + metrics + findings
        let overall: Int
    }

    /// Runs the speech pipeline (required) and video pipeline (best-effort), then
    /// scores the result. Throws if transcription fails.
    func analyze(videoURL: URL, speechType: SpeechType) async throws -> Result {
        async let speechTask = SpeechPipeline().run(videoURL: videoURL)
        async let visualsTask = VideoPipeline().run(videoURL: videoURL)

        let transcript = try await speechTask.transcript
        let video = try? await visualsTask
        return score(transcript: transcript, video: video, speechType: speechType)
    }

    /// Scores an already-decoded transcript (e.g. the offline fixture path).
    func score(
        transcript: Transcript,
        video: VideoPipeline.Result? = nil,
        speechType: SpeechType
    ) -> Result {
        let scoring = SessionScorer().score(transcript: transcript, video: video, speechType: speechType)
        let report = AnalysisReport(
            scores: scoring.scores,
            summary: "",
            metrics: scoring.metrics,
            findings: scoring.findings
        )
        return Result(transcript: transcript, report: report, overall: scoring.overall)
    }
}
