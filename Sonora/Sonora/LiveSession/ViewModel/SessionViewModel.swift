//
//  SessionViewModel.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/28/26.
//
import FirebaseFirestore

func joinQueue(userID: String, mode: Session.Mode) async throws {
    let db = Firestore.firestore()

    try await db.collection("WaitingUsers").addDocument(data: [
        "userID": userID,
        "mode": mode.rawValue
    ])
}
