//
//  PauseAnalyzer.swift
//  Sonora
//

import Foundation

struct Pause: Hashable {
    /// End of the word before the pause.
    let start: TimeInterval
    /// Start of the word after the pause.
    let end: TimeInterval
    var duration: TimeInterval { end - start }
}

struct PauseAnalyzer {
    /// Silence between two words at least this long counts as a pause.
    var minimumPause: TimeInterval = 1.0

    /// Returns every gap between consecutive words that is at least `minimumPause` long.
    func findPauses(in words: [TranscriptWord]) -> [Pause] {
        zip(words, words.dropFirst()).compactMap { previous, next in
            let gap = next.start - previous.end
            return gap >= minimumPause ? Pause(start: previous.end, end: next.start) : nil
        }
    }

    // Optional: returns just when each pause happened, as (start, end) times in seconds.
    // func findPauseTimestamps(in words: [TranscriptWord]) -> [(start: TimeInterval, end: TimeInterval)] {
    //     findPauses(in: words).map { (start: $0.start, end: $0.end) }
    // }
}
