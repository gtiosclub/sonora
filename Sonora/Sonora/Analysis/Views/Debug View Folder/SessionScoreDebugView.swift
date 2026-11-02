//
//  SessionScoreDebugView.swift
//  Sonora
//
//  Created by Dev Patel on 11/2/26.
//

import SwiftUI

struct SessionScoreDebugView: View {
    @State private var text = ""

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(.body, design: .monospaced))
                .padding()
        }
        .onAppear {
            showSessionSkillScore()
        }
    }
    
    private func showSessionSkillScore() {
        do {
            let url = Bundle.main.url(forResource: "deepgram_fillers_on", withExtension: "json")!
            let data = try Data(contentsOf: url)
            let transcript = try DeepgramDecoder().decode(data)
            let report = SpeechReportBuilder().buildReport(from: transcript)

            let scores = SessionScores(engagement: 80, confidence: 70, clarity: 90, content: 60)
            let result = SessionScoreMapper().make(from: scores, sessionID: "session-1", userID: "user-1")
            text = "\(result)"
            print(result)
        } catch {
            text = "Error: \(error)"
        }
    }
}

#Preview {
    SessionScoreDebugView()
}
