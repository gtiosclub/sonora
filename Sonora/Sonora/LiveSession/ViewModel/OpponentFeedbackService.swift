//
//  OpponentFeedbackService.swift
//  Sonora
//
//  Asks for and stores human feedback about an opponent after a live session.
//  Matches the style of SessionViewModel.swift (free async functions, "Sessions" collection).
//

import FirebaseFirestore

// Only live opponent (human vs. human) sessions should ask for feedback.
// AI sessions skip it.
func shouldAskForOpponentFeedback(session: Session) -> Bool {
    return session.opponentType == .human
}

// Returns the other player's ID if this was a live opponent session,
// or nil for AI sessions (so no feedback is asked).
func liveOpponentId(in session: Session, currentUserId: String) -> String? {
    guard shouldAskForOpponentFeedback(session: session) else {
        return nil
    }
    return session.participants.first(where: { $0 != currentUserId })
}

// Saves one user's feedback about their opponent to
// Sessions/{sessionID}/Feedback/{userId}.
// Using userId as the document ID means each player leaves at most one
// feedback per session (submitting again overwrites it).
func submitOpponentFeedback(
    userId: String,
    sessionID: String,
    rating: Int,
    tags: [String],
    comment: String
) async throws {
    // Rating must be 1–5
    guard (1...5).contains(rating) else {
        return
    }

    let db = Firestore.firestore()
    let sessionRef = db.collection("Sessions").document(sessionID)
    let document = try await sessionRef.getDocument()

    // Check to make sure the session exists
    guard document.exists else {
        return
    }

    // Only collect feedback for live opponent sessions
    guard let opponentType = document.data()?["opponentType"] as? String,
          opponentType == "human" else {   // must match how .human is saved in Firestore
        return
    }

    // Make sure the user was a participant, and find their opponent
    guard let participants = document.data()?["participants"] as? [String],
          participants.contains(userId),
          let opponentId = participants.first(where: { $0 != userId }) else {
        return
    }

    // Save the feedback in a subcollection under the session
    try await sessionRef.collection("Feedback").document(userId).setData([
        "raterId": userId,
        "opponentId": opponentId,
        "sessionId": sessionID,
        "mode": document.data()?["mode"] as? String ?? "",
        "rating": rating,
        "tags": tags,
        "comment": comment.trimmingCharacters(in: .whitespacesAndNewlines),
        "createdAt": FieldValue.serverTimestamp()
    ])
}
