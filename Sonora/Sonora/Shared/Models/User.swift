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
    
    //basic contact and profile information about user
    var username: String
    var email: String
    var lastLogin: Date
    
    //user's current drill streak and streak freezes left
    var streak: Int
    var streakFreezes: Int
    
    //user's skill and preference profiles
    var skillProfile: SkillProfile
    var preferenceProfile: PreferenceProfile
    // MARK: MANDATORY
}
