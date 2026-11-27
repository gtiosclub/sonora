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
        let base = score(transcript: transcript, video: video, speechType: speechType)

        // Content is the one category the deterministic scorer can't compute; fold it
        // in from the on-device model when available, recomputing the overall to include it.
        let scores: SessionScores
        let overall: Int
        if let content = await ContentScorer().score(transcript: transcript, speechType: speechType) {
            scores = SessionScores(
                engagement: base.report.scores.engagement,
                confidence: base.report.scores.confidence,
                clarity: base.report.scores.clarity,
                content: content
            )
            overall = SessionScorer.overall(for: scores, speechType: speechType)
        } else {
            scores = base.report.scores
            overall = base.overall
        }

        // Build the report with the final scores, then add the on-device coaching
        // summary from that report + overall. Result.report is a let, so set the
        // summary before wrapping. Stays "" when the model is unavailable.
        var report = AnalysisReport(
            scores: scores,
            summary: "",
            metrics: base.report.metrics,
            findings: base.report.findings
        )
        report.summary = await SummaryGenerator().generate(from: report, overall: overall) ?? ""

        return Result(transcript: base.transcript, report: report, overall: overall)
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
