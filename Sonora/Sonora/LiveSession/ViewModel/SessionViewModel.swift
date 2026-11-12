//
//  SessionViewModel.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/28/26.
//

import FirebaseFirestore

func acceptSession(userId: String, sessionID: String) async throws {
    let db = Firestore.firestore()
    let ref = db.collection("Sessions").document(sessionID)

    _ = try await db.runTransaction { txn, errorPointer in
        let snap: DocumentSnapshot
        do { snap = try txn.getDocument(ref) }
        catch { errorPointer?.pointee = error as NSError; return nil }

        guard let data = snap.data(),
              let participants = data["participants"] as? [String],
              participants.contains(userId),
              (data["status"] as? String) == "pending" else { return nil }

        var accepted = data["acceptedBy"] as? [String] ?? []
        if !accepted.contains(userId) { accepted.append(userId) }

        var update: [String: Any] = ["acceptedBy": accepted]
        if Set(accepted) == Set(participants) {
            update["status"] = "active"
            update["startTime"] = Timestamp(date: Date())
        }
        txn.updateData(update, forDocument: ref)
        return nil
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
func createAISession(userId: String, mode: Session.Mode, topic: DebateTopic? = nil) async throws -> Session {
    if mode == .debate && topic == nil {
        throw JoinQueueError.missingDebateTopic
    }

    let ref = Firestore.firestore().collection("Sessions").document()  // new empty doc: Firestore picks the ID
    let now = Date()
    var session = Session(
        id: ref.documentID,
        participants: [userId],
        status: .active,
        acceptedBy: [userId],
        mode: mode,
        opponentType: .ai,
        startTime: now,
        createdAt: now
    )

    if mode == .debate, let topic {
        session.prompt = topic.question
    }

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

func findWaitingCandidates(userId: String, mode: Session.Mode, topic: DebateTopic? = nil) async throws -> [WaitingUser] {
    if mode == .debate && topic == nil {
        throw JoinQueueError.missingDebateTopic
    }

    var query: Query = Firestore.firestore()
        .collection("WaitingUsers")
        .whereField("mode", isEqualTo: mode.rawValue)

    if mode == .debate, let topic {
        query = query.whereField("topic", isEqualTo: topic.rawValue)
    }

    let snapshot = try await query.getDocuments()
    return try snapshot.documents
        .filter { $0.documentID != userId }
        .map { try $0.data(as: WaitingUser.self) }
}

@discardableResult
func listenForWaitingCandidates(
    userId: String,
    mode: Session.Mode,
    topic: DebateTopic? = nil,
    onChange: @escaping (Result<[WaitingUser], Error>) -> Void
) -> ListenerRegistration {
    var query: Query = Firestore.firestore()
        .collection("WaitingUsers")
        .whereField("mode", isEqualTo: mode.rawValue)

    if mode == .debate, let topic {
        query = query.whereField("topic", isEqualTo: topic.rawValue)
    }

    return query.addSnapshotListener { snapshot, error in
        if let error {
            onChange(.failure(error))
            return
        }
        guard let snapshot else { return }

        do {
            let candidates = try snapshot.documents
                .filter { $0.documentID != userId }
                .map { try $0.data(as: WaitingUser.self) }
            onChange(.success(candidates))
        } catch {
            onChange(.failure(error))
        }
    }
}

let matchSimilarityThreshold = 0.75

func rankWaitingCandidates(
    userID: String,
    candidates: [WaitingUser]
) async throws -> [(candidate: WaitingUser, score: Double)] {
    let maxConcurrentLookups = 8

    return try await withThrowingTaskGroup(of: (Int, Double).self) { group in
        var scores = Array(repeating: 0.0, count: candidates.count)
        var nextIndex = 0

        for index in 0..<min(maxConcurrentLookups, candidates.count) {
            let candidateUserID = candidates[index].userId
            group.addTask {
                let score = try await calcUserSimilarity(
                    userID1: userID,
                    userID2: candidateUserID
                ) ?? 0
                return (index, score)
            }
            nextIndex += 1
        }

        while let (index, score) = try await group.next() {
            scores[index] = score

            if nextIndex < candidates.count {
                let candidateIndex = nextIndex
                let candidateUserID = candidates[candidateIndex].userId
                group.addTask {
                    let score = try await calcUserSimilarity(
                        userID1: userID,
                        userID2: candidateUserID
                    ) ?? 0
                    return (candidateIndex, score)
                }
                nextIndex += 1
            }
        }

        return candidates.enumerated()
            .map { (candidate: $0.element, score: scores[$0.offset]) }
            .sorted { $0.score > $1.score }
    }
}

// Atomically claims both queue entries and creates the pending session. This prevents
// two clients from matching the same waiting user at the same time.
func claimWaitingCandidate(
    userId: String,
    candidate: WaitingUser,
    mode: Session.Mode,
    topic: DebateTopic? = nil
) async throws -> Session? {
    guard let candidateDocumentId = candidate.id else { return nil }
    if mode == .debate && topic == nil {
        throw JoinQueueError.missingDebateTopic
    }

    let db = Firestore.firestore()
    let currentUserRef = db.collection("WaitingUsers").document(userId)
    let candidateRef = db.collection("WaitingUsers").document(candidateDocumentId)
    let sessionRef = db.collection("Sessions").document()
    let now = Date()
    var session = Session(
        id: sessionRef.documentID,
        participants: [candidate.userId, userId],
        status: .pending,
        acceptedBy: [],
        mode: mode,
        opponentType: .human,
        startTime: nil,
        createdAt: now
    )
    if mode == .debate, let topic {
        session.prompt = topic.question
    }

    var sessionData: [String: Any] = [
        "id": session.id,
        "participants": session.participants,
        "status": session.status.rawValue,
        "acceptedBy": session.acceptedBy,
        "mode": session.mode.rawValue,
        "opponentType": session.opponentType.rawValue,
        "startTime": NSNull(),
        "createdAt": Timestamp(date: session.createdAt)
    ]
    if let prompt = session.prompt {
        sessionData["prompt"] = prompt
    }

    let result = try await db.runTransaction { transaction, errorPointer in
        do {
            let currentUserSnapshot = try transaction.getDocument(currentUserRef)
            let candidateSnapshot = try transaction.getDocument(candidateRef)
            guard let currentUserData = currentUserSnapshot.data(),
                  currentUserData["userId"] as? String == userId,
                  currentUserData["mode"] as? String == mode.rawValue,
                  mode != .debate || currentUserData["topic"] as? String == topic?.rawValue,
                  let candidateData = candidateSnapshot.data(),
                  candidateData["userId"] as? String == candidate.userId,
                  candidateData["mode"] as? String == mode.rawValue,
                  mode != .debate || candidateData["topic"] as? String == topic?.rawValue else {
                return nil
            }

            transaction.deleteDocument(currentUserRef)
            transaction.deleteDocument(candidateRef)
            transaction.setData(sessionData, forDocument: sessionRef)
            return session
        } catch {
            errorPointer?.pointee = error as NSError
            return nil
        }
    }

    return result as? Session
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
    since: Date,
    onChange: @escaping (Result<[Session], Error>) -> Void
) -> ListenerRegistration {
    Firestore.firestore()
        .collection("Sessions")
        .whereField("participants", arrayContains: userId)
        .addSnapshotListener { snapshot, error in
            if let error { onChange(.failure(error)); return }
            guard let snapshot else { return }
            let sessions = snapshot.documents
                .compactMap { try? decodeSession($0) }
                .filter { $0.createdAt >= since.addingTimeInterval(-5) }  // small clock-skew buffer
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
    try await joinQueue(userId: userId, mode: mode, topic: topic)

    let candidates = try await findWaitingCandidates(userId: userId, mode: mode, topic: topic)
    let rankedCandidates = try await rankWaitingCandidates(userID: userId, candidates: candidates)

    for rankedCandidate in rankedCandidates where rankedCandidate.score >= matchSimilarityThreshold {
        if let session = try await claimWaitingCandidate(
            userId: userId,
            candidate: rankedCandidate.candidate,
            mode: mode,
            topic: topic
        ) {
            return session
        }
    }

    return nil
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


    let data1 = doc1.data() ?? [:]
    let data2 = doc2.data() ?? [:]

    let categories = ["clarity", "confidence", "content", "engaging"]

    let baseline = 50.0

    var squaredDiffSum = 0.0
    var validSkillCount = 0

    // loop through each skill category to calculate score differences
    for category in categories {
        var score1: Double = baseline
        var score2: Double = baseline

        // extract score for user 1
        if let categoryData = data1[category] as? [String: Any] {
            if let score = categoryData["score"] as? Int {
                score1 = Double(score)
            }
        }

        // extract score for user 2
        if let categoryData = data2[category] as? [String: Any] {
            if let score = categoryData["score"] as? Int {
                score2 = Double(score)
            }
        }

        // compare both users and normalize the difference
        let diff = (score1 - score2) / 100.0
        squaredDiffSum += (diff * diff)
        validSkillCount += 1
    }

    // safeguard to prevent dividing by 0
    guard validSkillCount > 0 else {
        return nil
    }

    // calculate normalized Euclidean distance
    let distance = sqrt(squaredDiffSum / Double(validSkillCount))

    let similarity = 1.0 - distance

    return similarity
}
