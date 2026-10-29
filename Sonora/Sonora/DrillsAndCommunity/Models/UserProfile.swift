//
//  UserProfile.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/15/26.
//

// Everything the Profile page shows that isn't already on `User`.
// `id` matches `User.userId`, so one Firestore document per user.
// Streak is not stored here, since it already lives on `User.streak`.

import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    var id: String                 // same value as User.userId
    var fullName: String
    var username: String
    var email: String
    var phoneNumber: String
    var bio: String

    // Stats
    var totalSessions: Int
    var totalSpeakingSeconds: Int

    // Topic chips (later these can be derived from PreferenceProfile:
    // goodTopics -> masteredTopics, badTopics -> challengingTopics, modes -> modes)
    var masteredTopics: [String]
    var challengingTopics: [String]
    var modes: [String]
}

extension UserProfile {
    /// "Joe Shmow" -> "JS". Falls back to the username.
    var initials: String {
        let source = fullName.isEmpty ? username : fullName
        let letters = source.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
