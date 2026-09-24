//
//  TranscriptWord.swift
//  Sonora
//
//  Created by Judy Hsu on 9/24/26.
//
import Foundation

struct TranscriptWord: Codable, Equatable, Hashable {
    var text: String
    var start: TimeInterval
    var end: TimeInterval
    var confidence: Double?
}
