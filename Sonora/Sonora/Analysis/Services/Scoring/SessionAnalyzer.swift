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
        let report: AnalysisReport   // scores + metrics + findings + summary
        let overall: Int
    }

    /// Runs the speech pipeline (required) and video pipeline (best-effort), then
    /// scores the result and adds an on-device coaching summary when available.
    /// Throws if transcription fails.
    func analyze(videoURL: URL, speechType: SpeechType) async throws -> Result {
        async let speechTask = SpeechPipeline().run(videoURL: videoURL)
        async let visualsTask = VideoPipeline().run(videoURL: videoURL)

        let transcript = try await speechTask.transcript
        let video = try? await visualsTask
        let scored = score(transcript: transcript, video: video, speechType: speechType)

        // Result.report is a let, so set the summary on a local copy before wrapping.
        // Stays "" if the on-device model is unavailable.
        var report = scored.report
        report.summary = await SummaryGenerator().generate(from: report, overall: scored.overall) ?? ""

        return Result(transcript: scored.transcript, report: report, overall: scored.overall)
    }

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
