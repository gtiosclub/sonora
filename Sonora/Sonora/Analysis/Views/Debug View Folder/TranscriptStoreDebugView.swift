//
//  TranscriptStoreDebugView.swift
//  Sonora
//

import SwiftUI

/// Exercises `TranscriptStore`: save a fixture transcript under a test session id,
/// then load it back and confirm the round-trip.
struct TranscriptStoreDebugView: View {
    @State private var sessionID = ""
    @State private var status = ""

    private let store = TranscriptStore()

    var body: some View {
        Form {
            TextField("Test session ID", text: $sessionID)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button("Save sample transcript") {
                Task { await save() }
            }
            Button("Load transcript") {
                Task { await load() }
            }

            Text(status)
                .font(.system(.body, design: .monospaced))
        }
    }

    @MainActor
    private func save() async {
        guard !sessionID.isEmpty else { status = "Enter a session ID first."; return }
        do {
            let transcript = try Self.fixtureTranscript()
            try await store.save(transcript, sessionID: sessionID)
            status = "Saved \(transcript.words.count) words. Check the Transcripts collection."
        } catch {
            status = "Error: \(error)"
        }
    }

    @MainActor
    private func load() async {
        guard !sessionID.isEmpty else { status = "Enter a session ID first."; return }
        do {
            guard let transcript = try await store.load(sessionID: sessionID) else {
                status = "No transcript stored for \"\(sessionID)\"."
                return
            }
            let preview = transcript.words.prefix(12).map(\.text).joined(separator: " ")
            status = "Loaded \(transcript.words.count) words:\n\(preview)…"
        } catch {
            status = "Error: \(error)"
        }
    }

    /// Decodes the bundled Deepgram fixture into a Transcript.
    private static func fixtureTranscript() throws -> Transcript {
        let url = Bundle.main.url(forResource: "deepgram_fillers_on", withExtension: "json")!
        let data = try Data(contentsOf: url)
        return try DeepgramDecoder().decode(data)
    }
}
