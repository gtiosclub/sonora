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

// Creates a new active session against the AI and saves it to the "Sessions" collection.
// Returns the saved session.
func createAISession(userId: String, mode: Session.Mode) async throws -> Session {
    let ref = Firestore.firestore().collection("Sessions").document()  // new empty doc: Firestore picks the ID
    let now = Date()
    let session = Session(
        id: ref.documentID,
        participants: [userId],
        status: .active,
        acceptedBy: [userId],
        mode: mode,
        opponentType: .ai,
        startTime: now,
        creaedAt: now
    )

    try ref.setData(from: session)   // Dates are saved as Firestore timestamps
    return session
}
