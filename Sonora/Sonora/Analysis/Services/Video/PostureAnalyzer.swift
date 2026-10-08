//
//  PostureAnalyzer.swift
//  Sonora
//
//  Created by Dev Patel on 10/8/26.
//

import Foundation

/// The two posture numbers for one moment in the video.
struct PostureMeasurement {
    let shoulderTilt: Double   // degrees, 0 means level shoulders
    let headHeight: Double     // nose y minus average shoulder y
}

struct PostureAnalyzer {

    /// Turns a pose into shoulder tilt and head height.
    /// Returns nil if the nose or either shoulder is missing.
    func analyze(_ sample: BodyPoseSample) -> PostureMeasurement? {
        guard let leftShoulder = joint(named: "leftShoulder", in: sample),
              let rightShoulder = joint(named: "rightShoulder", in: sample),
              let nose = joint(named: "nose", in: sample) else { return nil }

        // Shoulder tilt: the angle of the line between the shoulders.
        // The person's left shoulder shows up on the right side of the image,
        // so we subtract right from left to get a small angle when level.
        // Positive = left shoulder is higher, negative = right shoulder is higher.
        let dx = leftShoulder.position.x - rightShoulder.position.x
        let dy = leftShoulder.position.y - rightShoulder.position.y
        let shoulderTilt = Double(atan2(dy, dx)) * 180 / .pi

        // Head height: Vision's y goes up, so a higher nose means a bigger number
        let averageShoulderY = (leftShoulder.position.y + rightShoulder.position.y) / 2
        let headHeight = Double(nose.position.y - averageShoulderY)

        return PostureMeasurement(shoulderTilt: shoulderTilt, headHeight: headHeight)
    }

    /// Finds one joint by name, or nil if it wasn't confident enough to be kept.
    private func joint(named name: String, in sample: BodyPoseSample) -> BodyPoseJoint? {
        sample.joints.first { $0.name == name }
    }
}
