//
//  FaceDebugView.swift
//  Sonora
//
//  Created by Dev Patel on 10/16/26.
//

import SwiftUI

struct FaceDebugView: View {
    @State private var lines: [String] = []

    private let photoNames = [
        "face_camera", "face_left", "face_right", "face_up",
        "face_down", "face_laptop", "face_eyes_down"
    ]

    var body: some View {
        List(lines, id: \.self) { line in
            Text(line)
                .font(.system(.body, design: .monospaced))
        }
        .onAppear {
            runFaceDetection()
        }
    }

    /// Runs the face detector on each photo and lists its angles.
    private func runFaceDetection() {
        for name in photoNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
                  let image = UIImage(contentsOfFile: url.path) else {
                lines.append("\(name) could not load photo")
                continue
            }

            do {
                if let face = try FaceDetector().detectFace(in: image) {
                    let yaw = Int(face.yaw.rounded())
                    let pitch = Int(face.pitch.rounded())
                    let roll = Int(face.roll.rounded())
                    lines.append("\(name) yaw \(yaw)° pitch \(pitch)° roll \(roll)°")
                } else {
                    lines.append("\(name) no face found")
                }
            } catch {
                lines.append("\(name) error: \(error)")
            }
        }
    }
}

#Preview {
    FaceDebugView()
}
