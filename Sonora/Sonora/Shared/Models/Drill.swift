//
//  Drill.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 9/21/26.
//


//Drill Model: skill, sub-skill, mode, difficulty, prompt, topic, success criteria, drill results, duration, source session, date, id, userId, transcript
import Foundation

struct Drill: Identifiable, Equatable, Codable {
    // MARK: MANDATORY
    var id: String
    var userId: String
    // MARK: MANDATORY
    
    //basic info from the session
    var transcript: String
    var summary: String
    var mode: Session.Mode
    var date: Date
    var duration: Double
    
    //how to determine improvement
    var successCriteria: String
    var results: String
    
    //skill that the drill focused on and how much it leveled up
    var skill: SkillProfile.Skill
    var subSkill: String
    var improvement: Int
    var difficulty: String
    
    //notate which session it's from
    var sourceSession: Session
    var topic: String
    var prompt: String
    

}
