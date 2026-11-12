//
//  FriendSearchService.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 10/26/26.
//

import FirebaseFirestore

enum FriendSearchService {
    private static var users: CollectionReference {
        Firestore.firestore().collection("Users")
    }

    // Search Users by username
    static func searchByUsername(_ query: String, excluding currentUserId: String? = nil) async throws -> [User] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        let snapshot = try await users
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThan: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        return decodeUsers(snapshot, excluding: currentUserId)
    }

    // Search Users by email (needs full email)
    static func searchByEmail(_ query: String, excluding currentUserId: String? = nil) async throws -> [User] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        let candidates = Array(Set([query, query.lowercased()]))
        let snapshot = try await users
            .whereField("email", in: candidates)
            .getDocuments()
        return decodeUsers(snapshot, excluding: currentUserId)
    }

    // anything with an "@" is treated as an email adn everything else as a username
    static func search(_ query: String, excluding currentUserId: String? = nil) async throws -> [User] {
        if query.contains("@") {
            return try await searchByEmail(query, excluding: currentUserId)
        }
        return try await searchByUsername(query, excluding: currentUserId)
    }

    // Skips your own account and other profiles that don't have the fully filled in field
    private static func decodeUsers(_ snapshot: QuerySnapshot, excluding currentUserId: String?) -> [User] {
        snapshot.documents
            .compactMap { try? $0.data(as: User.self) }
            .filter { $0.userId != currentUserId }
    }
}
