//
//  PreferenceProfile.swift
//  Sonora
//
//  Created by Jocelyn Chen on 9/26/26.
//

import Foundation

struct PreferenceProfile: Identifiable, Equatable, Codable {
    var id: String
    var userId: String

    var practiceLength: PracticeLength
    var difficulty: Difficulty
    var practiceType: PracticeType
    var topics: [String]
    var feedbackStyle: FeedbackStyle

    enum PracticeLength: String, Codable {
        case short
        case medium
        case long
    }

    enum Difficulty: String, Codable {
        case easy
        case moderate
        case challenging
    }

    enum PracticeType: String, Codable {
        case drills
        case debates
        case interviews
        case presentations
    }

    enum FeedbackStyle: String, Codable {
        case detailed
        case highLevel
    }
}
