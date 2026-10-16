//
//  InterviewSessions.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 9/24/26.
//

import SwiftUI

@MainActor
enum InterviewSessions {
    static let interviewSession1: Session = {
        Session(id: "interview1",
                participants: ["user1"],
                status: Session.Status.completed,
                acceptedBy: ["user1"],
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.ai,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 20,
                        hour: 17,
                        minute: 0
                    )
                )!,
                createdAt: Date(),
                durationSeconds: 600,
                sessionSkillScore: SessionSkillScore(id: "interview1", userId: "user1", content: Skill(id: "interview1-content", score: 55, summary: ""), engagement: Skill(id: "interview1-content", score: 58, summary: ""), clarity: Skill(id: "interview1-content", score: 81, summary: ""), confidence: Skill(id: "interview1-content", score: 89, summary: "")))
    }()
    
    static let interviewSession2: Session = {
        Session(id: "interview2",
                participants: ["user1"],
                status: Session.Status.completed,
                acceptedBy: ["user1"],
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.ai,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 21,
                        hour: 18,
                        minute: 0
                    )
                )!,
                createdAt: Date(),
                durationSeconds:700,
                sessionSkillScore: SessionSkillScore(id: "interview2", userId: "user1", content: Skill(id: "interview2-content", score: 90, summary: ""), engagement: Skill(id: "interview2-content", score: 64, summary: ""), clarity: Skill(id: "interview2-content", score: 85, summary: ""), confidence: Skill(id: "interview2-content", score: 55, summary: "")))
    }()
    
    static let interviewSession3: Session = {
        Session(id: "interview3",
                participants: ["user1"],
                status: Session.Status.completed,
                acceptedBy: ["user1"],
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.ai,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 22,
                        hour: 16,
                        minute: 0
                    )
                )!,
                createdAt: Date(),
                durationSeconds: 500,
                sessionSkillScore: SessionSkillScore(id: "interview3", userId: "user1", content: Skill(id: "interview3-content", score: 77, summary: ""), engagement: Skill(id: "interview3-content", score: 66, summary: ""), clarity: Skill(id: "interview3-content", score: 55, summary: ""), confidence: Skill(id: "interview3-content", score: 44, summary: "")))
    }()
    
    static let interviewSession4: Session = {
        Session(id: "interview4",
                participants: ["user1"],
                status: Session.Status.completed,
                acceptedBy: ["user1"],
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.human,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 23,
                        hour: 20,
                        minute: 0
                    )
                )!,
                createdAt: Date(),
                durationSeconds: 800,
                sessionSkillScore: SessionSkillScore(id: "interview4", userId: "user1", content: Skill(id: "interview4-content", score: 21, summary: ""), engagement: Skill(id: "interview4-content", score: 76, summary: ""), clarity: Skill(id: "interview4-content", score: 94, summary: ""), confidence: Skill(id: "interview4-content", score: 99, summary: "")))
    }()
    
    static let interviewSession5: Session = {
        Session(id: "interview5",
                participants: ["user1"],
                status: Session.Status.completed,
                acceptedBy: ["user1"],
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.human,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 24,
                        hour: 15,
                        minute: 0
                    )
                )!,
                createdAt: Date(),
                durationSeconds: 900,
                sessionSkillScore: SessionSkillScore(id: "interview5", userId: "user1", content: Skill(id: "interview5-content", score: 65, summary: ""), engagement: Skill(id: "interview5-content", score: 70, summary: ""), clarity: Skill(id: "interview5-content", score: 61, summary: ""), confidence: Skill(id: "interview5-content", score: 45, summary: "")))
    }()
}
