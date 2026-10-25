//
//  SpeechAnalyzer.swift
//  Sonora
//

import Foundation

struct SpeechAnalysisReport {
    let fillers: [TranscriptWord]
    let pauses: [Pause]
    let scriptComparison: ScriptComparison
    /// From the first word's start to the last word's end.
    let speakingDuration: TimeInterval
    /// The target time, or an estimate from the script length at `SpeechAnalyzer.targetWordsPerMinute`.
    let expectedDuration: TimeInterval

    /// Positive means the speaker ran long, negative means they finished early.
    var durationDifference: TimeInterval { speakingDuration - expectedDuration }
    var totalPauseTime: TimeInterval { pauses.reduce(0) { $0 + $1.duration } }
    var wordsPerMinute: Double {
        speakingDuration > 0 ? Double(scriptComparison.spokenWordCount) / speakingDuration * 60 : 0
    }
}

/// Runs every speech analyzer over one transcript and combines the results.
struct SpeechAnalyzer {
    /// Typical conversational presentation pace, used when no target duration is given.
    var targetWordsPerMinute: Double = 150
    var fillerAnalyzer = FillerWordAnalyzer()
    var pauseAnalyzer = PauseAnalyzer()
    var scriptAnalyzer = ScriptComparisonAnalyzer()

    func analyze(
        _ transcript: Transcript,
        script: String,
        targetDuration: TimeInterval? = nil
    ) -> SpeechAnalysisReport {
        let words = transcript.words
        let comparison = scriptAnalyzer.compare(words, toScript: script)
        let speakingDuration = (words.last?.end ?? 0) - (words.first?.start ?? 0)
        let expected = targetDuration
            ?? Double(comparison.scriptWordCount) / targetWordsPerMinute * 60

        return SpeechAnalysisReport(
            fillers: fillerAnalyzer.findFillers(in: words),
            pauses: pauseAnalyzer.findPauses(in: words),
            scriptComparison: comparison,
            speakingDuration: speakingDuration,
            expectedDuration: expected
        )
    }
}
