//
//  Drill.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 9/21/26.
//

import Foundation

struct Drill: Identifiable, Equatable, Codable {
    // MARK: MANDATORY
    var id: String
    var userId: String
    // MARK: MANDATORY
    
    
    var prompt: String
    var transcript: String
    var summary: String
    var mode: Session.Mode
    var date: Date
    
    //skill that the drill focused on and how much it leveled up
    var skill: SkillProfile.Skill
    var improvement: Int

}
