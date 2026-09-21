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
    var goodTopics : [Topics]
    var badTopics : [Topics]


}

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

