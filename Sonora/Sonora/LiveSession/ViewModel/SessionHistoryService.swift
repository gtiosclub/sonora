//
//  SessionHistoryService.swift
//  Sonora
//
//  Created by Nidhi Nagumalla on 10/28/26.
//


import Foundation
import FirebaseFirestore

enum SessionHistoryService {

    private static var sessions: CollectionReference {
        Firestore.firestore().collection("Sessions")
    }

    /// Fetches completed sessions involving the given user,
    /// ordered from most recent to oldest.
    static func fetchCompletedSessions(userID: String) async throws -> [Session] {
        let snapshot = try await sessions
            .whereField("participants", arrayContains: userID)
            .getDocuments()

        
        let completedSessions = snapshot.documents.compactMap { document -> Session? in

            do {
                let session = try document.data(as: Session.self)
                return session.status == .completed ? session : nil
            } catch {
                print("Failed to decode session \(document.documentID): \(error)")
                return nil
            }
        }

        return completedSessions.sorted {
            $0.createdAt > $1.createdAt
        }
    }
}
