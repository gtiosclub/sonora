//
//  TranscriptStore.swift
//  Sonora
//

import FirebaseFirestore

/// Caches a session's transcript in Firestore so re-analysis can reuse it instead
/// of extracting audio and re-running Deepgram every time.
///
/// Stored in its own `Transcripts` collection (doc id = sessionID) rather than on
/// the Session document, so the word list doesn't bloat the Session reads that
/// `SessionScoreHistoryStore` does, and so it stays clear of the 1 MB/doc limit.
struct TranscriptStore {

    private var collection: CollectionReference {
        Firestore.firestore().collection("Transcripts")
    }

    /// Writes the transcript under the session's id, overwriting any existing one.
    func save(_ transcript: Transcript, sessionID: String) async throws {
        // Encode first so we can use the server-acknowledged async setData.
        let encoded = try Firestore.Encoder().encode(transcript)
        try await collection.document(sessionID).setData(encoded)
    }

    /// Returns the cached transcript for a session, or nil if none is stored.
    func load(sessionID: String) async throws -> Transcript? {
        let snapshot = try await collection.document(sessionID).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: Transcript.self)
    }
}
