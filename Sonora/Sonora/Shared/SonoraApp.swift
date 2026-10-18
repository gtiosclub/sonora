//
//  SonoraApp.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/13/26.
//

import SwiftUI
import FirebaseCore

@main
struct SonoraApp: App {
    @State private var auth: AuthManager

    init() {
        FirebaseApp.configure()
        _auth = State(initialValue: AuthManager())
    }
    private let transcript = try! MockTranscriptionService().loadTranscript(fromFixture: "sample_short")
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SessionFeedbackView(
                    feedback: .sample,
                    transcript: transcript,
                    report: SpeechReportBuilder().buildReport(from: transcript)
                )
            }
        }
    }
}
