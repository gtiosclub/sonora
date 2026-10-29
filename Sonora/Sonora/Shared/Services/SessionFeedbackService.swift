//
//  SessionFeedback.swift
//  Sonora
//
//  Created by Nidhi Nagumalla on 10/28/26.
//


import Foundation
import FirebaseFirestore

enum SessionFeedbackService {

    private static var sessions: CollectionReference {
        Firestore.firestore().collection("Sessions")
    }
    
    
    static func fetchFeedback(
        sessionID: String,
        userID: String
    ) async throws -> AnalysisReport? {

        let feedbackRef = sessions
            .document(sessionID)
            .collection("Feedback")
            .document(userID)

        // Fetch the feedback document.
        let snapshot = try await feedbackRef.getDocument()

        guard snapshot.exists else {
            return nil
        }

        // Retrieve the four skill scores and summary.
        let data = snapshot.data() ?? [:]

        let scores = SessionScores(
            engagement: data["engagement"] as? Int ?? 0,
            confidence: data["confidence"] as? Int ?? 0,
            clarity: data["clarity"] as? Int ?? 0,
            content: data["content"] as? Int
        )

        let summary = data["summary"] as? String ?? ""

        // Retrieve timestamped findings.
        let timestampsSnapshot = try await feedbackRef
            .collection("Timestamps")
            .order(by: "start")
            .getDocuments()

        let findings = timestampsSnapshot.documents.compactMap { document -> Finding? in
            let data = document.data()

            guard let start = data["start"] as? Double,
                  let duration = data["duration"] as? Double,
                  let message = data["message"] as? String
            else {
                return nil
            }

            return Finding(
                start: start,
                duration: duration,
                message: message
            )
        }

        return AnalysisReport(
            scores: scores,
            summary: summary,
            metrics: [],
            findings: findings
        )
    }



}
