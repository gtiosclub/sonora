//
//  BodyPoseDebugView.swift
//  Sonora
//
//  Created by Dev Patel on 9/28/26.
//

import SwiftUI
import UIKit

struct BodyPoseDebugView: View {
    @State private var lines: [String] = []

    var body: some View {
        List(lines, id: \.self) { line in
            Text(line)
                .font(.system(.body, design: .monospaced))
        }
        .task {
            await runPoseDetection()
        }
    }

    /// Samples the video at 1 frame per second, then lists the joints found in each frame.
    private func runPoseDetection() async {
        let videoURL = Bundle.main.url(forResource: "sample_video", withExtension: "mov")!

        do {
            let frames = try await FrameSampler().sampleFrames(from: videoURL)
            print("Frames:", frames.count)

            for frame in frames {
                // Skip frames where no person (or no confident joint) was found
                guard let sample = try BodyPoseDetector().detectPose(in: frame) else { continue }

                for joint in sample.joints {
                    let x = String(format: "%.2f", joint.position.x)
                    let y = String(format: "%.2f", joint.position.y)
                    let confidence = String(format: "%.2f", joint.confidence)
                    lines.append("\(Int(frame.timestamp))s \(joint.name) (\(x), \(y)) \(confidence)")
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

#Preview {
    BodyPoseDebugView()
}
