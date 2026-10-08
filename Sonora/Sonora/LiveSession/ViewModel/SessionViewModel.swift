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


func declineSession(userId: String, sessionID:String) async throws{
    let db = Firestore.firestore()
    
    let sessionRef = db.collection("Sessions").document(sessionID)
    let document = try await sessionRef.getDocument()
    
    // check to make sure the session exists
    guard document.exists else{
        return
    }
    // Check to make sure the user is a participant
    guard let participants = document.data()?["participants"] as? [String],
          participants.contains(userId) else {
        return
    }
    // Set the session status to declined
    try await sessionRef.updateData(["status":"declined"])
    
}



func joinQueue(userID: String, mode: Session.Mode) async throws {
    let db = Firestore.firestore()
    
    // .document(userID) sets the document name to match the userID
    let docRef = db.collection("WaitingUsers").document(userId)
    
    // Adds document to "Waiting users"
    try await docRef.setData([
        "userId": userId,
        "mode": mode.rawValue
    ])
}

func cancelWaitingRequest(userId: String) async throws {
    // Creates firestore object
    let db = Firestore.firestore()
    
    // Sets reference variable docRef to the document that needs to be deleted
    let docRef = db.collection("WaitingUsers").document(userId)
    
    // Deletes document
    // If userId doesn't exist, function doesn't do anything and no errors thrown
    try await docRef.delete()
}

