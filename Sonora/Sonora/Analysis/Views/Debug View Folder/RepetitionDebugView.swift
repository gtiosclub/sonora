//
//  RepetitionDebugView.swift
//  Sonora
//
//  Created by Dev Patel on 11/22/26.
//

import SwiftUI

struct RepetitionDebugView: View {
    @State private var lines: [String] = []

    var body: some View {
        VStack {
            Button("Run on real transcript") {
                run(addRepeatedPhrase: false)
            }
            .buttonStyle(.bordered)

            Button("Run with repeated phrase added") {
                run(addRepeatedPhrase: true)
            }
            .buttonStyle(.bordered)

            List(lines, id: \.self) { line in
                Text(line)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }

    /// Scores the saved Deepgram transcript and lists the repetition results.
    private func run(addRepeatedPhrase: Bool) {
        do {
            let url = Bundle.main.url(forResource: "deepgram_fillers_on", withExtension: "json")!
            let data = try Data(contentsOf: url)
            var transcript = try DeepgramDecoder().decode(data)

            if addRepeatedPhrase {
                transcript.words += repeatedPhraseWords()
            }

            let result = SessionScorer().score(transcript: transcript)

            let count = result.metrics.first { $0.name == "Repeated phrases" }?.value ?? 0
            var output = ["Repeated phrases metric: \(Int(count))"]

            let repeated = result.findings.filter { $0.message.hasPrefix("Repeated phrase") }
            if repeated.isEmpty {
                output.append("No repetition findings")
            }
            for finding in repeated {
                output.append("\(finding.start.asPreciseClock) \(finding.message)")
            }

            lines = output
        } catch {
            lines = ["Error: \(error)"]
        }
    }

    /// "we need to" said 3 times, starting at 30s (after the real transcript ends at about 26s).
    /// Other words sit between the repeats so only that one phrase repeats.
    private func repeatedPhraseWords() -> [TranscriptWord] {
        let text = "we need to apples we need to oranges we need to pears"
        return text.split(separator: " ").enumerated().map { index, word in
            let start = 30 + Double(index) * 0.5
            return TranscriptWord(text: String(word), start: start, end: start + 0.5, confidence: 1.0)
        }
    }
}

#Preview {
    RepetitionDebugView()
}
