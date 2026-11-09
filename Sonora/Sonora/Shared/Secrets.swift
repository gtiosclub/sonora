//
//  Secrets.swift
//  Sonora
//
//  Created by Judy Hsu on 10/11/26.
//

import Foundation

enum Secrets {
    /// Reads the key from Secrets.plist, which is gitignored. Returns "" if missing.
    static var deepgramAPIKey: String {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = dict["DEEPGRAM_API_KEY"] as? String
        else { return "" }
        return key
    }
}
