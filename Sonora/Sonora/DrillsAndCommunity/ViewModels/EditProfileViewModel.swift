//
//  EditProfileViewModel.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/13/26.
//

//  ViewModel for the Edit Profile screen.

import Foundation
import Combine

@MainActor
final class EditProfileViewModel: ObservableObject {

    // MARK: - Editable fields
    @Published var fullName: String
    @Published var email: String
    @Published var phoneNumber: String
    @Published var bio: String

    // MARK: - State
    @Published private(set) var isSaving = false
    @Published private(set) var didSave = false
    @Published private(set) var errorMessage: String?

    /// Visual only for now (no photo picker yet).
    var onChangePhoto: () -> Void = {}

    private let original: UserProfile
    private let repository: any ProfileRepository
    private let onSaved: (UserProfile) -> Void

    init(
        profile: UserProfile,
        repository: any ProfileRepository,
        onSaved: @escaping (UserProfile) -> Void = { _ in }
    ) {
        self.original = profile
        self.repository = repository
        self.onSaved = onSaved
        self.fullName = profile.fullName
        self.email = profile.email
        self.phoneNumber = profile.phoneNumber
        self.bio = profile.bio
    }

    // MARK: - Display
    var initials: String { original.initials }

    // MARK: - Validation
    var hasChanges: Bool {
        fullName != original.fullName
            || email != original.email
            || phoneNumber != original.phoneNumber
            || bio != original.bio
    }

    var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty && email.contains("@")
    }

    var canSave: Bool { isValid && hasChanges && !isSaving }

    // MARK: - Actions
    func changePhotoTapped() { onChangePhoto() }

    func save() async {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil

        var updated = original
        updated.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await repository.saveProfile(updated)
            onSaved(updated)
            didSave = true
        } catch {
            errorMessage = "Couldn't save your profile. Please try again."
        }
        isSaving = false
    }
}
