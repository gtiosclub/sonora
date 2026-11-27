//
//  ContentScorer.swift
//  Sonora
//

import Foundation
import FoundationModels

/// Scores the rubric's **Content** category (substance, structure, relevance) from
/// the transcript using the on-device Foundation Models model. This is the one
/// category `SessionScorer` can't compute deterministically.
///
/// Pure and stateless so a test can pass a fixture `Transcript`. Returns `nil`
/// when the model is unavailable or the transcript is too short to judge — callers
/// treat `nil` as "leave `content` unscored", keeping it out of the overall.
struct ContentScorer {

    /// At most this many words are sent to the model, to stay well inside the
    /// context window and bound latency on long sessions.
    private static let maxWords = 600

    /// Structured output: a single 0–100 score, constrained so the model can't
    /// return an out-of-range value.
    @Generable
    struct Evaluation {
        @Guide(description: "Overall quality of the spoken content from 0 to 100", .range(0...100))
        var score: Int
    }

    /// Returns a 0–100 Content score, or `nil` when the model is unavailable or
    /// there isn't enough speech to judge. Never throws.
    func score(transcript: Transcript, speechType: SpeechType) async -> Int? {
        // Gate on the model itself, not an OS-version check: an eligible OS without
        // Apple Intelligence enabled still can't run it.
        guard SystemLanguageModel.default.isAvailable else { return nil }

        let text = Self.condensedText(transcript)
        // Fewer than a handful of words isn't enough to rate content fairly.
        guard text.split(separator: " ").count >= 10 else { return nil }

        let session = LanguageModelSession(instructions: Self.instructions(for: speechType))
        do {
            let response = try await session.respond(
                to: "Transcript:\n\(text)",
                generating: Evaluation.self
            )
            return min(max(response.content.score, 0), 100)
        } catch {
            return nil
        }
    }

    // MARK: - Prompt pieces (exposed for testing)

    /// Rubric instructions, tailored to the session type. Kept out of the per-call
    /// prompt body so the transcript gets most of the context budget.
    static func instructions(for speechType: SpeechType) -> String {
        let focus: String
        switch speechType {
        case .presentation:
            focus = "a clear main point, logical structure, and relevant supporting detail"
        case .debate:
            focus = "strong arguments, supporting evidence, and how well points are defended"
        case .interview:
            focus = "relevant, specific, well-structured answers with concrete examples"
        }
        return """
            You are an expert speaking judge scoring only the CONTENT of a \
            \(speechType.rawValue) — what was said, not how it sounded. Judge \(focus). \
            Ignore delivery, pacing, filler words, and audio quality. Return a single \
            integer from 0 to 100, where 0 is empty or incoherent and 100 is \
            exceptionally substantive and well-organized.
            """
    }

    /// Joins the transcript words into plain text, capped at `maxWords`.
    /// On-device model, so sending the words raises no network/PII concern.
    static func condensedText(_ transcript: Transcript) -> String {
        transcript.words.prefix(maxWords)
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
