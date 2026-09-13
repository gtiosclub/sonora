//
//  User.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/13/26.
//

import Foundation

struct User: Codable, Equatable, Identifiable {
    var id: String {userId} // conform to identifiable
    // MARK: MANDATORY
    var userId: String
    var username: String
    var email: String
    var lastLogin: Date
    var streak: Int
    var skillProfile: SkillProfile
    // MARK: MANDATORY
}
