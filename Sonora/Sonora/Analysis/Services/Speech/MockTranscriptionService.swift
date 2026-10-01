//
//  MockTranscriptionService.swift
//  Sonora
//
//  Created by Kirtan Chintam on 9/30/26.
//
import Foundation

struct MockTranscriptionService {
    func loadTranscript(fromFixture name: String) throws -> Transcript {
        guard let url=Bundle.main.url(forResource:name, withExtension: "json") else {
            fatalError("Could not find \(name).json in the app bundle")
        }
        let data = try Data(contentsOf:url)
        return try JSONDecoder().decode(Transcript.self, from:data)
    }
}
