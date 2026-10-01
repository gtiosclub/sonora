//
//  SkillProfiles.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 10/1/26.
//

import Foundation

// Sample SkillProfiles for testing and previews
extension SkillProfile {
    static func sample(userId: String) -> SkillProfile {
        SkillProfile(
            id: userId,
            userId: userId,
            content: Skill(id: UUID().uuidString, summary: "Good structure, can add more examples."),
            clarity: Skill(id: UUID().uuidString, summary: "Clear diction, minor fillers."),
            confidence: Skill(id: UUID().uuidString, summary: "Decent eye contact, some hesitation."),
            engaging: Skill(id: UUID().uuidString, summary: "Engaging but a bit monotone.")
        )
    }
}
