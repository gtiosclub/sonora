//
//  SessionViewModel.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/28/26.
//

import FirebaseFirestore

func acceptSession(userId: String, sessionID: String) async throws{
    // async means the function performs asynchronous work
    // throws means the function can pass errors back to whoever called it
    
    //access firestore
    let db = Firestore.firestore()
    
    // Get the session document using its ID
    let sessionRef = db.collection("Sessions").document(sessionID)
    let document = try await sessionRef.getDocument()
    
    // check to make sure the session exists
    guard document.exists else{
        return
    }
    
    // Make sure the user is a participant in the session
    guard let participants = document.data()?["participants"] as? [String],
          participants.contains(userId) else {
        return
    }
    
    // Add the user to the list of users who accepted the session
    try await sessionRef.updateData(["acceptedBy": FieldValue.arrayUnion([userId])])
    
    // Get the updated session data
    let updatedDocument = try await sessionRef.getDocument()
    // Get the updated list of users who accepted
    guard let acceptedBy = updatedDocument.data()?["acceptedBy"] as? [String] else {
        return
    }
    
    // Start the session once all participants have accepted
    if acceptedBy.count == participants.count {
        try await sessionRef.updateData(["status":"active"])
    }
}

func joinQueue(userID: String, mode: Session.Mode) async throws {
    let db = Firestore.firestore()

    try await db.collection("WaitingUsers").addDocument(data: [
        "userID": userID,
        "mode": mode.rawValue
    ])
}

// Finds one user waiting in the same mode, or returns nil if there isn't one
func findWaitingMatch(mode: Session.Mode) async throws -> WaitingUser? {
    let snapshot = try await Firestore.firestore()
        .collection("WaitingUsers")
        .whereField("mode", isEqualTo: mode.rawValue)
        .limit(to: 1)
        .getDocuments()

    guard let document = snapshot.documents.first else { return nil }
    return try document.data(as: WaitingUser.self)
}
