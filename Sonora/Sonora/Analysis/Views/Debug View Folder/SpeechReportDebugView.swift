import SwiftUI

struct SpeechReportDebugView: View {

    @State private var report: AnalysisReport?
    @State private var status: String?
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        List {
            Section {
                Button("Analyze sample video") {
                    Task { await analyzeSampleVideo() }
                }
                Button("Use saved transcript") {
                    loadSavedTranscript()
                }
            }
            .disabled(isWorking)

            if let status {
                Section {
                    HStack {
                        ProgressView()
                        Text(status)
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            if let report {
                Section("Metrics (\(report.metrics.count))") {
                    ForEach(Array(report.metrics.enumerated()), id: \.offset) { _, m in
                        HStack {
                            Text(m.name)
                            Spacer()
                            Text(String(format: "%.0f", m.value)).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Findings (\(report.findings.count))") {
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
    }

    /// Runs the real pipeline on the bundled sample video, surfacing each step and any error.
    @MainActor
    private func analyzeSampleVideo() async {
        isWorking = true
        report = nil
        errorMessage = nil
        status = nil
        defer {
            isWorking = false
            status = nil
        }

        // Fixtures must be in the app target's "Copy Bundle Resources".
        guard let videoURL = Bundle.main.url(forResource: "filler_words_testing", withExtension: "mov") else {
            errorMessage = "Couldn't find filler_words_testing.mov in the app bundle."
            return
        }

        do {
            report = try await SpeechPipeline().analyze(videoURL: videoURL) { step in
                status = step.rawValue
            }
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }
    }

    /// Demo backup: build the report from a saved Deepgram response with no network.
    private func loadSavedTranscript() {
        report = nil
        status = nil
        errorMessage = nil

        guard let url = Bundle.main.url(forResource: "deepgram_fillers_on", withExtension: "json") else {
            errorMessage = "Couldn't find deepgram_fillers_on.json in the app bundle."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let transcript = try DeepgramDecoder().decode(data)
            report = SpeechReportBuilder().buildReport(from: transcript)
        } catch {
            errorMessage = "Failed to build report: \(error.localizedDescription)"
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
