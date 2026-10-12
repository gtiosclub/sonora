//
//  SkillProfile.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/13/26.
//


import Foundation

struct SkillProfile: Identifiable, Equatable, Codable {
    var id: String
    var userId: String
    
    //4 dimensions of speaking skills
    var content: Skill
    var clarity: Skill
    var confidence: Skill
    var engaging: Skill
}

struct Skill: Identifiable, Equatable, Codable {
    var id: String
    var score: Int
    var summary: String
}

extension SkillProfile {
    static func makeNew(userId: String) -> SkillProfile {
        func empty() -> Skill { Skill(id: UUID().uuidString, score: 50, summary: "") }
        func score(pScore: Int) -> Skill { Skill(id: UUID().uuidString, score: pScore, summary: "") }
        return SkillProfile(id: userId, userId: userId,
                            content: empty(), clarity: empty(), confidence: empty(), engaging: empty())
    }
}
