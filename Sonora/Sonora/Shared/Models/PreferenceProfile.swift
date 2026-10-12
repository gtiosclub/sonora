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

    var practiceLength: PracticeLength //preferred practice length
    var difficulty: Difficulty //preferred difficulty level
    var feedbackStyle: FeedbackStyle //preferred feedback style

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

    enum FeedbackStyle: String, Codable {
        case detailed
        case highLevel
    }
}
