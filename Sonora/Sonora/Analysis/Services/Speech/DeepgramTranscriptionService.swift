import Foundation

enum DeepgramError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpStatus(code: Int, body: String)
    case network(URLError)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No Deepgram API key set. Add your key to Shared/Secrets.swift."
        case .invalidResponse:
            return "Deepgram returned a response the app couldn't read."
        case .httpStatus(let code, let body):
            if code == 401 || code == 403 {
                return "Deepgram rejected the API key (HTTP \(code)). Check Secrets.swift."
            }
            return "Deepgram request failed (HTTP \(code)): \(body.prefix(200))"
        case .network(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

struct DeepgramTranscriptionService {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = Secrets.deepgramAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    /// Sends the audio file to Deepgram and returns the raw JSON response data.
    func transcribe(fileURL: URL) async throws -> Data {
        guard !apiKey.isEmpty, apiKey != "PASTE_YOUR_DEEPGRAM_KEY_HERE" else {
            throw DeepgramError.missingAPIKey
        }

        var components = URLComponents(string: "https://api.deepgram.com/v1/listen")!
        // Keep these in sync with your Week 1 curl command.
        components.queryItems = [
            URLQueryItem(name: "filler_words", value: "true")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.contentType(for: fileURL), forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        do {
            // Streams the file from disk instead of loading it all into memory.
            let (data, response) = try await session.upload(for: request, fromFile: fileURL)

            guard let http = response as? HTTPURLResponse else {
                throw DeepgramError.invalidResponse
            }
            guard (200..<300).contains(http.statusCode) else {
                throw DeepgramError.httpStatus(
                    code: http.statusCode,
                    body: String(data: data, encoding: .utf8) ?? ""
                )
            }
            return data
        } catch let urlError as URLError {
            throw DeepgramError.network(urlError)
        }
    }

    private static func contentType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "wav": return "audio/wav"
        case "mp3": return "audio/mpeg"
        case "m4a", "mp4": return "audio/mp4"
        case "flac": return "audio/flac"
        case "ogg": return "audio/ogg"
        default: return "application/octet-stream"
        }
    }
}
