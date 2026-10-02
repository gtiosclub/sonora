//
//  BodyPoseSample.swift
//  Sonora
//
//  Created by Dev Patel on 9/28/26.
//

import CoreGraphics
import CoreMedia

struct BodyPoseJoint {
    let name: String
    let position: CGPoint
    let confidence: Float
}

struct BodyPoseSample {
    let time: CMTime
    let joints: [BodyPoseJoint]
}	
