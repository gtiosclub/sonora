//
//  ProfileRepository.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/12/26.
//

//  The ViewModels only talk to this protocol, not to Firebase directly.
//  To connect Firebase later, need to write a `FirestoreProfileRepository` that
//  conforms to it and pass it into ProfileViewModel. No view code changes.

import Foundation

@MainActor
protocol ProfileRepository {
    func fetchProfile(userId: String) async throws -> UserProfile
    func saveProfile(_ profile: UserProfile) async throws
}

/// Stand-in used for previews and until Firebase is connected.
@MainActor
final class MockProfileRepository: ProfileRepository {
    private var stored: UserProfile

    init(profile: UserProfile) {
        self.stored = profile
    }

    func fetchProfile(userId: String) async throws -> UserProfile {
        stored
    }

    func saveProfile(_ profile: UserProfile) async throws {
        stored = profile
    }
}
