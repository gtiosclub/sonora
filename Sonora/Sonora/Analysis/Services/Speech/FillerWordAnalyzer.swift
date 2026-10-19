//
//  FillerWordAnalyzer.swift
//  Sonora
//

import Foundation

struct FillerWordAnalyzer {
    /// The single source of truth for which words count as fillers (lowercase, no punctuation).
    /// Includes the hyphenated forms Deepgram emits when `filler_words=true`.
    static let fillerWords: Set<String> = [
        "um", "uh", "mhmm", "er", "hmm",
        "mm-mm", "uh-uh", "uh-huh", "nuh-uh",
    ]

    /// Returns every word in the transcript that is a filler, in order.
    /// The filler count is `result.count`; each filler's timestamp is its `start`.
    func findFillers(in words: [TranscriptWord]) -> [TranscriptWord] {
        words.filter { Self.isFiller($0.text) }
    }

    // Optional: returns just when each filler was said, as (start, end) times in seconds.
    // func findFillerTimestamps(in words: [TranscriptWord]) -> [(start: TimeInterval, end: TimeInterval)] {
    //     findFillers(in: words).map { (start: $0.start, end: $0.end) }
    // }

    static func isFiller(_ text: String) -> Bool {
        fillerWords.contains(normalize(text))
    }

    /// Lowercases and strips leading/trailing punctuation so "Um," and "UH." match "um"/"uh".
    /// Inner punctuation is kept, so "I'll" and "uh-huh" survive intact.
    static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters.union(.whitespacesAndNewlines))
    }
}
