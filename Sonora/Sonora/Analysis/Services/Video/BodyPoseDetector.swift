//
//  BodyPoseDetector.swift
//  Sonora
//
//  Created by Dev Patel on 9/28/26.
//

import Vision
import CoreMedia
import UIKit

struct BodyPoseDetector {

    /// Joints below this confidence are skipped.
    private let minimumConfidence: Float = 0.3

    /// The only joints we keep: shoulders and wrists.
    private let jointsToKeep: [(name: String, joint: VNHumanBodyPoseObservation.JointName)] = [
        ("leftShoulder", .leftShoulder),
        ("rightShoulder", .rightShoulder),
        ("leftWrist", .leftWrist),
        ("rightWrist", .rightWrist)
    ]

    /// Finds a person in the frame and returns their shoulders and wrists.
    /// Returns nil if no person is found, or if no joint is confident enough.
    func detectPose(in frame: Frame) throws -> BodyPoseSample? {
        guard let cgImage = frame.image.cgImage else { return nil }

        // Ask Vision to look for a body pose in the image
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])
        print("People found:", request.results?.count ?? 0)

        // Use the first person Vision found
        guard let person = request.results?.first else { return nil }

        // Keep only the joints we care about that are confident enough
        var joints: [BodyPoseJoint] = []
        for (name, jointName) in jointsToKeep {
            let point = try person.recognizedPoint(jointName)
            print(name, point.confidence)
            if point.confidence >= minimumConfidence {
                joints.append(BodyPoseJoint(name: name, position: point.location, confidence: point.confidence))
            }
        }

        if joints.isEmpty { return nil }

        let time = CMTime(seconds: frame.timestamp, preferredTimescale: 600)
        return BodyPoseSample(time: time, joints: joints)
    }
}
