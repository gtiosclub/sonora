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

/// Finds users by username, phone number, or ID.
final class UserSearchService {

    // ⚠️ Check these against Firestore Database -> Data in the Firebase Console.
    // You have both "Users" and "users" collections, so look at which one holds
    // real accounts with a username and phone number, and match it exactly.
    // FirestoreProfileRepository uses the same collection name; keep them in sync.
    private static let collectionName = "Users"
    private static let usernameField  = "username"
    private static let emailField     = "email"
    private static let phoneField = "phoneNumber"
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

    /// Matches the phone number as onboarding stores it (digits and a leading "+").
    func findUser(phone: String) async throws -> FoundUser? {
        let normalized = PhoneNumberFormatter.normalize(phone)
        guard !normalized.isEmpty else { return nil }
        let snapshot = try await db.collection(Self.collectionName)
            .whereField(Self.phoneField, isEqualTo: normalized)
            .limit(to: 1)
            .getDocuments()
        return makeFoundUser(from: snapshot)
    }

    /// Look up a user by their UID (used for friends lists).
    func findUser(id: String) async throws -> FoundUser? {
        let doc = try await db.collection(Self.collectionName).document(id).getDocument()
        guard let data = doc.data() else { return nil }
        return makeUser(id: doc.documentID, data: data)
    }

    private func makeFoundUser(from snapshot: QuerySnapshot) -> FoundUser? {
        guard let doc = snapshot.documents.first else { return nil }
        return makeUser(id: doc.documentID, data: doc.data())
    }

    private func makeUser(id: String, data: [String: Any]) -> FoundUser {
        let username = data[Self.usernameField] as? String ?? ""
        let name = Self.nameFields.compactMap { data[$0] as? String }.first ?? username
        return FoundUser(id: id, username: username, displayName: name)
    }
}
