//
//  FriendshipService.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/27/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum FriendshipError: LocalizedError {
    case notSignedIn
    case invalidUser
    case alreadyExists
    case notFound
    case unavailable

    var errorDescription: String? {
        switch self {
        case .notSignedIn:   return "You need to be signed in."
        case .invalidUser:   return "You can't do that with yourself."
        case .alreadyExists: return "A request or friendship already exists."
        case .notFound:      return "Friendship not found."
        case .unavailable:   return "That action isn't available."
        }
    }
}

final class FriendshipService {
    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("friendships") }

    private var currentUserId: String? { Auth.auth().currentUser?.uid }

    /// Same sorted-pair ID the security rules expect: A_B == B_A.
    static func pairId(_ a: String, _ b: String) -> String {
        [a, b].sorted().joined(separator: "_")
    }

    // MARK: - 1. Send request

    func sendRequest(to receiverId: String) async throws {
        guard let uid = currentUserId else { throw FriendshipError.notSignedIn }
        guard receiverId != uid else { throw FriendshipError.invalidUser }

        let ref = collection.document(Self.pairId(uid, receiverId))
        if try await ref.getDocument().exists { throw FriendshipError.alreadyExists }

        try await ref.setData([
            "requesterId": uid,
            "receiverId": receiverId,
            "participants": [uid, receiverId],
            "status": FriendshipStatus.pending.rawValue,
            "blockedBy": NSNull(),
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - 2. Accept (pending -> accepted)

    func acceptRequest(friendshipId: String) async throws {
        guard currentUserId != nil else { throw FriendshipError.notSignedIn }

        // Rules enforce: only the receiver, and only while pending.
        try await collection.document(friendshipId).updateData([
            "status": FriendshipStatus.accepted.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - 3. Block

    func block(userId targetId: String) async throws {
        guard let uid = currentUserId else { throw FriendshipError.notSignedIn }
        guard targetId != uid else { throw FriendshipError.invalidUser }

        let ref = collection.document(Self.pairId(uid, targetId))
        let snapshot = try await ref.getDocument()

        if snapshot.exists {
            if let existing = try? snapshot.data(as: Friendship.self),
               existing.status == .blocked, existing.blockedBy != uid {
                throw FriendshipError.unavailable
            }
            try await ref.updateData([
                "status": FriendshipStatus.blocked.rawValue,
                "blockedBy": uid,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } else {
            try await ref.setData([
                "requesterId": uid,
                "receiverId": targetId,
                "participants": [uid, targetId],
                "status": FriendshipStatus.blocked.rawValue,
                "blockedBy": uid,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }

    // MARK: - 4. Delete (unfriend / cancel / decline / unblock)

    func delete(friendshipId: String) async throws {
        guard currentUserId != nil else { throw FriendshipError.notSignedIn }
        // Rules enforce: participants only, and only the blocker can remove a block.
        try await collection.document(friendshipId).delete()
    }

    // MARK: - Reading

    /// All friendships (any status) involving the current user.
    func fetchMyFriendships() async throws -> [Friendship] {
        guard let uid = currentUserId else { throw FriendshipError.notSignedIn }
        let snapshot = try await collection
            .whereField("participants", arrayContains: uid)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Friendship.self) }
    }
}
