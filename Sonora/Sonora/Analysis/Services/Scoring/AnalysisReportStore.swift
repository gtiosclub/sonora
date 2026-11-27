//
//  AnalysisReportStore.swift
//  Sonora
//
//  Created by Dev Patel on 11/22/26.
//


import FirebaseFirestore

struct AnalysisReportStore {

    /// Writes the mapped SessionSkillScore and the summary onto the existing Session document.
    /// Only those two fields are updated; the rest of the document is left alone.
    /// Throws if the session document doesn't exist.
    func save(_ report: AnalysisReport, sessionID: String, userID: String) async throws {
        // Turn our scores into the shared SessionSkillScore the Drills team reads
        let skillScore = SessionScoreMapper().make(from: report.scores, sessionID: sessionID, userID: userID)

        // A nested struct can't go into updateData directly, so encode it first
        let encoded = try Firestore.Encoder().encode(skillScore)

        let ref = Firestore.firestore().collection("Sessions").document(sessionID)
        try await ref.updateData([
            "sessionSkillScore": encoded,
            "summary": report.summary
        ])
    }
}