//
//  PresentationSessions.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 9/24/26.
//


import Foundation

@MainActor
enum PresentationSessions {
    static let presentationSession1 = Session(
        id: "presentation1",
        participants: ["user1"],
        status: .completed,
        acceptedBy: ["user1"],
        mode: .speech,
        opponentType: .ai,
        startTime: date(month: 11, day: 10),
        createdAt: date(month: 11, day: 10),
        durationSeconds: 300,
        topic: .technology,
        sessionSkillScore: SessionSkillScore(id: "presentation1", userId: "user1", content: Skill(id: "presentation1-content", score: 82, summary: ""), engagement: Skill(id: "presentation1-engagement", score: 46, summary: ""), clarity: Skill(id: "presentation1-clarity", score: 74, summary: ""), confidence: Skill(id: "presentation1-confidence", score: 70, summary: "")),
        summary: "Pitched a clear idea with solid market research, but opened by reading a definition and spoke in a monotone that lost the room.",
        prompt: "Pitch: a campus app that matches study partners."
    )

    static let presentationSession2 = Session(
        id: "presentation2",
        participants: ["user1"],
        status: .completed,
        acceptedBy: ["user1"],
        mode: .speech,
        opponentType: .ai,
        startTime: date(month: 11, day: 6),
        createdAt: date(month: 11, day: 6),
        durationSeconds: 420,
        topic: .science,
        sessionSkillScore: SessionSkillScore(id: "presentation2", userId: "user1", content: Skill(id: "presentation2-content", score: 79, summary: ""), engagement: Skill(id: "presentation2-engagement", score: 68, summary: ""), clarity: Skill(id: "presentation2-clarity", score: 41, summary: ""), confidence: Skill(id: "presentation2-confidence", score: 72, summary: "")),
        summary: "Covered the science accurately, but used heavy jargon without explaining it and jumped between points with no transitions.",
        prompt: "How vaccines train the immune system."
    )

    static let presentationSession3 = Session(
        id: "presentation3",
        participants: ["user1"],
        status: .completed,
        acceptedBy: ["user1"],
        mode: .speech,
        opponentType: .ai,
        startTime: date(month: 11, day: 1),
        createdAt: date(month: 11, day: 1),
        durationSeconds: 240,
        topic: .economy,
        sessionSkillScore: SessionSkillScore(id: "presentation3", userId: "user1", content: Skill(id: "presentation3-content", score: 44, summary: ""), engagement: Skill(id: "presentation3-engagement", score: 63, summary: ""), clarity: Skill(id: "presentation3-clarity", score: 77, summary: ""), confidence: Skill(id: "presentation3-confidence", score: 75, summary: "")),
        summary: "Walked through the numbers clearly and calmly, but never explained what they meant for the club and ended without a takeaway.",
        prompt: "Quarterly club budget update."
    )

    static let presentationSession4 = Session(
        id: "presentation4",
        participants: ["user1"],
        status: .completed,
        acceptedBy: ["user1"],
        mode: .speech,
        opponentType: .ai,
        startTime: date(month: 10, day: 28),
        createdAt: date(month: 10, day: 28),
        durationSeconds: 360,
        topic: .environment,
        sessionSkillScore: SessionSkillScore(id: "presentation4", userId: "user1", content: Skill(id: "presentation4-content", score: 76, summary: ""), engagement: Skill(id: "presentation4-engagement", score: 66, summary: ""), clarity: Skill(id: "presentation4-clarity", score: 69, summary: ""), confidence: Skill(id: "presentation4-confidence", score: 43, summary: "")),
        summary: "Made a persuasive case with good local examples, but read mostly from the slides, rushed through the ending, and rarely looked up.",
        prompt: "Why cities should invest in bike lanes."
    )

    static let presentationSession5 = Session(
        id: "presentation5",
        participants: ["user1"],
        status: .completed,
        acceptedBy: ["user1"],
        mode: .speech,
        opponentType: .ai,
        startTime: date(month: 10, day: 22),
        createdAt: date(month: 10, day: 22),
        durationSeconds: 270,
        topic: .art,
        sessionSkillScore: SessionSkillScore(id: "presentation5", userId: "user1", content: Skill(id: "presentation5-content", score: 71, summary: ""), engagement: Skill(id: "presentation5-engagement", score: 84, summary: ""), clarity: Skill(id: "presentation5-clarity", score: 52, summary: ""), confidence: Skill(id: "presentation5-confidence", score: 67, summary: "")),
        summary: "Told the story with lots of energy and humor, but spoke so quickly that key plot points were hard to follow.",
        prompt: "Book talk: The Martian by Andy Weir."
    )

    static let lastFive = [presentationSession1, presentationSession2, presentationSession3, presentationSession4, presentationSession5]

    private static func date(month: Int, day: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(timeZone: .current, year: 2026, month: month, day: day, hour: 17)
        )!
    }
}
