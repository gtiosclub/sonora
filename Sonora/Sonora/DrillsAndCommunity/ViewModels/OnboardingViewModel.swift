//
//  OnboardingViewModel.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/22/26.
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth

/// Phone numbers are stored (and searched) as digits with an optional leading "+",
/// so "(404) 555-1234" and "404-555-1234" are the same number.
enum PhoneNumberFormatter {
    static func normalize(_ raw: String) -> String {
        raw.filter { $0.isNumber || $0 == "+" }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var username = ""
    @Published var displayName = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    /// True when nobody is signed in yet, so we create the account here.
    /// False when they already signed in (Google/Apple/etc.) and only need a profile.
    @Published private(set) var needsPassword: Bool
    @Published private(set) var emailLocked: Bool
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?

    /// Called after the profile is saved. The host decides where to go next.
    var onComplete: () -> Void = {}

    private let service: OnboardingService

    init(service: OnboardingService = OnboardingService()) {
        self.service = service

        // FirebaseApp.app() is nil in Xcode previews, where Auth would crash.
        let user = FirebaseApp.app() == nil ? nil : Auth.auth().currentUser
        needsPassword = (user == nil)
        email = user?.email ?? ""
        emailLocked = !(user?.email ?? "").isEmpty
        displayName = user?.displayName ?? ""
    }

    // MARK: - Cleaned values

    var normalizedUsername: String {
        var name = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if name.hasPrefix("@") { name.removeFirst() }
        return name
    }

    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedName: String { displayName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var normalizedPhone: String { PhoneNumberFormatter.normalize(phone) }

    // MARK: - Validation messages (nil = fine or not typed yet)

    var usernameError: String? {
        guard !username.isEmpty else { return nil }
        let valid = normalizedUsername.range(of: "^[a-z0-9_]{3,20}$", options: .regularExpression) != nil
        return valid ? nil : "3–20 characters: letters, numbers, or underscores."
    }

    var emailError: String? {
        guard !email.isEmpty else { return nil }
        let valid = trimmedEmail.range(of: "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", options: .regularExpression) != nil
        return valid ? nil : "Enter a valid email address."
    }

    var phoneError: String? {
        guard !phone.isEmpty else { return nil }   // optional
        let digits = normalizedPhone.filter(\.isNumber).count
        return (7...15).contains(digits) ? nil : "Enter a valid phone number, or leave it blank."
    }

    var passwordError: String? {
        guard needsPassword, !password.isEmpty else { return nil }
        return password.count >= 8 ? nil : "At least 8 characters."
    }

    var confirmError: String? {
        guard needsPassword, !confirmPassword.isEmpty else { return nil }
        return confirmPassword == password ? nil : "Passwords don't match."
    }

    var canSubmit: Bool {
        let basics = !normalizedUsername.isEmpty && usernameError == nil
            && !trimmedName.isEmpty
            && !trimmedEmail.isEmpty && emailError == nil
            && phoneError == nil
        let passwordsOK = !needsPassword
            || (password.count >= 8 && password == confirmPassword)
        return basics && passwordsOK && !isSubmitting
    }

    // MARK: - Submit

    func submit() async {
        guard canSubmit else { return }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let uid: String
            if let existing = service.currentUserId {
                uid = existing
            } else {
                uid = try await service.createAuthUser(email: trimmedEmail, password: password)
                // From here on we're signed in; a retry (e.g. after "username taken")
                // won't try to create the account again.
                needsPassword = false
            }

            try await service.saveProfile(
                uid: uid,
                username: normalizedUsername,
                displayName: trimmedName,
                email: trimmedEmail,
                phone: normalizedPhone.isEmpty ? nil : normalizedPhone
            )
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
