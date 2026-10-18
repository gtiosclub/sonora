//
//  FillerDebugView.swift
//  Sonora
//
//  Created by Vedansh Mannem on 10/14/26.
//

import SwiftUI

struct FillerDebugView: View {
    /// Test sentences for FillerWordAnalyzer: no fillers, several fillers, and fillers with capitals/punctuation.
    private let testCases: [(name: String, sentence: String)] = [
        ("No fillers", "I think we should bring an umbrella today"),
        ("Several fillers", "um I uh think hmm we er should mhmm leave"),
        ("Capitals and punctuation", "Um, I think, UH. we should... Hmm! Er? leave MHMM."),
    ]

    var body: some View {
        List(testCases, id: \.name) { testCase in
            let fillers = FillerWordAnalyzer().findFillers(in: makeWords(from: testCase.sentence))

            Section(testCase.name) {
                Text(testCase.sentence)
                Text("Fillers: \(fillers.count)")
                    .bold()
                ForEach(fillers, id: \.self) { filler in
                    HStack {
                        Text(String(format: "%.1fs", filler.start))
                            .foregroundStyle(.secondary)
                        Text(filler.text)
                    }
                }
            }
        }
    }

    /// Turns a sentence into words with fake timings: each word lasts 0.5s, back to back.
    private func makeWords(from sentence: String) -> [TranscriptWord] {
        sentence.split(separator: " ").enumerated().map { index, word in
            TranscriptWord(text: String(word), start: Double(index) * 0.5, end: Double(index) * 0.5 + 0.5)
        }
    }
}

#Preview {
    FillerDebugView()
}
