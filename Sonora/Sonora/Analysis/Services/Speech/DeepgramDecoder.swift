//
//  DeepgramDecoder.swift
//  Sonora
//
//  Created by Dev Patel on 10/14/26.
//

import Foundation

struct DeepgramDecoder {
    private struct Response: Decodable {
        let results: Results
    }

    private struct Results: Decodable {
        let channels: [Channel]
    }

    private struct Channel: Decodable {
        let alternatives: [Alternative]
    }

    private struct Alternative: Decodable {
        let words: [Word]
    }

    private struct Word: Decodable {
        let word: String
        let start: Double
        let end: Double
        let confidence: Double
    }

    /// Converts Deepgram JSON into Transcript.
    func decode(_ data: Data) throws -> Transcript {
        let response = try JSONDecoder().decode(Response.self, from: data)

        // Using the first of Deepgram's returned channels
        guard let alternative = response.results.channels.first?.alternatives.first else {
            return Transcript(words: [])
        }

        let words = alternative.words.map { word in
            TranscriptWord(text: word.word, start: word.start, end: word.end, confidence: word.confidence)
        }

        return Transcript(words: words)
    }
}
