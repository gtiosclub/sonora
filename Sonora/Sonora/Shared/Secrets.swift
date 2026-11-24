//
//  Secrets.swift
//  Sonora
//
//  Created by Judy Hsu on 10/11/26.
//

import Foundation

enum Secrets {
    static var deepgramAPIKey: String { value(for: "DEEPGRAM_API_KEY") }

    static var openAIAPIKey: String { value(for: "OPENAI_API_KEY") }

    /// Reads a key from Secrets.plist, which is gitignored. Returns "" if missing.
    private static func value(for key: String) -> String {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = dict[key] as? String
        else { return "" }
        return value
    }
}
