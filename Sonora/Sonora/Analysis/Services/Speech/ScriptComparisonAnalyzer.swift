//
//  ScriptComparisonAnalyzer.swift
//  Sonora
//

import Foundation

struct ScriptComparison {
    let scriptWordCount: Int
    let spokenWordCount: Int
    /// Spoken words that aren't in the script, excluding fillers (those are counted separately).
    let extraWords: [TranscriptWord]
    /// Spoken fillers that aren't in the script.
    let fillerWords: [TranscriptWord]
    /// Script words the speaker never said, in script order.
    let missedWords: [String]

    /// How many more (positive) or fewer (negative) words were said than the script has.
    var wordCountDifference: Int { spokenWordCount - scriptWordCount }
}

struct ScriptComparisonAnalyzer {
    /// Aligns what was said against the script using a longest-common-subsequence match,
    /// so a single inserted or skipped word doesn't throw off the rest of the comparison.
    func compare(_ words: [TranscriptWord], toScript script: String) -> ScriptComparison {
        let scriptTokens = Self.tokenize(script)
        let spokenTokens = words.map { FillerWordAnalyzer.normalize($0.text) }
        let (matchedSpoken, matchedScript) = Self.longestCommonSubsequence(spokenTokens, scriptTokens)

        var extra: [TranscriptWord] = []
        var fillers: [TranscriptWord] = []
        for (index, word) in words.enumerated() where !matchedSpoken.contains(index) {
            if FillerWordAnalyzer.isFiller(word.text) {
                fillers.append(word)
            } else {
                extra.append(word)
            }
        }
        let missed = scriptTokens.indices
            .filter { !matchedScript.contains($0) }
            .map { scriptTokens[$0] }

        return ScriptComparison(
            scriptWordCount: scriptTokens.count,
            spokenWordCount: words.count,
            extraWords: extra,
            fillerWords: fillers,
            missedWords: missed
        )
    }

    static func tokenize(_ script: String) -> [String] {
        script
            .split(whereSeparator: \.isWhitespace)
            .map { FillerWordAnalyzer.normalize(String($0)) }
            .filter { !$0.isEmpty }
    }

    /// Returns the indices in `a` and `b` that belong to one longest common subsequence.
    private static func longestCommonSubsequence(_ a: [String], _ b: [String]) -> (Set<Int>, Set<Int>) {
        let n = a.count, m = b.count
        // lengths[i][j] = LCS length of a[i...] and b[j...]
        var lengths = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in stride(from: n - 1, through: 0, by: -1) {
            for j in stride(from: m - 1, through: 0, by: -1) {
                lengths[i][j] = a[i] == b[j]
                    ? lengths[i + 1][j + 1] + 1
                    : max(lengths[i + 1][j], lengths[i][j + 1])
            }
        }

        var matchedA = Set<Int>(), matchedB = Set<Int>()
        var i = 0, j = 0
        while i < n && j < m {
            if a[i] == b[j] {
                matchedA.insert(i)
                matchedB.insert(j)
                i += 1
                j += 1
            } else if lengths[i + 1][j] >= lengths[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }
        return (matchedA, matchedB)
    }
}
