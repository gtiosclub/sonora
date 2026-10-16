import Foundation

enum SpeechThresholds {
    static let fastWPM: Double = 170
    static let slowWPM: Double = 110
}

struct SpeechReportBuilder {

    private let fillerAnalyzer = FillerWordAnalyzer()

    func buildReport(from transcript: Transcript) -> AnalysisReport {
        let fillers = fillerAnalyzer.findFillers(in: transcript.words)

        var metrics: [Metric] = []
        var findings: [Finding] = []

        metrics.append(Metric(name: "Filler words", value: Double(fillers.count)))
        findings += fillers.map {
            Finding(start: $0.start, duration: 0, message: "Filler word: \"\($0.text)\"")
        }

        return AnalysisReport(
            scores: SessionScores(engaging: 0, confidence: 0, clarity: 0, content: 0),
            summary: "",
            metrics: metrics,
            findings: findings.sorted { $0.start < $1.start }
        )
    }
}
