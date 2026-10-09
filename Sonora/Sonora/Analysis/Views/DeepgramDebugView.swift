import SwiftUI
import UniformTypeIdentifiers

struct DeepgramDebugView: View {
    @State private var isPickerPresented = false
    @State private var isLoading = false
    @State private var responseSize: Int?
    @State private var preview: String?
    @State private var errorMessage: String?

    private let service = DeepgramTranscriptionService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Choose audio file…") { isPickerPresented = true }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            

            if isLoading { ProgressView("Sending to Deepgram…") }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            if let responseSize, let preview {
                Text("Response size: \(responseSize) bytes").font(.headline)
                ScrollView {
                    Text(preview)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()
        }
        .padding()
        .fileImporter(isPresented: $isPickerPresented, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let url): Task { await send(url) }
            case .failure(let error): errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func send(_ url: URL) async {
        isLoading = true
        errorMessage = nil
        responseSize = nil
        preview = nil
        defer { isLoading = false }

        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try await service.transcribe(fileURL: url)
            responseSize = data.count
            preview = String((String(data: data, encoding: .utf8) ?? "<non-UTF8 data>").prefix(500))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview { DeepgramDebugView() }
