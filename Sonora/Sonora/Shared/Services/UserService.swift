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

    /// Lowercase copies of username and email. Firestore can't search case-insensitively,
    /// so friend search (UserSearchService) matches on these instead.
    static func searchKeys(username: String, email: String) -> [String: Any] {
        [
            "usernameLowercase": username.lowercased(),
            "emailLowercase": email.lowercased()
        ]
    }

    /// Adds or refreshes the search keys on an existing user doc.
    static func updateSearchKeys(for user: User) async throws {
        try await users.document(user.userId)
            .updateData(searchKeys(username: user.username, email: user.email))
    }

    static func updateLastLogin(userID: String, date: Date) async throws {
        try await users.document(userID).updateData(["lastLogin": Timestamp(date: date)])
    }

    /// Returns nil if the user has no doc yet.
    static func getStreak(userID: String) async throws -> Int? {
        let snapshot = try await users.document(userID).getDocument()
        guard snapshot.exists else { return nil }
        return snapshot.get("streak") as? Int ?? 0
    }

    static func updateStreak(userID: String, streak: Int) async throws {
        try await users.document(userID).updateData(["streak": streak])
        try await AchievementService.syncStreakAchievement(userId: userID, streak: streak)
    }
}
