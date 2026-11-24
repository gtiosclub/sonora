import Foundation
let lowVolumeThreshold: Double = 0.05
let minLowVolumeDuration: TimeInterval = 0.5
struct VolumeReportBuilder {
    struct LowVolumeRun: Equatable {
        let start: TimeInterval
        let duration: TimeInterval
    }
    func buildReport(from samples: [VolumeSample]) -> (metrics: [Metric], findings: [Finding]) {
        guard !samples.isEmpty else { return ([], []) }
        let (mean, stdDev) = Self.statistics(of: samples.map(\.rms))
        let metrics = [
            makeMetric(name: "Average volume", value: mean),
            makeMetric(name: "Volume variation", value: stdDev),
        ]
        let findings = Self.lowVolumeRuns(in: samples).map {
            makeFinding(start: $0.start, duration: $0.duration, message: "Volume dropped")
        }
        return (metrics, findings)
    }
    static func statistics(of values: [Double]) -> (mean: Double, stdDev: Double) {
        guard !values.isEmpty else { return (0, 0) }
        let count = Double(values.count)
        let mean = values.reduce(0, +) / count
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / count
        return (mean, variance.squareRoot())
    }
    static func lowVolumeRuns(in samples: [VolumeSample]) -> [LowVolumeRun] {
        guard !samples.isEmpty else { return [] }
        let sampleInterval: TimeInterval = samples.count > 1
            ? (samples[samples.count - 1].timestamp - samples[0].timestamp) / Double(samples.count - 1)
            : 0
        var runs: [LowVolumeRun] = []
        var runStartIndex: Int?
        func closeRun(endingBefore endIndex: Int) {
            guard let startIndex = runStartIndex else { return }
            let start = samples[startIndex].timestamp
            let end = endIndex < samples.count
                ? samples[endIndex].timestamp
                : samples[samples.count - 1].timestamp + sampleInterval
            let duration = end - start
            if duration > minLowVolumeDuration {
                runs.append(LowVolumeRun(start: start, duration: duration))
            }
            runStartIndex = nil
        }
        for (index, sample) in samples.enumerated() {
            if sample.rms < lowVolumeThreshold {
                if runStartIndex == nil { runStartIndex = index }
            } else {
                closeRun(endingBefore: index)
            }
        }
        closeRun(endingBefore: samples.count)
        return runs
    }
    private func makeMetric(name: String, value: Double) -> Metric {
        Metric(name: name, value: value)
    }
    private func makeFinding(start: TimeInterval, duration: TimeInterval, message: String) -> Finding {
        Finding(start: start, duration: duration, message: message)
    }
}
