import Foundation

/// Runs the full speech-analysis pipeline for a recorded video:
/// extract audio -> transcribe with Deepgram -> decode -> build the report.
struct SpeechPipeline {

    /// The phases `analyze` moves through, reported via `onProgress`.
    enum Step: String {
        case extractingAudio = "Extracting audio…"
        case transcribing = "Transcribing…"
        case analyzing = "Analyzing…"
    }

    /// The transcript plus the report built from it.
    struct Result {
        let transcript: Transcript
        let report: AnalysisReport
    }

    /// Takes a video, runs it through every speech service, and returns both the
    /// transcript and the report. `onProgress` is called at the start of each step;
    /// it defaults to a no-op so existing callers are unaffected.
    func run(
        videoURL: URL,
        onProgress: @MainActor (Step) -> Void = { _ in }
    ) async throws -> Result {
        // 1. Pull the audio out of the video into a temporary .m4a.
        onProgress(.extractingAudio)
        let audioURL = try await AudioExtractor.extractAudio(from: videoURL)

        // 2. Send the audio to Deepgram. Clean up the temp file afterward,
        //    even if transcription or a later step throws.
        onProgress(.transcribing)
        let data: Data
        do {
            data = try await DeepgramTranscriptionService().transcribe(fileURL: audioURL)
        } catch {
            try? FileManager.default.removeItem(at: audioURL)
            throw error
        }
        try? FileManager.default.removeItem(at: audioURL)

        // 3. Turn the raw JSON into a Transcript, then build the report.
        onProgress(.analyzing)
        let transcript = try DeepgramDecoder().decode(data)
        let report = SpeechReportBuilder().buildReport(from: transcript)
        return Result(transcript: transcript, report: report)
    }

    /// Convenience that returns just the report. Existing callers rely on this.
    func analyze(
        videoURL: URL,
        onProgress: @MainActor (Step) -> Void = { _ in }
    ) async throws -> AnalysisReport {
        try await run(videoURL: videoURL, onProgress: onProgress).report
    }
}
