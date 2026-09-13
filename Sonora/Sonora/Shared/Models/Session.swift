//
//  Session.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/13/26.
//

import Foundation

struct Session: Identifiable, Codable, Equatable {
    var id: String
    var userId1: String
    var userId2: String?
    var AIOpponent: AIOpponent?
    var mode: Mode
    var opponentType: OpponentType
    var startTime: Date
    var durationSeconds: Int
    
    enum Mode: String, Codable {
        case interview, debate, speech
    }
    
    enum OpponentType: String, Codable {
        case human, ai
    }
}
