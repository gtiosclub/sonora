//
//  SessionScores.swift
//  Sonora
//
//  Created by Judy Hsu on 10/8/26.
//

import Foundation

struct SessionScores: Codable, Equatable {        // all 0–100
    var engagement: Int, confidence: Int, clarity: Int
    var content: Int?   // nil = not scored yet (needs the LLM layer), not a 0 score

    /// Fixed 4-slot layout for `Session.scores`. Unscored content is written as 0
    /// to keep the slots aligned; read `content` (not this) to tell "not scored"
    /// apart from "scored low".
    var asArray: [Int] { [engagement, confidence, clarity, content ?? 0] }
}
