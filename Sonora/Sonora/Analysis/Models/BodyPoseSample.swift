//
//  BodyPoseSample.swift
//  Sonora
//
//  Created by Dev Patel on 9/28/26.
//

import CoreGraphics
import Foundation

struct BodyPoseJoint: Codable, Equatable {
    let name: String
    let position: CGPoint
    let confidence: Double
}

struct BodyPoseSample: Codable, Equatable {
    let time: TimeInterval
    let joints: [BodyPoseJoint]
}	
