import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
struct SummaryGenerator {
    func generate(from report: AnalysisReport, overall: Int? = nil) async -> String? {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return nil }
        guard SystemLanguageModel.default.isAvailable else { return nil }
        let session = LanguageModelSession(
            instructions: """
            You are a concise, encouraging public-speaking coach. \
            Reply with 2-3 sentences of plain text. No lists, no markdown, no emojis.
            """
        )
        do {
            let response = try await session.respond(
                to: Self.makePrompt(from: report, overall: overall)
            )
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
    static func makePrompt(
        from report: AnalysisReport,
        overall: Int? = nil,
        maxMetrics: Int = 4
    ) -> String {
        let metricLines = report.metrics
            .prefix(maxMetrics)
            .map { "- \($0.name): \(format($0.value))" }   // adjust if Metric's fields differ
            .joined(separator: "\n")

        let overallLine = overall.map { "Overall score: \($0)/100\n" } ?? ""

        return """
        Write a 2-3 sentence coaching note for a speaker based on these results.
        \(overallLine)Key metrics:
        \(metricLines)
        Mention one strength and one thing to improve.
        """
    }
    private static func format<T>(_ value: T) -> String {
        if let d = value as? Double { return String(format: "%.1f", d) }
        return "\(value)"
    }
}
