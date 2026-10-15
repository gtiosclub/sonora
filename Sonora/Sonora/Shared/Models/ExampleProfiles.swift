//
//  ExampleProfiles.swift
//  Sonora
//
//  Created by Jocelyn Chen on 9/26/26.
//

import Foundation

let exampleSkillProfile1 = SkillProfile(
    id: "skill1",
    userId: "user1",
    content: .init(id: "user1-content", score: 75, summary: ""),
    clarity: .init(id: "user1-clarity", score: 90, summary: ""),
    confidence: .init(id: "user1-confidence", score: 62, summary: ""),
    engaging: .init(id: "user1-engagement", score: 78, summary: "")
)

let exampleSkillProfile2 = SkillProfile(
    id: "skill2",
    userId: "user2",
    content: .init(id: "user2-content", score: 60, summary: ""),
    clarity: .init(id: "user2-clarity", score: 88, summary: ""),
    confidence: .init(id: "user2-confidence", score: 76, summary: ""),
    engaging: .init(id: "user2-engagement", score: 91, summary: "")
)

let examplePreferenceProfile1 = PreferenceProfile(
    id: "preference1",
    userId: "user1",
    practiceLength: .short,
    difficulty: .moderate,
    feedbackStyle: .detailed,
    goodTopics: [Topics.architecture, Topics.history],
    badTopics: [Topics.astronomy],
    modes: [Session.Mode.debate, Session.Mode.interview]
)

let examplePreferenceProfile2 = PreferenceProfile(
    id: "preference2",
    userId: "user2",
    practiceLength: .medium,
    difficulty: .challenging,
    feedbackStyle: .highLevel,
    goodTopics: [Topics.politics, Topics.philosophy],
    badTopics: [Topics.mathematics],
    modes: [Session.Mode.debate]
)

let exampleSessionScores: [SessionSkillScore] = {
    let userId = "user1"

    let content    = [60, 63, 62, 70, 74, 73, 80, 85]
    let engagement = [55, 58, 66, 64, 70, 75, 74, 78]
    let clarity    = [70, 72, 71, 75, 80, 84, 88, 90]
    let confidence = [40, 45, 44, 52, 50, 58, 61, 62]

    return content.indices.map { i in
        let sessionId = "session\(i)"
        let scoreId = "session\(i)-user1"

        return SessionSkillScore(
            id: scoreId,
            userId: userId,
            content: Skill(
                id: "\(scoreId)-content",
                score: content[i],
                summary: ""
            ),
            engagement: Skill(
                id: "\(scoreId)-engagement",
                score: engagement[i],
                summary: ""
            ),
            clarity: Skill(
                id: "\(scoreId)-clarity",
                score: clarity[i],
                summary: ""
            ),
            confidence: Skill(
                id: "\(scoreId)-confidence",
                score: confidence[i],
                summary: ""
            )
        )
    }
}()
