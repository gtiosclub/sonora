//
//  DebateSessions.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 9/24/26.
//

//fake data to test stuff
import Foundation

@MainActor
enum DebateSessions {
    static let debateSession1 = Session(
        id: "debate1",
        participants: ["user1"],
        status: .completed,
        acceptedBy: ["user1"],
        mode: .debate,
        opponentType: .ai,
        startTime: date(month: 1, day: 01),
        createdAt: date(month: 1, day: 01),
        durationSeconds: 600,
        topic: .technology,
        sessionSkillScore: SessionSkillScore(id: "debate1", userId: "user1", content: Skill(id: "debate1-content", score: 90, summary: ""), engagement: Skill(id: "debate1-content", score: 64, summary: ""), clarity: Skill(id: "debate1-content", score: 85, summary: ""), confidence: Skill(id: "debate1-content", score: 55, summary: "")),
        summary: "argues that early social media harms young teen mental health. statistically sound argument, but failed to summarize their argument and provide a closing statement",
        prompt: "social media does more harm than good.",
        scores: [72, 58, 64, 70]
    )

    static let debateSession2 = Session(
        id: "debate2",
        participants: ["user1", "user2"],
        status: .completed,
        acceptedBy: ["user1", "user2"],
        mode: .debate,
        opponentType: .human,
        startTime: date(month: 10, day: 10),
        createdAt: date(month: 10, day: 10),
        durationSeconds: 720,
        topic: .education,
        sessionSkillScore: SessionSkillScore(id: "debate2", userId: "user1", content: Skill(id: "debate2-content", score: 52, summary: ""), engagement: Skill(id: "debate2-engagement", score: 78, summary: ""), clarity: Skill(id: "debate2-clarity", score: 70, summary: ""), confidence: Skill(id: "debate2-confidence", score: 74, summary: "")),
        summary: "defended pass/fail grading with a clear fairness argument, but relied on a single personal example and never brought in evidence to support it.",
        prompt: "schools should replace letter grades with pass/fail."
    )

    static let debateSession3 = Session(
        id: "debate3",
        participants: ["user1"],
        status: .completed,
        acceptedBy: ["user1"],
        mode: .debate,
        opponentType: .ai,
        startTime: date(month: 10, day: 8),
        createdAt: date(month: 10, day: 8),
        durationSeconds: 540,
        topic: .economy,
        sessionSkillScore: SessionSkillScore(id: "debate3", userId: "user1", content: Skill(id: "debate3-content", score: 81, summary: ""), engagement: Skill(id: "debate3-engagement", score: 66, summary: ""), clarity: Skill(id: "debate3-clarity", score: 47, summary: ""), confidence: Skill(id: "debate3-confidence", score: 62, summary: "")),
        summary: "argued remote work boosts productivity with strong statistics, but the explanation was rushed and the main points were hard to follow.",
        prompt: "remote work is better than working in an office."
    )

    static let debateSession4 = Session(
        id: "debate4",
        participants: ["user1", "user3"],
        status: .completed,
        acceptedBy: ["user1", "user3"],
        mode: .debate,
        opponentType: .human,
        startTime: date(month: 10, day: 5),
        createdAt: date(month: 10, day: 5),
        durationSeconds: 660,
        topic: .environment,
        sessionSkillScore: SessionSkillScore(id: "debate4", userId: "user1", content: Skill(id: "debate4-content", score: 73, summary: ""), engagement: Skill(id: "debate4-engagement", score: 49, summary: ""), clarity: Skill(id: "debate4-clarity", score: 76, summary: ""), confidence: Skill(id: "debate4-confidence", score: 80, summary: "")),
        summary: "opposed a ban on gas cars by 2035 with confident delivery, but spoke in a flat tone and never responded directly to the opponent's points.",
        prompt: "governments should ban gas-powered cars by 2035."
    )

    static let debateSession5 = Session(
        id: "debate5",
        participants: ["user1"],
        status: .completed,
        acceptedBy: ["user1"],
        mode: .debate,
        opponentType: .ai,
        startTime: date(month: 10, day: 2),
        createdAt: date(month: 10, day: 2),
        durationSeconds: 600,
        topic: .economy,
        sessionSkillScore: SessionSkillScore(id: "debate5", userId: "user1", content: Skill(id: "debate5-content", score: 68, summary: ""), engagement: Skill(id: "debate5-engagement", score: 84, summary: ""), clarity: Skill(id: "debate5-clarity", score: 64, summary: ""), confidence: Skill(id: "debate5-confidence", score: 45, summary: "")),
        summary: "argued college athletes should be paid using engaging stories, but hedged often and backed down when challenged on funding.",
        prompt: "college athletes should be paid."
    )

    static let lastFive = [debateSession2, debateSession3, debateSession4, debateSession5, debateSession1]
    static let previousDrills: [Drill] = []

    static func drill(_ id: String, from session: Session, task: DrillTaskType,
                      day: Int, prompt: String) -> Drill {
        Drill(
            id: id,
            userId: "user1",
            transcript: "",
            summary: "",
            mode: .debate,
            date: date(month: 9, day: day),
            duration: 60,
            successCriteria: "",
            results: "",
            skill: Skill(id: "content", score: 65, summary: ""),
            subSkill: "",
            improvement: 0,
            difficulty: "medium",
            sourceSession: session,
            topic: session.topic,
            prompt: prompt,
            taskType: task
        )
    }

    private static func date(month: Int, day: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(timeZone: .current, year: 2026, month: month, day: day, hour: 17)
        )!
    }
}
