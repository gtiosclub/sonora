import SwiftUI
import AVFoundation

struct AudioExtractorDebugView: View {
    @State private var outputURL: URL?
    @State private var fileSize: String?
    @State private var errorMessage: String?
    @State private var isWorking = false
    // Has to be stored in state, or it gets deallocated and nothing plays.
    @State private var player: AVAudioPlayer?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Audio Extractor").font(.title2.bold())
            HStack {
                Button("Extract sample_speech_black_screen.mp4") {
                    Task { await run(resource: "sample_speech_black_screen", ext: "mp4") }
                }
                Button("Test sample_short.json") {
                    Task { await run(resource: "sample_short", ext: "json") }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWorking)
            if isWorking { ProgressView() }
            if let outputURL, let fileSize {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Size: \(fileSize)")
                    Text("Path: \(outputURL.path)")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                    Button("Play", systemImage: "play.fill") { play(outputURL) }
                }
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
            Spacer()
        }
        .padding()
    }
    private func run(resource: String, ext: String) async {
        isWorking = true
        outputURL = nil
        fileSize = nil
        errorMessage = nil
        player?.stop()
        defer { isWorking = false }
        // Fixtures must be in the app target's "Copy Bundle Resources".
        guard let input = Bundle.main.url(forResource: resource, withExtension: ext) else {
            errorMessage = "Couldn't find \(resource).\(ext) in the app bundle."
            return
        }
        do {
            let url = try await AudioExtractor.extractAudio(from: input)
            let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            outputURL = url
            fileSize = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    private func play(_ url: URL) {
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            player = newPlayer
            newPlayer.play()
        } catch {
            errorMessage = "Playback failed: \(error.localizedDescription)"
        }
    }
}
#Preview {
    AudioExtractorDebugView()
}
