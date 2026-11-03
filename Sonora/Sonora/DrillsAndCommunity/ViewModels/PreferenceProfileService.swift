//
//  PreferenceProfileService.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 10/15/26.
//

import FirebaseFirestore

enum PreferenceProfileService {
    // Same collection AuthManager.signUp writes to
    private static var profiles: CollectionReference {
        Firestore.firestore().collection("PreferencesProfile")
    }

    // Add PreferenceProfile to Firebase
    static func add(_ profile: PreferenceProfile, for userId: String) async throws {
        try await profiles.document(userId).setData(from: profile)
    }

    // Get User's PreferenceProfile from Firebase
    static func fetch(for userId: String) async throws -> PreferenceProfile? {
        let snapshot = try await profiles.document(userId).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: PreferenceProfile.self)
    }

    // Update existing PreferenceProfile in Firebase
    static func update(_ profile: PreferenceProfile, for userId: String) async throws {
        try await profiles.document(userId).setData(from: profile, merge: true)
    }
}
