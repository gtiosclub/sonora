//
//  AnalysisReportStoreDebugView.swift
//  Sonora
//
//  Created by Dev Patel on 11/22/26.
//

import SwiftUI

struct AnalysisReportStoreDebugView: View {
    @State private var sessionID = ""
    @State private var userID = ""
    @State private var status = ""

    var body: some View {
        Form {
            TextField("Test session ID", text: $sessionID)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            TextField("User ID", text: $userID)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button("Save sample report") {
                Task { await saveReport() }
            }

            Text(status)
        }
    }

    /// Builds a report from the saved transcript, then saves it onto the test session.
    @MainActor
    private func saveReport() async {
        guard !sessionID.isEmpty, !userID.isEmpty else {
            status = "Enter a session ID and a user ID first."
            return
        }

        do {
            let url = Bundle.main.url(forResource: "deepgram_fillers_on", withExtension: "json")!
            let data = try Data(contentsOf: url)
            let transcript = try DeepgramDecoder().decode(data)
            var report = SpeechReportBuilder().buildReport(from: transcript)

            // Sample values so the change is easy to spot in the Firestore console
            report.scores = SessionScores(engagement: 80, confidence: 70, clarity: 90, content: 60)
            report.summary = "Test summary from the debug view."

            try await AnalysisReportStore().save(report, sessionID: sessionID, userID: userID)
            status = "Saved. Check the Sessions document in the Firestore console."
        } catch {
            status = "Error: \(error)"
        }
    }
}
