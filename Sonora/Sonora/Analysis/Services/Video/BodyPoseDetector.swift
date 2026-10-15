//
//  BodyPoseDetector.swift
//  Sonora
//
//  Created by Dev Patel on 9/28/26.
//

import Vision
import UIKit

struct BodyPoseDetector {

    /// Joints below this confidence are skipped.
    private let minimumConfidence: Double = 0.3

    /// Joints we keep: shoulders, wrists, nose, and neck.
    private let jointsToKeep: [(name: String, joint: VNHumanBodyPoseObservation.JointName)] = [
        ("leftShoulder", .leftShoulder),
        ("rightShoulder", .rightShoulder),
        ("leftWrist", .leftWrist),
        ("rightWrist", .rightWrist),
        ("nose", .nose),
        ("neck", .neck)
    ]

    /// Finds a person in the frame and returns their shoulders and wrists.
    /// Returns nil if no person is found, or if no joint is confident enough.
    func detectPose(in frame: Frame) throws -> BodyPoseSample? {
        guard let cgImage = frame.image.cgImage else { return nil }

        // Ask Vision to look for a body pose in the image
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])
        let peopleFound = request.results?.count ?? 0
        if peopleFound > 1 {
            print("⚠️ \(peopleFound) people found at \(frame.timestamp)s, using the first one")
        }

        // Use the first person Vision found
        guard let person = request.results?.first else { return nil }

        // Keep only the joints we care about that are confident enough
        var joints: [BodyPoseJoint] = []
        for (name, jointName) in jointsToKeep {
            let point = try person.recognizedPoint(jointName)
            let pointConfidence = Double(point.confidence)
            if pointConfidence >= minimumConfidence {
                joints.append(BodyPoseJoint(name: name, position: point.location, confidence: pointConfidence))
            }
        }

        if joints.isEmpty { return nil }

        return BodyPoseSample(time: frame.timestamp, joints: joints)
    }
}
