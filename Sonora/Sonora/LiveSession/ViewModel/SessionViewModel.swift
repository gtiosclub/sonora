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
        
        let db = Firestore.firestore()
        
        let documentRef = try await db.collection("Sessions")
            .addDocument(data: [
                "participants": [fromUserId, toUserId],
                "acceptedBy": [fromUserId],
                "mode": mode.rawValue,
                "status": "pending"
            ])
        
        return documentRef.documentID
}

// Validates that a session with that session id exists and is currently active
// Sets the status of that function to completed
// Populates end time and sets duration in seconds
func completeSession(sessionID: String) async throws {
    let db = Firestore.firestore()
    let sessionRef = db.collection("Sessions").document(sessionID)

    let document = try await sessionRef.getDocument()

    guard document.exists else {
        return
    }

    let status = document.get("status") as? String

    guard status == "active" else {
        return
    }

    // Get start time and calculate duration if it exists
    if let startTime = document.get("startTime") as? Timestamp {
        let startDate = startTime.dateValue()
        let endDate = Date.now
        let duration = endDate.timeIntervalSince(startDate)

        try await sessionRef.updateData([
            "durationSeconds": duration,
            "endTime": Timestamp(date: endDate)
        ])
    }

    // Mark session as completed
    try await sessionRef.updateData([
        "status": "completed"
    ])

    // Increment session count for each participant
    if let participants = document.get("participants") as? [String] {
        for userId in participants {
            let userRef = db.collection("Users").document(userId)

            try await userRef.setData([
                "sessionCount": FieldValue.increment(Int64(1))
            ], merge: true)
        }
    }
}

func calcUserSimilarity(userID1: String, userID2: String) async throws -> Double? {
    // access firestore
    let db = Firestore.firestore()
    
    // get the skill profile document for user 1
    let user1Ref = db.collection("SkillProfile").document(userID1)
    let doc1 = try await user1Ref.getDocument()
    
    // get the skill profile document for user 2
    let user2Ref = db.collection("SkillProfile").document(userID2)
    let doc2 = try await user2Ref.getDocument()
    
    
    // check to make sure both skill profile documents exist and get their data
    guard let data1 = doc1.data(), let data2 = doc2.data() else {
        return nil
    }
    	
    let categories = ["clarity", "confidence", "content", "engaging"]
    
    var squaredDiffSum = 0.0
    var validSkillCount = 0
    
    // loop through each skill category to calculate score differences
    for category in categories {
        var score1: Int?
        var score2: Int?
        
        // extract score for user 1
        if let categoryData = data1[category] as? [String: Any] {
            if let score = categoryData["score"] as? Int {
                score1 = score
            }
        }
        
        // extract score for user 2
        if let categoryData = data2[category] as? [String: Any] {
            if let score = categoryData["score"] as? Int {
                score2 = score
            }
        }
        
        // compare if both users have a valid score in this category
        if let s1 = score1, let s2 = score2 {
            // normalize the difference
            let diff = Double((s1 - s2)) / 100.0
            squaredDiffSum += (diff * diff)
            validSkillCount += 1
        }
    }
    
    // return if no scores were found
    guard validSkillCount > 0 else {
        return nil
    }
    
    // calculate normalized Euclidean distance
    let distance = sqrt(squaredDiffSum / Double(validSkillCount))
    	
    let similarity = 1.0 - distance
    
    return similarity
}	
