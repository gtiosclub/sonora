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
    
    //users' previous drills
    var pastDrills: [Drill]
    
    //user's skill and preference profiles
    var skillProfile: SkillProfile
    var preferenceProfile: PreferenceProfile
    // MARK: MANDATORY
}


extension User {
    /// A brand-new user with empty defaults. Used at sign up.
    static func makeNew(userId: String, username: String, email: String) -> User {
        func emptySkill() -> SkillProfile.Skill {
            SkillProfile.Skill(id: UUID().uuidString, comment: "")
        }

        return User(
            userId: userId,
            username: username,
            email: email,
            lastLogin: Date(),
            streak: 0,
            streakFreezes: 0,
            pastDrills: [],
            skillProfile: SkillProfile(
                id: UUID().uuidString,
                userId: userId,
                content: emptySkill(),
                clarity: emptySkill(),
                confidence: emptySkill(),
                engaging: emptySkill()
            ),
            preferenceProfile: PreferenceProfile(
                id: UUID().uuidString,
                userId: userId,
                goodTopics: [],
                badTopics: [],
                modes: []
            )
        )
    }
}
