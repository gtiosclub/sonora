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

/// Finds another user by username or phone number.
final class UserSearchService {

    // ⚠️ Check these against Firestore Database -> Data in the Firebase Console.
    // You have both "Users" and "users" collections, so look at which one holds
    // real accounts with a username and phone number, and match it exactly.
    private static let collectionName = "users"
    private static let usernameField  = "username"
    private static let phoneField     = "phoneNumber"
    private static let nameFields     = ["fullName", "displayName", "name"]

    // lazy so creating this object doesn't touch Firebase until it's used
    private lazy var db = Firestore.firestore()

    func findUser(username: String) async throws -> FoundUser? {
        let cleaned = username.hasPrefix("@") ? String(username.dropFirst()) : username
        return try await findUser(field: Self.usernameField, value: cleaned)
    }

    /// Exact match on the phone number as it's stored in Firestore.
    func findUser(phone: String) async throws -> FoundUser? {
        try await findUser(field: Self.phoneField, value: phone)
    }

    private func findUser(field: String, value: String) async throws -> FoundUser? {
        let snapshot = try await db.collection(Self.collectionName)
            .whereField(field, isEqualTo: value)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        let data = doc.data()
        let username = data[Self.usernameField] as? String ?? ""
        let name = Self.nameFields.compactMap { data[$0] as? String }.first ?? username
        return FoundUser(id: doc.documentID, username: username, displayName: name)
    }
}
