//
//  AnimatedGIFView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/22/26.
//

import SwiftUI
import UIKit
import ImageIO

/// Loops a bundled GIF indefinitely. `name` is the file name without ".gif".
struct GIFImageView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        // Let SwiftUI decide the size instead of the GIF's pixel size.
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        // An animated UIImage plays automatically and repeats forever.
        view.image = Self.animatedImage(named: name)
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    // MARK: - Decoding

    private static func animatedImage(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        var frames: [UIImage] = []
        var totalDuration = 0.0

        for index in 0..<CGImageSourceGetCount(source) {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            totalDuration += frameDelay(source, index)
        }

        guard !frames.isEmpty else { return nil }
        return UIImage.animatedImage(with: frames, duration: totalDuration)
    }

    private static func frameDelay(_ source: CGImageSource, _ index: Int) -> Double {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
            ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double)
            ?? 0.1
        // Browsers treat tiny delays as 0.1s; do the same so playback isn't too fast.
        return delay < 0.02 ? 0.1 : delay
    }
}

/// Tuxely waving. Falls back to a placeholder until the GIF is added to the project.
struct TuxelyWaveView: View {
    /// File name in the bundle, without ".gif".
    var gifName: String = "tuxely_wave"

    var body: some View {
        if Bundle.main.url(forResource: gifName, withExtension: "gif") != nil {
            GIFImageView(name: gifName)
                .aspectRatio(1, contentMode: .fit)
                .accessibilityLabel("Tuxely the penguin waving")
        } else {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 64))
                .foregroundStyle(ProfilePalette.deepPlum)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Circle().fill(ProfilePalette.lavender))
                .aspectRatio(1, contentMode: .fit)
                .accessibilityHidden(true)
        }
    }
}
