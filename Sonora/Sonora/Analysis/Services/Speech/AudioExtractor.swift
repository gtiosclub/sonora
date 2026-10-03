//
//  AudioExtractor.swift
//  Sonora
//
//  Created by Nishanth Vadlamani on 9/29/26.
//
import AVFoundation
enum AudioExtractorError: LocalizedError {
    case unreadableMedia(String)
    case noAudioTrack
    case exportSessionUnavailable
    case exportFailed(String)
    var errorDescription: String? {
        switch self {
        case .unreadableMedia(let detail):
            return "Couldn't read this file as media: \(detail)"
        case .noAudioTrack:
            return "This file has no audio track."
        case .exportSessionUnavailable:
            return "Couldn't create an export session for this file."
        case .exportFailed(let detail):
            return "Export failed: \(detail)"
        }
    }
}
enum AudioExtractor {
    // Extracts the audio from a video and writes it to a new .m4a in the temp directory. Returns URL of new .m4a file.
    static func extractAudio(from videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        // Making sure the file is readable media and actually has an audio track.
        let audioTracks: [AVAssetTrack]
        do {
            audioTracks = try await asset.loadTracks(withMediaType: .audio)
        } catch {
            // Example: a .json file is not media at all
            throw AudioExtractorError.unreadableMedia(error.localizedDescription)
        }
        guard !audioTracks.isEmpty else {
            throw AudioExtractorError.noAudioTrack
        }
        // Unique output path in the temp directory (export fails if the file exists).
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        try? FileManager.default.removeItem(at: outputURL)
        // Export the audio only.
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw AudioExtractorError.exportSessionUnavailable
        }
        do {
            if #available(iOS 18.0, macOS 15.0, *) {
                try await session.export(to: outputURL, as: .m4a)
            } else {
                session.outputURL = outputURL
                session.outputFileType = .m4a
                await session.export()
                if session.status != .completed {
                    throw session.error
                        ?? AudioExtractorError.exportFailed("status \(session.status.rawValue)")
                }
            }
        } catch let error as AudioExtractorError {
            throw error
        } catch {
            throw AudioExtractorError.exportFailed(error.localizedDescription)
        }
        return outputURL
    }
}
