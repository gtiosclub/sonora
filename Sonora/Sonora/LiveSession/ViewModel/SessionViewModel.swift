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



func joinQueue(userId: String, mode: Session.Mode, topic: DebateTopic? = nil) async throws {
    // Creates firestore object
    let db = Firestore.firestore()
    
    // .document(userID) sets the document name to match the userID
    let docRef = db.collection("WaitingUsers").document(userId)
    
    // Debate users must select a topic
    if mode == .debate && topic == nil {
        throw JoinQueueError.missingDebateTopic
    }
    
    var data: [String: Any] = [
            "userId": userId,
            "mode": mode.rawValue,
            "joinedAt": Timestamp(date: Date())
        ]
    // Save the selected debate topic when provided
    if let topic = topic, mode == .debate {
        data["topic"] = topic.rawValue
    }

    try await docRef.setData(data)
}

    enum JoinQueueError: Error {
        case missingDebateTopic
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
        createdAt: now
    )

    try ref.setData(from: session)   // Dates are saved as Firestore timestamps
    return session
}
// Finds one user waiting in the same mode, or returns nil if there isn't one
func findWaitingMatch(userId: String, mode: Session.Mode, topic: DebateTopic? = nil) async throws -> WaitingUser? {
    // Debate users must select a topic
    if mode == .debate && topic == nil {
        throw JoinQueueError.missingDebateTopic
    }
    
        // Find users waiting in the same mode
    var query: Query = Firestore.firestore()
        .collection("WaitingUsers")
        .whereField("mode", isEqualTo: mode.rawValue)

        // For debates, also require the same topic
    if mode == .debate, let topic = topic {
        query = query.whereField("topic", isEqualTo: topic.rawValue)
    }

    let snapshot = try await query.getDocuments()
    guard let document = snapshot.documents.first(where: {
        $0.documentID != userId
    }) else {
        return nil
    }
    return try document.data(as: WaitingUser.self)
}

func cancelWaitingRequest(userId: String) async throws {
    // Creates firestore object
    let db = Firestore.firestore()
    
    // The queue document ID is the user's ID.
    let docRef = db.collection("WaitingUsers").document(userId)
    
    // Deletes document
    // If userId doesn't exist, function doesn't do anything and no errors thrown
    try await docRef.delete()
}


// Creates a new pending session between two users and saves it to Firestore.
func createPendingSession(
    userID1: String,
    userID2: String,
    mode: Session.Mode,
    topic: DebateTopic? = nil
) async throws -> Session {
    // Debate sessions must have a selected topic
    if mode == .debate && topic == nil {
        throw JoinQueueError.missingDebateTopic
    }
    
    // Create a new session document with an auto-generated ID.
    let ref = Firestore.firestore()
        .collection("Sessions")
        .document()
    
    // Get the current date and time.
    let now = Date()
    
    // Create the session.
    var session = Session(
        id: ref.documentID,
        participants: [userID1, userID2],
        status: .pending,
        acceptedBy: [],
        mode: mode,
        opponentType: .human,
        startTime: Optional.none,
        createdAt: now
    )
    // Save the selected debate question on the session
    if mode == .debate, let topic = topic {
        session.prompt = topic.question
    }
    
    // Save the session to Firestore.
    try ref.setData(from: session)
    
    return session
}

// Observes sessions containing this user, including pending and terminal status changes.
@discardableResult
func listenForUserSessions(
    userId: String,
    onChange: @escaping (Result<[Session], Error>) -> Void
) -> ListenerRegistration {
    Firestore.firestore()
        .collection("Sessions")
        .whereField("participants", arrayContains: userId)
        .addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }

            guard let snapshot else { return }
            let sessions = snapshot.documents.compactMap { try? decodeSession($0) }
            onChange(.success(sessions))
        }
}

// Observes status and participant changes for a single session.
@discardableResult
func listenToSession(
    sessionId: String,
    onChange: @escaping (Result<Session, Error>) -> Void
) -> ListenerRegistration {
    Firestore.firestore()
        .collection("Sessions")
        .document(sessionId)
        .addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }

            guard let snapshot, snapshot.exists else { return }
            do {
                onChange(.success(try decodeSession(snapshot)))
            } catch {
                onChange(.failure(error))
            }
        }
}

private func decodeSession(_ document: DocumentSnapshot) throws -> Session {
    if var session = try? document.data(as: Session.self) {
        session.id = document.documentID
        return session
    }

    guard let data = document.data(),
          let participants = data["participants"] as? [String],
          let statusRawValue = data["status"] as? String,
          let status = Session.Status(rawValue: statusRawValue),
          let modeRawValue = data["mode"] as? String,
          let mode = Session.Mode(rawValue: modeRawValue) else {
        throw SessionListenerError.invalidSessionDocument
    }

    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
    let startTime = (data["startTime"] as? Timestamp)?.dateValue()
    let opponentType = (data["opponentType"] as? String)
        .flatMap(Session.OpponentType.init(rawValue:)) ?? .human

    return Session(
        id: document.documentID,
        participants: participants,
        status: status,
        acceptedBy: data["acceptedBy"] as? [String] ?? [],
        aIOpponent: nil,
        mode: mode,
        opponentType: opponentType,
        startTime: startTime,
        createdAt: createdAt,
        durationSeconds: data["durationSeconds"] as? Int,
        topic: nil,
        sessionSkillScore: nil,
        summary: data["summary"] as? String,
        prompt: data["prompt"] as? String,
        analysis: data["analysis"] as? String,
        scores: data["scores"] as? [Int]
    )
}

private enum SessionListenerError: LocalizedError {
    case invalidSessionDocument

    var errorDescription: String? {
        "The session document is missing required fields."
    }
}

func requestRandomMatch(userId: String, mode: Session.Mode, topic: DebateTopic? = nil) async throws -> Session? {
    // Unwraps waitingUser object
    if let matchedUser = try await findWaitingMatch(userId: userId,  mode: mode, topic: topic) {
        guard matchedUser.userId != userId else {
            try await joinQueue(userId: userId, mode: mode)
            return nil
        }
        // Remove the exact matched queue document before creating the session.
        try await cancelWaitingRequest(userId: matchedUser.id ?? matchedUser.userId)
        
        // Creates a new session
        let session = try await createPendingSession(
            userID1: matchedUser.userId,
            userID2: userId,
            mode: mode,
            topic: topic)
        return session
    } else {
        // Adds user to queue if nil is unwrapped
        try await joinQueue(userId: userId, mode: mode, topic: topic)
        return nil
    }
}
    
func inviteFriendToSession(
        fromUserId: String,
        toUserId: String,
        mode: Session.Mode
    ) async throws -> String {

        let documentRef = Firestore.firestore().collection("Sessions").document()
        let now = Date()
        let session = Session(
            id: documentRef.documentID,
            participants: [fromUserId, toUserId],
            status: .pending,
            acceptedBy: [fromUserId],
            mode: mode,
            opponentType: .human,
            startTime: nil,
            createdAt: now
        )
        try documentRef.setData(from: session)
        return documentRef.documentID
}

