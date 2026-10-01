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

    var content: Int
    var engagement: Int
    var speakingClarity: Int
    var confidence: Int
}
