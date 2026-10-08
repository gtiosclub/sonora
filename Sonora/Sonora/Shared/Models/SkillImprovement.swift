//
//  SkillImprovement.swift
//  Sonora
//
//  Created by evelyn wang on 9/27/26.
//

//Skill Improvement Model: Skill, improvement (int), Skill Summary from before

import Foundation

struct SkillImprovement: Identifiable, Equatable, Codable {
    var id: String
    var userID: String
    
    var Skill: SkillProfile.Skill
    var improvement: Int
    var SkillSummary: String

}

