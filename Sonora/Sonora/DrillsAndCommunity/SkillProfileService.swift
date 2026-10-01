//
//  SkillProfileService.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 10/1/26.
//

import FirebaseFirestore

enum SkillProfileService {
    // Same collection AuthManager.signUp writes to
    private static var profiles: CollectionReference {
        Firestore.firestore().collection("SkillProfile")
    }

    // Add SkillProfile to Firebase
    static func add(_ profile: SkillProfile, for userId: String) async throws {
        try await profiles.document(userId).setData(from: profile)
    }

    // Get User's SkillProfile from Firebase
    static func fetch(for userId: String) async throws -> SkillProfile? {
        let snapshot = try await profiles.document(userId).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: SkillProfile.self)
    }

    // Update existing SkillProfile in Firebase
    static func update(_ profile: SkillProfile, for userId: String) async throws {
        try await profiles.document(userId).setData(from: profile, merge: true)
    }
}
