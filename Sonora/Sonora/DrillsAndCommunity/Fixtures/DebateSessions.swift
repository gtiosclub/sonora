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
        summary: "argues that early social media harms young teen mental health. statistically sound argument, but failed to summarize their argument and provide a closing statement",
        prompt: "social media does more harm than good.",
        scores: [72, 58, 64, 70]
    )

    static let lastFive = [debateSession1]
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
            skill: SkillProfile.Skill(id: "content", summary: ""),
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
