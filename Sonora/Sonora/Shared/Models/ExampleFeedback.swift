//
//  ExampleFeedback.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/7/26.
//

import Foundation

let exampleSession = Session(
    id: "session1",
    participants: ["user1"],
    status: .completed,
    acceptedBy: ["user1"],
    mode: .interview,
    opponentType: .ai,
    startTime: Date(),
    createdAt: Date(),
    durationSeconds: 402
)

let exampleFeedback = SessionFeedback(
    id: "feedback1",
    sessionId: "session1",
    overallScore: 84,
    previousScore: 76,
    summary: "Confident, well-structured answers overall. You kept a steady pace and strong posture, but your delivery stayed fairly flat in the middle of the session.",
    strength: "Clear openings and a steady 146 WPM pace.",
    focusArea: "Vary your tone to emphasize key points.",
    paceWPM: 146,
    voiceModulation: 0.55,
    posture: 0.88,
    moments: [
        ReviewMoment(
            id: "moment1",
            startSeconds: 161,
            endSeconds: 200,
            note: "You sped up while giving your example."
        )
    ],
    recentScores: [73, 76, 75, 80, 78, 84]
)
