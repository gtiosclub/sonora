//
//  SessionFeedback.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/7/26.
//

import Foundation

struct SessionFeedback: Identifiable, Codable, Equatable {
    var id: String
    var sessionId: String

    var overallScore: Int            // 0-100
    var previousScore: Int?          // score from the last session of the same mode

    // Session summary (AI generated)
    var summary: String
    var strength: String
    var focusArea: String

    // Skill breakdown
    var paceWPM: Int
    var voiceModulation: Double      // 0...1
    var posture: Double              // 0...1

    // Moments to review
    var moments: [ReviewMoment]

    // Progress (oldest -> newest overall scores)
    var recentScores: [Int]
}

struct ReviewMoment: Identifiable, Codable, Equatable {
    var id: String
    var startSeconds: Int
    var endSeconds: Int
    var note: String
}
