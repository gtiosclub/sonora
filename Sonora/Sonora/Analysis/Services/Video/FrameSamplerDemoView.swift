//
//  FrameSamplerDemoView.swift
//  Sonora
//
//  Created by Dev Patel on 10/2/26.
//

import SwiftUI

struct FrameSamplerDemoView: View {
    @State private var frames: [Frame] = []

    var body: some View {
        ScrollView {
            ForEach(frames.indices, id: \.self) { i in
                VStack {
                    Image(uiImage: frames[i].image)
                        .resizable()
                        .scaledToFit()
                    Text("\(frames[i].timestamp) s")
                }
            }
        }
        .task {
            let videoURL = Bundle.main.url(forResource: "sample_video", withExtension: "mov")!
            do {
                frames = try await FrameSampler().sampleFrames(from: videoURL)
                print("Got \(frames.count) frames")
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    FrameSamplerDemoView()
}
