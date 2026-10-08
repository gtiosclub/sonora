//
//  Session.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/13/26.
//

import Foundation
import FirebaseFirestore

struct Session: Identifiable, Codable, Equatable {
    var id: String
    var participants: [String]  // array of userIDs
    var status: Status
    var acceptedBy: [String]  // array of userIDs to keep track of who has accepted the session
    var aIOpponent: AIOpponent?
    var mode: Mode
    var opponentType: OpponentType
    var startTime: Date?  // when the session becomes active
    var createdAt: Date // when a pending session is created

    var durationSeconds: Int?
    var topic: Topics?
    var skillImprovement: SkillImprovement?
    var summary: String?
    var prompt: String?
    var analysis: String?
    var scores: [Int]? //analysis subteams scores
    
    enum Mode: String, Codable {
        case interview, debate, speech
    }
    
    enum Status: String, Codable {
        case active, pending, deleted, completed
    }
    
    enum OpponentType: String, Codable {
        case human, ai
    }
    
}
struct WaitingUser: Codable, Identifiable {
    @DocumentID var id: String?
    var userID: String
    var mode: String
    var joinedAt: Date?
}
