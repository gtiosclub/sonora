//
//  AnalysisReportStore.swift
//  Sonora
//
//  Created by Dev Patel on 11/22/26.
//

import FirebaseFirestore

struct AnalysisReportStore {

    /// Writes the mapped SessionSkillScore and the summary onto the existing Session document.
    func save(_ report: AnalysisReport, sessionID: String, userID: String) async throws {
        let skillScore = SessionScoreMapper().make(from: report.scores, sessionID: sessionID, userID: userID)

        let encoded = try Firestore.Encoder().encode(skillScore)

        let ref = Firestore.firestore().collection("Sessions").document(sessionID)
        try await ref.updateData([
            "sessionSkillScore": encoded,
            "summary": report.summary
        ])
    }
}
