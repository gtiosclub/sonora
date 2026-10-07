//
//  FrameSampler.swift
//  Sonora
//
//  Created by Dev Patel on 9/28/26.
//

import AVFoundation
import UIKit

/// One frame from the video, and when it appears (in seconds).
struct Frame {
    let image: UIImage
    let timestamp: Double
}

struct FrameSampler {

    /// Grabs frames from a video at a steady rate.
    /// Example: framesPerSecond = 1 returns one frame at 0s, 1s, 2s, ...
    func sampleFrames(from videoURL: URL, framesPerSecond: Double = 1) async throws -> [Frame] {
        let asset = AVURLAsset(url: videoURL)
        let videoLength = try await asset.load(.duration).seconds

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true       // keeps the video upright
        generator.requestedTimeToleranceBefore = .zero        // get the exact frame we ask for
        generator.requestedTimeToleranceAfter = .zero

        let secondsBetweenFrames = 1.0 / framesPerSecond
        var frames: [Frame] = []
        var timestamp = 0.0

        while timestamp < videoLength {
            let time = CMTime(seconds: timestamp, preferredTimescale: 600)
            let (cgImage, _) = try await generator.image(at: time)
            frames.append(Frame(image: UIImage(cgImage: cgImage), timestamp: timestamp))
            timestamp += secondsBetweenFrames
        }

        return frames
    }
}

extension FrameSampler {
    func quickTest() async {
        let videoURL = Bundle.main.url(forResource: "sample_video", withExtension: "mov")!
        let frames = try? await sampleFrames(from: videoURL)
        print("Got \(frames?.count ?? 0) frames")
        frames?.forEach { print($0.timestamp) }
    }
}
