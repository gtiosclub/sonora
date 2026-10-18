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

    /// Takes a video, runs it through every speech service, and returns the finished report.
    /// `onProgress` is called on the main actor at the start of each step; it defaults to a no-op
    /// so existing callers are unaffected.
    func analyze(
        videoURL: URL,
        onProgress: @MainActor (Step) -> Void = { _ in }
    ) async throws -> AnalysisReport {
        // 1. Pull the audio out of the video into a temporary .m4a.
        await onProgress(.extractingAudio)
        let audioURL = try await AudioExtractor.extractAudio(from: videoURL)

        // 2. Send the audio to Deepgram. Clean up the temp file afterward,
        //    even if transcription or a later step throws.
        await onProgress(.transcribing)
        let data: Data
        do {
            data = try await DeepgramTranscriptionService().transcribe(fileURL: audioURL)
        } catch {
            try? FileManager.default.removeItem(at: audioURL)
            throw error
        }
        try? FileManager.default.removeItem(at: audioURL)

        // 3. Turn the raw JSON into a Transcript, then build the report.
        await onProgress(.analyzing)
        let transcript = try DeepgramDecoder().decode(data)

        // 4. Build the analysis report from the transcript.
        return SpeechReportBuilder().buildReport(from: transcript)
    }
}
