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
    content: 85,
    engagement: 78,
    speakingClarity: 90,
    confidence: 62
)

let exampleSkillProfile2 = SkillProfile(
    id: "skill2",
    userId: "user2",
    content: 60,
    engagement: 88,
    speakingClarity: 76,
    confidence: 91
)

let examplePreferenceProfile1 = PreferenceProfile(
    id: "preference1",
    userId: "user1",
    practiceLength: .short,
    difficulty: .moderate,
    practiceType: .drills,
    topics: ["interviews", "presentations"],
    feedbackStyle: .detailed
)

let examplePreferenceProfile2 = PreferenceProfile(
    id: "preference2",
    userId: "user2",
    practiceLength: .medium,
    difficulty: .challenging,
    practiceType: .debates,
    topics: ["current events", "argumentative topics"],
    feedbackStyle: .highLevel
)

let exampleSessionScores: [SessionSkillScore] = {
    let content    = [60, 63, 62, 70, 74, 73, 80, 85]
    let engagement = [55, 58, 66, 64, 70, 75, 74, 78]
    let clarity    = [70, 72, 71, 75, 80, 84, 88, 90]
    let confidence = [40, 45, 44, 52, 50, 58, 61, 62]

    return content.indices.map { i in
        SessionSkillScore(
            id: "score\(i)",
            sessionId: "session\(i)",
            userId: "user1",
            date: Date().addingTimeInterval(-86_400 * Double(content.count - i)),
            content: content[i],
            engagement: engagement[i],
            speakingClarity: clarity[i],
            confidence: confidence[i]
        )
    }
}()
