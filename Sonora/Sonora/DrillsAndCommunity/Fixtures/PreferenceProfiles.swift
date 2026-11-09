//
//  PreferenceProfiles.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 10/15/26.
//

import Foundation

// Sample PreferenceProfiles for testing
extension PreferenceProfile {
    static func sample(userId: String) -> PreferenceProfile {
        PreferenceProfile(
            id: userId,
            userId: userId,
            practiceLength: .medium,
            difficulty: .moderate,
            feedbackStyle: .detailed,
            goodTopics: [.technology, .science],
            badTopics: [.politics],
            modes: [.interview, .debate]
        )
    }
}
