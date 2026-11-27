//
//  ChangePasswordView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/14/26.
//

import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class ChangePasswordViewModel: ObservableObject {
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var didSucceed = false

    var hasMinLength: Bool { newPassword.count >= 8 }
    var hasNumber: Bool { newPassword.contains(where: \.isNumber) }
    var hasSpecial: Bool { newPassword.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace } }
    var passwordsMatch: Bool { !confirmPassword.isEmpty && newPassword == confirmPassword }
    var canSubmit: Bool { hasMinLength && hasNumber && hasSpecial && passwordsMatch && !isSaving }

    func submit() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "You're not signed in."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await user.updatePassword(to: newPassword)
            errorMessage = nil
            didSucceed = true
        } catch let error as NSError {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                // TODO: present a re-authentication step (current password) and retry.
                errorMessage = "For security, please sign in again and then retry."
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct ChangePasswordView: View {
    @StateObject private var viewModel = ChangePasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showNew = false
    @State private var showConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SonoraTopBar(title: "Password") {
                    BackButton()
                } trailing: {
                    Color.clear.frame(width: 44, height: 44)
                }

                card
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .fontDesign(.rounded)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .alert("Password updated", isPresented: $viewModel.didSucceed) {
            Button("OK") { dismiss() }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Change Password")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(ProfilePalette.deepPlum)
                    Text("Your new password must be different from the ones you used before.")
                        .font(.caption)
                        .foregroundStyle(ProfilePalette.secondaryText)
                }
                Spacer(minLength: 8)
                Image("Tuxely")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .accessibilityHidden(true)
            }

            passwordField("New password*", text: $viewModel.newPassword, reveal: $showNew)

            VStack(alignment: .leading, spacing: 8) {
                requirement("At least 8 characters", met: viewModel.hasMinLength)
                requirement("One number", met: viewModel.hasNumber)
                requirement("One special character", met: viewModel.hasSpecial)
            }

            passwordField("Confirm password*", text: $viewModel.confirmPassword, reveal: $showConfirm)

            if !viewModel.confirmPassword.isEmpty && !viewModel.passwordsMatch {
                Text("Passwords don't match").font(.caption).foregroundStyle(.red)
            }
            if let error = viewModel.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
            }

            Button {
                Task { await viewModel.submit() }
            } label: {
                Group {
                    if viewModel.isSaving { ProgressView().tint(.white) }
                    else { Text("Update Password") }
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(ProfilePalette.calmGreen))
            }
            .disabled(!viewModel.canSubmit)
            .opacity(viewModel.canSubmit ? 1 : 0.5)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(ProfilePalette.softBeige))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .strokeBorder(ProfilePalette.lavender, lineWidth: 1))
    }

    private func passwordField(_ label: String, text: Binding<String>, reveal: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote.weight(.semibold)).foregroundStyle(ProfilePalette.primaryText)
            HStack {
                Group {
                    if reveal.wrappedValue { TextField("", text: text) }
                    else { SecureField("", text: text) }
                }
                .textContentType(.newPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button { reveal.wrappedValue.toggle() } label: {
                    Image(systemName: reveal.wrappedValue ? "eye" : "eye.slash")
                        .foregroundStyle(ProfilePalette.secondaryText)
                }
                .accessibilityLabel(reveal.wrappedValue ? "Hide password" : "Show password")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(ProfilePalette.deepPlum.opacity(0.35), lineWidth: 1))
        }
    }

    private func requirement(_ text: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(met ? ProfilePalette.calmGreen : Color.red.opacity(0.8))
            Text(text).font(.caption)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(met ? "met" : "not met")
    }
}

#Preview {
    NavigationStack { ChangePasswordView() }
}
