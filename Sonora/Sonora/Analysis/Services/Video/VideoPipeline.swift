import Foundation

/// Runs the full video-analysis pipeline for a recorded video:
/// sample frames -> per frame detect face (gaze) and body pose -> posture.
/// This composes the video services we have today and returns the raw,
/// time-stamped readings. Turning these into rubric scores/findings is a
/// separate step (see the scoring notes alongside SpeechPipeline).
struct VideoPipeline {

    /// The phases `run` moves through, reported via `onProgress`.
    enum Step: String {
        case samplingFrames = "Sampling frames…"
        case analyzingFrames = "Analyzing frames…"
    }

    /// A face reading (yaw/pitch/roll) at one moment in the video.
    struct TimedFace {
        let time: TimeInterval
        let face: FaceSample
    }

    /// A posture reading (shoulder tilt / head height) at one moment in the video.
    struct TimedPosture {
        let time: TimeInterval
        let posture: PostureMeasurement
    }

    /// Everything the video services produced, keyed by time.
    struct Result {
        let frameCount: Int
        let duration: TimeInterval          // timestamp of the last sampled frame
        let faces: [TimedFace]              // frames where a face was found
        let poses: [BodyPoseSample]         // frames where a body pose was found
        let postures: [TimedPosture]        // poses that had enough joints for posture
    }

    /// Samples the video and runs every video service over each frame.
    /// `onProgress` is called at the start of each phase; it defaults to a no-op.
    func run(
        videoURL: URL,
        framesPerSecond: Double = 1,
        onProgress: @MainActor (Step) -> Void = { _ in }
    ) async throws -> Result {
        // 1. Pull evenly spaced frames out of the video.
        onProgress(.samplingFrames)
        let frames = try await FrameSampler().sampleFrames(from: videoURL, framesPerSecond: framesPerSecond)

        // 2. Run face + pose + posture on each frame, keeping whatever was found.
        onProgress(.analyzingFrames)
        let faceDetector = FaceDetector()
        let poseDetector = BodyPoseDetector()
        let postureAnalyzer = PostureAnalyzer()

        var faces: [TimedFace] = []
        var poses: [BodyPoseSample] = []
        var postures: [TimedPosture] = []

        for frame in frames {
            if let face = try faceDetector.detectFace(in: frame.image) {
                faces.append(TimedFace(time: frame.timestamp, face: face))
            }
            if let pose = try poseDetector.detectPose(in: frame) {
                poses.append(pose)
                if let posture = postureAnalyzer.analyze(pose) {
                    postures.append(TimedPosture(time: frame.timestamp, posture: posture))
                }
            }
        }

        return Result(
            frameCount: frames.count,
            duration: frames.last?.timestamp ?? 0,
            faces: faces,
            poses: poses,
            postures: postures
        )
    }
}
