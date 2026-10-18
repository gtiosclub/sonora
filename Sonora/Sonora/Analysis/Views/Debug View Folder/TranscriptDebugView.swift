//
//  TranscriptDebugView.swift
//  Sonora
//
//  Created by Kirtan Chintam on 10/1/26.
//

import SwiftUI

struct TranscriptDebugView: View {
    @State private var words: [TranscriptWord] = []
    
    var body: some View {
        List(words, id: \.self) { word in
            HStack {
                Text(formatTime(word.start))
                    .foregroundStyle(.secondary)
                Text(word.text)
                    .foregroundStyle((word.confidence ?? 1.0) < 0.7 ? .gray : .primary)
            }
        }
        .safeAreaInset(edge: .top) {
            Text("\(words.count) words")
                .font(.headline)
        }
        .onAppear {
            do {
                let url = Bundle.main.url(forResource: "deepgram_fillers_on", withExtension: "json")!
                let data = try Data(contentsOf: url)
                let transcript = try DeepgramDecoder().decode(data)
                words = transcript.words
            } catch {
                print("Could not load transcript: \(error)")
            }
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds)/60
        let remainder = seconds - Double(minutes*60)
        return String(format: "%d:%05.2f", minutes, remainder)
    }
}

#Preview {
    TranscriptDebugView()
}
