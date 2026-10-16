//
//  FaceDetector.swift
//  Sonora
//
//  Created by Dev Patel on 10/16/26.
//

import Vision
import UIKit

struct FaceDetector {

    /// Finds face and returns FaceSample, or returns nil if no face is found.
    func detectFace(in image: UIImage) throws -> FaceSample? {
        guard let cgImage = image.cgImage else { return nil }

        // Ask Vision to look for a face, and tell it which way the photo is rotated
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: visionOrientation(of: image))
        try handler.perform([request])

        // Use the first face Vision found
        guard let face = request.results?.first,
              let yaw = face.yaw,
              let pitch = face.pitch,
              let roll = face.roll else { return nil }

        // Vision gives angles in radians, so convert them to degrees
        return FaceSample(
            yaw: yaw.doubleValue * 180 / .pi,
            pitch: pitch.doubleValue * 180 / .pi,
            roll: roll.doubleValue * 180 / .pi
        )
    }

    /// Photos store which way is up, and UIKit and Vision name it differently.
    /// This converts one to the other.
    private func visionOrientation(of image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
