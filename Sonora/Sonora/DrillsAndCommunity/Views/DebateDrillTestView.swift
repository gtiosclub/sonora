//
//  DebateDrillTestView.swift
//  Sonora
//
//  Created by Eshaan Dixit on 10/1/26.
//

import SwiftUI
import FoundationModels

struct DebateDrillTestView: View {
    @State private var results: [DebateDrillPrompt] = []
    @State private var isGenerating = false

    var body: some View {
        List {
            Section {
                Text(SystemLanguageModel.default.isAvailable
                     ? "Apple model: available"
                     : "Apple model: unavailable (using template)")
                    .font(.footnote)

                Button("Generate Drill") { Task { await generate() } }
                Button("Clear", role: .destructive) { results = [] }
            }
            .disabled(isGenerating)

            Section("Results") {
                if isGenerating { ProgressView() }
                ForEach(results.indices, id: \.self) { i in
                    let result = results[i]
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(result.taskType.rawValue) · \(result.sessionId ?? "no session")")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(result.drillContext)
                    }
                }
            }
        }
        .navigationTitle("Debate Drill Test")
    }

    private func generate() async {
        isGenerating = true
        defer { isGenerating = false }

        let result = await DebateDrillGenerator.generate(
            lastDebates: DebateSessions.lastFive,
            previousDrills: DebateSessions.previousDrills
        )
        results.insert(result, at: 0)
    }
}
