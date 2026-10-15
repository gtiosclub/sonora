import SwiftUI
struct SpeechReportDebugView: View {
    @State private var report: AnalysisReport?
    @State private var errorMessage: String?
    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
            if let report {
                Section("sample_short – Metrics (\(report.metrics.count))") {
                    ForEach(Array(report.metrics.enumerated()), id: \.offset) { _, m in
                        HStack {
                            Text(m.name)
                            Spacer()
                            Text(String(format: "%.0f", m.value)).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("sample_short – Findings (\(report.findings.count))") {
                    ForEach(Array(report.findings.enumerated()), id: \.offset) { _, f in
                        HStack {
                            Text(Self.timestamp(f.start)).monospacedDigit()
                            Text(f.message)
                        }
                    }
                }
            }
        }
        .navigationTitle("Speech Report")
        .onAppear(perform: load)
    }
    private func load() {
        do {
            let transcript = try MockTranscriptionService().loadTranscript(fromFixture: "sample_short")
            report = SpeechReportBuilder().buildReport(from: transcript)
        } catch {
            errorMessage = "Failed to build report: \(error)"
        }
    }
    static func timestamp(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = seconds - Double(minutes * 60)
        return String(format: "%d:%05.2f", minutes, secs)
    }
}
#Preview {
    NavigationStack { SpeechReportDebugView() }
}
