//
//  SessionScores.swift
//  Sonora
//
//  Created by Judy Hsu on 10/8/26.
//

import Foundation

struct SessionScores: Codable, Equatable {        // all 0–100
    var engagement: Int, confidence: Int, clarity: Int, content: Int
    var asArray: [Int] { [engagement, confidence, clarity, content] }
}
