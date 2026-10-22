//
//  MockTranscriptionService.swift
//  Sonora
//
//  Created by Kirtan Chintam on 9/30/26.
//
import Foundation

enum MockTranscriptionError: LocalizedError {
    case fixtureNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fixtureNotFound(let name):
            return "Could not find \(name).json in the app bundle."
        }
    }
}

struct MockTranscriptionService {
    func loadTranscript(fromFixture name: String) throws -> Transcript {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw MockTranscriptionError.fixtureNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Transcript.self, from: data)
    }
}
