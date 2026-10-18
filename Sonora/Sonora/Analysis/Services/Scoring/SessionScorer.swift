//
//  SessionScorer.swift
//  Sonora
//

import Foundation

/// Applies the Sonora rubric to the pipeline outputs to produce category scores,
/// an overall score, per-sub-metric metrics, and timestamped findings.
///
/// Implemented today (deterministic, no LLM):
///   - Clarity:    filler rate, pace, mumbling, rushed stretches        (transcript)
///   - Confidence: eye contact (if video given), hedging                (video + transcript)
///   - Engaging:   pace variety, vocabulary variety (MATTR), repetition (transcript)
///
/// Not yet scored (needs work the codebase doesn't have):
///   - Confidence › posture stability (needs tuned sway/tilt thresholds)
///   - Engaging › gesture use (needs a waist reference joint) and audience hooks (LLM)
///   - Content (entirely LLM)
/// Those are left out of their category averages; `content` stays 0 and is excluded
/// from the overall until the LLM layer exists.
struct SessionScorer {

    struct Result {
        let scores: SessionScores   // content is 0 until the LLM layer lands
        let overall: Int            // weighted over the categories we can compute
        let metrics: [Metric]
        let findings: [Finding]
    }

    /// Each sub-metric lands in one of these bands, which map to a 0–100 score
    /// (Good = 100, OK = 70, Needs work = 40), per the rubric.
    private enum Band {
        case good, ok, needsWork
        var score: Double {
            switch self {
            case .good: 100
            case .ok: 70
            case .needsWork: 40
            }
        }
    }

    private let fillerAnalyzer = FillerWordAnalyzer()

    func score(
        transcript: Transcript,
        video: VideoPipeline.Result? = nil,
        speechType: SpeechType = .presentation
    ) -> Result {
        let words = transcript.words
        let minutes = Self.spanMinutes(words)

        var metrics: [Metric] = []
        var findings: [Finding] = []

        // MARK: Clarity

        let fillers = fillerAnalyzer.findFillers(in: words)
        let fillerRate = minutes > 0 ? Double(fillers.count) / minutes : 0
        let fillerBand: Band = fillerRate < 2 ? .good : (fillerRate <= 5 ? .ok : .needsWork)
        metrics.append(Metric(name: "Filler rate (per min)", value: fillerRate))
        findings += fillers.map {
            Finding(start: $0.start, duration: 0, message: "Filler word: \"\($0.text)\"")
        }

        let wpm = minutes > 0 ? Double(words.count) / minutes : 0
        let paceBand = Self.paceBand(wpm: wpm, speechType: speechType)
        metrics.append(Metric(name: "Pace (wpm)", value: wpm))

        let mumbleRuns = Self.mumblingRuns(words)
        let mumbleRate = minutes > 0 ? Double(mumbleRuns.count) / minutes : 0
        let mumbleBand: Band = mumbleRate <= 1 ? .good : (mumbleRate <= 3 ? .ok : .needsWork)
        metrics.append(Metric(name: "Mumbling runs", value: Double(mumbleRuns.count)))
        findings += mumbleRuns.map {
            Finding(start: $0.start, duration: 0, message: "Unclear / mumbled stretch")
        }

        let windows = Self.wpmWindows(words)
        let rushedWindows = windows.enumerated().filter { $0.element > 190 }
        let rushedBand: Band = rushedWindows.isEmpty ? .good : (rushedWindows.count <= 2 ? .ok : .needsWork)
        metrics.append(Metric(name: "Rushed 30s windows", value: Double(rushedWindows.count)))
        findings += rushedWindows.map { index, windowWPM in
            Finding(start: Double(index) * 30, duration: 30,
                    message: "Rushed here (~\(Int(windowWPM)) wpm)")
        }

        let clarity = Self.average([fillerBand, paceBand, mumbleBand, rushedBand].map(\.score))

        // MARK: Confidence

        var confidenceBands: [Band] = []

        if let video, !video.faces.isEmpty {
            let facing = video.faces.filter { abs($0.face.yaw) <= 15 && abs($0.face.pitch) <= 10 }.count
            let eyeContact = Double(facing) / Double(video.faces.count) * 100
            let eyeBand: Band = eyeContact > 70 ? .good : (eyeContact >= 50 ? .ok : .needsWork)
            confidenceBands.append(eyeBand)
            metrics.append(Metric(name: "Eye contact (%)", value: eyeContact))
        }

        let hedges = Self.hedgeCount(words)
        let hedgeRate = minutes > 0 ? Double(hedges) / minutes : 0
        let hedgeBand: Band = hedgeRate < 1 ? .good : (hedgeRate < 2 ? .ok : .needsWork)
        confidenceBands.append(hedgeBand)
        metrics.append(Metric(name: "Hedging (per min)", value: hedgeRate))

        let confidence = Self.average(confidenceBands.map(\.score))

        // MARK: Engaging

        let paceVariety = Self.standardDeviation(windows)
        let varietyBand: Band = paceVariety >= 15 ? .good : (paceVariety >= 8 ? .ok : .needsWork)
        metrics.append(Metric(name: "Pace variety (wpm SD)", value: paceVariety))

        let mattr = Self.mattr(words)
        let mattrBand: Band = mattr > 0.72 ? .good : (mattr >= 0.65 ? .ok : .needsWork)
        metrics.append(Metric(name: "Vocabulary (MATTR)", value: mattr))

        let repeats = Self.repeatedTrigrams(words)
        let repeatBand: Band = repeats == 0 ? .good : (repeats <= 2 ? .ok : .needsWork)
        metrics.append(Metric(name: "Repeated phrases", value: Double(repeats)))

        let engaging = Self.average([varietyBand, mattrBand, repeatBand].map(\.score))

        // MARK: Assemble

        let scores = SessionScores(
            engaging: Self.toInt(engaging),
            confidence: Self.toInt(confidence),
            clarity: Self.toInt(clarity),
            content: 0 // not scored until the LLM layer exists
        )

        let overall = Self.overall(
            clarity: clarity, confidence: confidence, engaging: engaging, speechType: speechType
        )

        return Result(
            scores: scores,
            overall: overall,
            metrics: metrics,
            findings: findings.sorted { $0.start < $1.start }
        )
    }

