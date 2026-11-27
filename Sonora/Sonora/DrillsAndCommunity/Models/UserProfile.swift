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

    // New in v2 design. Defaulted so older Firestore documents still decode.
    var pronouns: String
    var totalDrills: Int

    init(
        id: String,
        fullName: String,
        username: String,
        email: String,
        phoneNumber: String,
        bio: String,
        totalSessions: Int,
        totalSpeakingSeconds: Int,
        masteredTopics: [String],
        challengingTopics: [String],
        modes: [String],
        pronouns: String = "",
        totalDrills: Int = 0
    ) {
        self.id = id
        self.fullName = fullName
        self.username = username
        self.email = email
        self.phoneNumber = phoneNumber
        self.bio = bio
        self.totalSessions = totalSessions
        self.totalSpeakingSeconds = totalSpeakingSeconds
        self.masteredTopics = masteredTopics
        self.challengingTopics = challengingTopics
        self.modes = modes
        self.pronouns = pronouns
        self.totalDrills = totalDrills
    }

    private enum CodingKeys: String, CodingKey {
        case id, fullName, username, email, phoneNumber, bio
        case totalSessions, totalSpeakingSeconds
        case masteredTopics, challengingTopics, modes
        case pronouns, totalDrills
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        fullName = try c.decode(String.self, forKey: .fullName)
        username = try c.decode(String.self, forKey: .username)
        email = try c.decode(String.self, forKey: .email)
        phoneNumber = try c.decode(String.self, forKey: .phoneNumber)
        bio = try c.decode(String.self, forKey: .bio)
        totalSessions = try c.decode(Int.self, forKey: .totalSessions)
        totalSpeakingSeconds = try c.decode(Int.self, forKey: .totalSpeakingSeconds)
        masteredTopics = try c.decode([String].self, forKey: .masteredTopics)
        challengingTopics = try c.decode([String].self, forKey: .challengingTopics)
        modes = try c.decode([String].self, forKey: .modes)
        // New fields: missing in older documents
        pronouns = try c.decodeIfPresent(String.self, forKey: .pronouns) ?? ""
        totalDrills = try c.decodeIfPresent(Int.self, forKey: .totalDrills) ?? 0
    }
}

extension UserProfile {
    /// "Joe Shmow" -> "JS". Falls back to the username.
    var initials: String {
        let source = fullName.isEmpty ? username : fullName
        let letters = source.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
