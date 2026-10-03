//
//  UserService.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/24/26.
//

import FirebaseFirestore

enum UserService {
    private static var users: CollectionReference {
        Firestore.firestore().collection("Users")
    }

    static func create(_ user: User) async throws {
        try users.document(user.userId).setData(from: user)
    }

    /// Returns nil if the user has no doc yet.
    static func fetch(userID: String) async throws -> User? {
        let snapshot = try await users.document(userID).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: User.self)
    }

    static func updateLastLogin(userID: String, date: Date) async throws {
        try await users.document(userID).updateData(["lastLogin": Timestamp(date: date)])
    }
}
