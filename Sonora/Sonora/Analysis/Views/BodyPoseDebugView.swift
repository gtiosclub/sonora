//
//  BodyPoseDebugView.swift
//  Sonora
//
//  Created by Dev Patel on 9/28/26.
//

import SwiftUI

struct BodyPoseDebugView: View {
    @State private var lines: [String] = []

    var body: some View {
        List(lines, id: \.self) { line in
            Text(line)
                .font(.system(.body, design: .monospaced))
        }
        .task {
            await runPostureAnalysis()
        }
    }

    /// Samples the video at 1 frame per second, then lists the posture numbers for each second.
    private func runPostureAnalysis() async {
        let videoURL = Bundle.main.url(forResource: "sample_posture", withExtension: "mov")!

        do {
            let frames = try await FrameSampler().sampleFrames(from: videoURL)

            for frame in frames {
                guard let sample = try BodyPoseDetector().detectPose(in: frame),
                      let posture = PostureAnalyzer().analyze(sample) else {
                    lines.append("\(Int(frame.timestamp))s no pose found")
                    continue
                }

                let tilt = String(format: "%.1f", posture.shoulderTilt)
                let head = String(format: "%.2f", posture.headHeight)
                lines.append("\(Int(frame.timestamp))s tilt \(tilt)° head \(head)")
            }
        } catch {
            lines.append("Error: \(error)")
        }
    }
}

#Preview {
    BodyPoseDebugView()
}
