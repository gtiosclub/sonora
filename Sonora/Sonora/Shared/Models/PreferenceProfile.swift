//
//  PreferenceProfile.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 9/21/26.
//

import Foundation

struct PreferenceProfile: Identifiable, Equatable, Codable {
    // MARK: MANDATORY
    var id: String
    var userId: String
    // MARK: MANDATORY
    
    // ADD preferences here

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
    
    //OPTIONAL: store topics that the user like
    var goodTopics : [Topics]
    
    //OPTIONAL: store topics that the user wants to stay away from
    var badTopics : [Topics]
    
    //store modes that user want to focus on
    //first element of list is the mode to focus on most
    var modes: [Session.Mode]
}

//possible topics of interest and disinterest that the user can choose from
enum Topics: Equatable, Codable {
    case environment,
         health,
         education,
         economy,
         technology,
         art,
         architecture,
         theater,
         religion,
         history,
         philosophy,
         politics,
         psychology,
         sociology,
         astronomy,
         science,
         geology,
         linguistics,
         law,
         mathematics,
         others
}

