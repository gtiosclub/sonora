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
    private static let collectionName = "users"
    private static let usernameField  = "username"
    private static let phoneField     = "phoneNumber"
    private static let nameFields     = ["fullName", "displayName", "name"]

    // lazy so creating this object doesn't touch Firebase until it's used
    private lazy var db = Firestore.firestore()

    func findUser(username: String) async throws -> FoundUser? {
        // Onboarding stores usernames lowercase, so search lowercase too.
        let cleaned = username.hasPrefix("@") ? String(username.dropFirst()) : username
        return try await findUser(field: Self.usernameField, value: cleaned.lowercased())
    }

    /// Matches the phone number as onboarding stores it (digits and a leading "+").
    func findUser(phone: String) async throws -> FoundUser? {
        let normalized = PhoneNumberFormatter.normalize(phone)
        guard !normalized.isEmpty else { return nil }
        return try await findUser(field: Self.phoneField, value: normalized)
    }

    /// Look up a user by their UID (used for friends lists).
    func findUser(id: String) async throws -> FoundUser? {
        let doc = try await db.collection(Self.collectionName).document(id).getDocument()
        guard let data = doc.data() else { return nil }
        return makeUser(id: doc.documentID, data: data)
    }

    private func findUser(field: String, value: String) async throws -> FoundUser? {
        let snapshot = try await db.collection(Self.collectionName)
            .whereField(field, isEqualTo: value)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return makeUser(id: doc.documentID, data: doc.data())
    }

    private func makeUser(id: String, data: [String: Any]) -> FoundUser {
        let username = data[Self.usernameField] as? String ?? ""
        let name = Self.nameFields.compactMap { data[$0] as? String }.first ?? username
        return FoundUser(id: id, username: username, displayName: name)
    }
}
