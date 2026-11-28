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
    /// scores the result, folds in the on-device Content score, and adds a coaching
    /// summary when available. Throws if transcription fails.
    func analyze(videoURL: URL, speechType: SpeechType) async throws -> Result {
        async let speechTask = SpeechPipeline().run(videoURL: videoURL)
        async let visualsTask = VideoPipeline().run(videoURL: videoURL)

        let transcript = try await speechTask.transcript
        let video = try? await visualsTask
        return await scoreWithContent(transcript: transcript, video: video, speechType: speechType)
    }

    /// Cache-aware variant: reuses the session's stored transcript when one exists,
    /// skipping audio extraction + Deepgram. On a cache miss it transcribes live and
    /// saves the transcript for next time. The video pipeline still runs either way.
    /// Throws only if a fresh transcription is needed and fails.
    func analyze(
        videoURL: URL,
        speechType: SpeechType,
        sessionID: String,
        transcriptStore: TranscriptStore = TranscriptStore()
    ) async throws -> Result {
        async let visualsTask = VideoPipeline().run(videoURL: videoURL)

        let transcript: Transcript
        if let cached = try? await transcriptStore.load(sessionID: sessionID) {
            transcript = cached
        } else {
            transcript = try await SpeechPipeline().run(videoURL: videoURL).transcript
            // Best-effort cache; a write failure shouldn't fail the analysis.
            try? await transcriptStore.save(transcript, sessionID: sessionID)
        }

        let video = try? await visualsTask
        return await scoreWithContent(transcript: transcript, video: video, speechType: speechType)
    }

    /// Deterministic scoring, the async on-device Content score folded in (recomputing
    /// the overall to include it), then a coaching summary built from the final report.
    /// Content and summary stay empty when the on-device model is unavailable.
    private func scoreWithContent(
        transcript: Transcript,
        video: VideoPipeline.Result?,
        speechType: SpeechType
    ) async -> Result {
        let base = score(transcript: transcript, video: video, speechType: speechType)

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

        // Result.report is a let, so set the summary on the report before wrapping.
        var report = AnalysisReport(
            scores: scores,
            summary: "",
            metrics: base.report.metrics,
            findings: base.report.findings
        )
        report.summary = await SummaryGenerator().generate(from: report, overall: overall) ?? ""

        return Result(transcript: base.transcript, report: report, overall: overall)
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
