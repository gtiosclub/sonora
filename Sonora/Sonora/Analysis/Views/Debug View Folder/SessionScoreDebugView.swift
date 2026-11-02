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
            guard let url = Bundle.main.url(forResource: "deepgram_fillers_on", withExtension: "json") else {
                text = "Error: couldn't find deepgram_fillers_on.json in the bundle"
                return
            }
            let data = try Data(contentsOf: url)
            let transcript = try DeepgramDecoder().decode(data)
            let report = SessionAnalyzer().score(transcript: transcript, speechType: .presentation).report

            let result = SessionScoreMapper().make(from: report.scores, sessionID: "session-1", userID: "user-1")
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
