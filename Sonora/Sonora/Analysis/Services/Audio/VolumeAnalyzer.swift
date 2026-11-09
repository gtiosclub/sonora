import AVFoundation
import Accelerate

struct VolumeSample {
    let timestamp: TimeInterval
    let rms: Double
}

enum VolumeAnalyzerError: Error {
    case bufferAllocationFailed
    case missingChannelData
}

struct VolumeAnalyzer {
    let windowSize: AVAudioFrameCount

    init(windowSize: AVAudioFrameCount = 1024) {
        self.windowSize = max(1, windowSize)
    }

    func analyze(audioURL: URL) throws -> [VolumeSample] {
        let file = try AVAudioFile(forReading: audioURL)
        let format = file.processingFormat
        let sampleRate = format.sampleRate

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: windowSize) else {
            throw VolumeAnalyzerError.bufferAllocationFailed
        }

        var samples: [VolumeSample] = []
        samples.reserveCapacity(Int(file.length / AVAudioFramePosition(windowSize)) + 1)

        while file.framePosition < file.length {
            let startFrame = file.framePosition
            try file.read(into: buffer, frameCount: windowSize)

            let frameCount = buffer.frameLength
            if frameCount == 0 { break }

            guard let channelData = buffer.floatChannelData else {
                throw VolumeAnalyzerError.missingChannelData
            }

            var rms: Float = 0
            vDSP_rmsqv(channelData[0], 1, &rms, vDSP_Length(frameCount))

            samples.append(
                VolumeSample(
                    timestamp: Double(startFrame) / sampleRate,
                    rms: Double(rms)
                )
            )
        }

        return samples
    }
}
