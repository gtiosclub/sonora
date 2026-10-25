//
//  DeepgramResponse.swift
//  Sonora
//

import Foundation

/// The parts of Deepgram's pre-recorded `/v1/listen` response we use.
/// We expect the input to look like the response from the docs:
/// https://developers.deepgram.com/reference/speech-to-text/listen-pre-recorded
///
/// Shape: `results.channels[].alternatives[].words[]`, each word with
/// `word`, `start`, `end`, `confidence` and (with `punctuate=true`) `punctuated_word`.
///
/// Request with `filler_words=true` — Deepgram drops "um"/"uh" from the output by default.
/// https://developers.deepgram.com/docs/filler-words
///
/// See `Samples/sample_deepgram.json` (repo root, not bundled in the app) for an example
/// of the response this expects.
struct DeepgramResponse: Decodable {
    struct Metadata: Decodable {
        let duration: TimeInterval?
    }

    struct Results: Decodable {
        let channels: [Channel]
    }

    struct Channel: Decodable {
        let alternatives: [Alternative]
    }

    struct Alternative: Decodable {
        let transcript: String
        let confidence: Double?
        let words: [Word]
    }

    struct Word: Decodable {
        let word: String
        let start: TimeInterval
        let end: TimeInterval
        let confidence: Double?
        let punctuatedWord: String?

        enum CodingKeys: String, CodingKey {
            case word, start, end, confidence
            case punctuatedWord = "punctuated_word"
        }
    }

    let metadata: Metadata?
    let results: Results

    static func decode(from data: Data) throws -> DeepgramResponse {
        try JSONDecoder().decode(DeepgramResponse.self, from: data)
    }

    /// Converts the best alternative of the first channel into our `Transcript` model.
    func toTranscript() -> Transcript {
        let words = results.channels.first?.alternatives.first?.words ?? []
        return Transcript(words: words.map {
            TranscriptWord(
                text: $0.punctuatedWord ?? $0.word,
                start: $0.start,
                end: $0.end,
                confidence: $0.confidence
            )
        })
    }
}
