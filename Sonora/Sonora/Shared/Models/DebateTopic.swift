//
//  DebateTopic.swift
//  Sonora
//
//  Created by Nidhi Nagumalla on 10/15/26.
//

import Foundation

enum DebateTopic: String, CaseIterable, Codable, Identifiable {
    case aiInEducation
    case socialMedia
    case collegeTuition
    case remoteWork
    case schoolUniforms
    case spaceExploration
    case animalTesting
    case votingAge
    case renewableEnergy
    case standardizedTesting
    case fourDayWorkweek
    case aiArt
    case personalPrivacy
    case electricVehicles
    case homework

    var id: String { rawValue }

    var question: String {
        switch self {
        case .aiInEducation:
            return "Should AI be used in classrooms?"
        case .socialMedia:
            return "Does social media do more harm than good?"
        case .collegeTuition:
            return "Should college education be free?"
        case .remoteWork:
            return "Is remote work better than office work?"
        case .schoolUniforms:
            return "Should schools require uniforms?"
        case .spaceExploration:
            return "Should governments prioritize space exploration?"
        case .animalTesting:
            return "Should animal testing be banned?"
        case .votingAge:
            return "Should the voting age be lowered to 16?"
        case .renewableEnergy:
            return "Should renewable energy replace fossil fuels entirely?"
        case .standardizedTesting:
            return "Should standardized tests be eliminated?"
        case .fourDayWorkweek:
            return "Should companies adopt a four-day workweek?"
        case .aiArt:
            return "Should AI-generated art be considered real art?"
        case .personalPrivacy:
            return "Is personal privacy more important than national security?"
        case .electricVehicles:
            return "Should all new cars be electric?"
        case .homework:
            return "Should schools eliminate homework?"
        }
    }
}
