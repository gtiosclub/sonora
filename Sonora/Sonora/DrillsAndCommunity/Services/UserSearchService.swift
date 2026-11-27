//
//  UserSearchService.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/6/26.
//

import Foundation
import FirebaseFirestore

struct FoundUser: Identifiable, Equatable {
    let id: String          // Firebase UID (the user document's ID)
    let username: String
    let displayName: String
}

/// Finds another user by username or email address. Not case-sensitive.
final class UserSearchService {

    // Same collection and fields AuthManager.signUp writes (see User.swift).
    private static let collectionName = "Users"
    private static let usernameField  = "username"
    private static let emailField     = "email"
    // Lowercase copies written by AuthManager (see UserService.searchKeys).
    private static let usernameKey    = "usernameLowercase"
    private static let emailKey       = "emailLowercase"
    private static let nameFields     = ["fullName", "displayName", "name"]

    // lazy so creating this object doesn't touch Firebase until it's used
    private lazy var db = Firestore.firestore()

    func findUser(username: String) async throws -> FoundUser? {
        let cleaned = username.hasPrefix("@") ? String(username.dropFirst()) : username
        return try await findUser(key: Self.usernameKey, fallbackField: Self.usernameField, value: cleaned)
    }

    func findUser(email: String) async throws -> FoundUser? {
        try await findUser(key: Self.emailKey, fallbackField: Self.emailField, value: email)
    }

    /// Matches the lowercase key first. Accounts that haven't opened the app since the
    /// keys were added don't have them yet, so fall back to the original field,
    /// trying the text as typed and all lowercase.
    private func findUser(key: String, fallbackField: String, value: String) async throws -> FoundUser? {
        let users = db.collection(Self.collectionName)

        let byKey = try await users
            .whereField(key, isEqualTo: value.lowercased())
            .limit(to: 1)
            .getDocuments()
        if let found = makeFoundUser(from: byKey) { return found }

        let byField = try await users
            .whereField(fallbackField, in: Array(Set([value, value.lowercased()])))
            .limit(to: 1)
            .getDocuments()
        return makeFoundUser(from: byField)
    }

    private func makeFoundUser(from snapshot: QuerySnapshot) -> FoundUser? {
        guard let doc = snapshot.documents.first else { return nil }
        let data = doc.data()
        let username = data[Self.usernameField] as? String ?? ""
        let name = Self.nameFields.compactMap { data[$0] as? String }.first ?? username
        return FoundUser(id: doc.documentID, username: username, displayName: name)
    }
}