    // MARK: - Overall (content excluded + weights renormalized)

    private static func overall(
        clarity: Double, confidence: Double, engaging: Double, speechType: SpeechType
    ) -> Int {
        let w = speechType.weights
        let weighted = clarity * w.clarity + confidence * w.confidence + engaging * w.engaging
        let totalWeight = w.clarity + w.confidence + w.engaging
        return toInt(totalWeight > 0 ? weighted / totalWeight : 0)
    }

    // MARK: - Sub-metric helpers

    private static func paceBand(wpm: Double, speechType: SpeechType) -> Band {
        let good = speechType.goodPace
        if good.contains(wpm) { return .good }
        if wpm >= good.lowerBound - 20 && wpm <= good.upperBound + 20 { return .ok }
        return .needsWork
    }

    /// Words per minute for each non-overlapping 30s window.
    private static func wpmWindows(_ words: [TranscriptWord], windowSeconds: Double = 30) -> [Double] {
        guard let last = words.last else { return [] }
        var windows: [Double] = []
        var start = 0.0
        while start < last.end {
            let end = start + windowSeconds
            let count = words.filter { $0.start >= start && $0.start < end }.count
            windows.append(Double(count) * (60.0 / windowSeconds))
            start = end
        }
        return windows
    }

    /// First word of each run of 3+ consecutive words below the confidence threshold.
    private static func mumblingRuns(_ words: [TranscriptWord], threshold: Double = 0.6) -> [TranscriptWord] {
        var runs: [TranscriptWord] = []
        var runStart: Int?
        var runLength = 0

        func closeRun() {
            if let start = runStart, runLength >= 3 { runs.append(words[start]) }
            runStart = nil
            runLength = 0
        }

        for (index, word) in words.enumerated() {
            if (word.confidence ?? 1.0) < threshold {
                if runStart == nil { runStart = index }
                runLength += 1
            } else {
                closeRun()
            }
        }
        closeRun()
        return runs
    }

    private static func hedgeCount(_ words: [TranscriptWord]) -> Int {
        let text = " " + words.map { $0.text.lowercased() }.joined(separator: " ") + " "
        let phrases = ["i think", "maybe", "kind of", "sort of", "i guess"]
        return phrases.reduce(0) { $0 + text.components(separatedBy: $1).count - 1 }
    }

    /// Moving-average type/token ratio over 50-word windows.
    private static func mattr(_ words: [TranscriptWord], window: Int = 50) -> Double {
        let tokens = words.map { FillerWordAnalyzer.normalize($0.text) }.filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return 0 }
        guard tokens.count > window else {
            return Double(Set(tokens).count) / Double(tokens.count)
        }
        var ratios: [Double] = []
        for start in 0...(tokens.count - window) {
            let slice = tokens[start..<start + window]
            ratios.append(Double(Set(slice).count) / Double(window))
        }
        return ratios.reduce(0, +) / Double(ratios.count)
    }

    /// Number of 3-word phrases said 3 or more times.
    private static func repeatedTrigrams(_ words: [TranscriptWord]) -> Int {
        let tokens = words.map { FillerWordAnalyzer.normalize($0.text) }.filter { !$0.isEmpty }
        guard tokens.count >= 3 else { return 0 }
        var counts: [String: Int] = [:]
        for i in 0...(tokens.count - 3) {
            counts[tokens[i..<i + 3].joined(separator: " "), default: 0] += 1
        }
        return counts.values.filter { $0 >= 3 }.count
    }

    // MARK: - Math helpers

    private static func spanMinutes(_ words: [TranscriptWord]) -> Double {
        guard let first = words.first, let last = words.last, last.end > first.start else { return 0 }
        return (last.end - first.start) / 60
    }

    private static func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        return variance.squareRoot()
    }

    private static func average(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private static func toInt(_ value: Double) -> Int {
        min(max(Int(value.rounded()), 0), 100)
    }
}
