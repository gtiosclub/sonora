//
//  SkillProfile.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/13/26.
//


import Foundation

struct SkillProfile: Identifiable, Equatable, Codable {
    // MARK: MANDATORY
    var id: String
    var userId: String
    
    //4 dimensions of speaking skills
    var content: Skill
    var clarity: Skill
    var confidence: Skill
    var engaging: Skill
    

    
    struct Skill: Identifiable, Equatable, Codable {
        var id: String
        var comment: String
    }
}

