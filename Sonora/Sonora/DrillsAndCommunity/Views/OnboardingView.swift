//
//  OnboardingView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/22/26.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @FocusState private var focused: Field?

    private enum Field { case username, displayName, email, phone, password, confirm }

    init(viewModel: OnboardingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                TuxelyWaveView()
                    .frame(width: 200, height: 200)
                    .padding(.top, 12)

                VStack(spacing: 6) {
                    Text("Welcome to Sonora")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(ProfilePalette.deepPlum)
                        .multilineTextAlignment(.center)
                    Text("Practice the conversations that matter.\n Let's set up your profile.")
                        .font(.subheadline)
                        .foregroundStyle(ProfilePalette.secondaryText)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    field("USERNAME",
                          hint: viewModel.usernameError ?? "This is how friends will find you.",
                          hintIsError: viewModel.usernameError != nil) {
                        HStack(spacing: 2) {
                            Text("@").foregroundStyle(ProfilePalette.secondaryText)
                            TextField("username", text: $viewModel.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.username)
                                .focused($focused, equals: .username)
                                .submitLabel(.next)
                                .onSubmit { focused = .displayName }
                        }
                    }

                    field("DISPLAY NAME") {
                        TextField("Your name", text: $viewModel.displayName)
                            .textContentType(.name)
                            .focused($focused, equals: .displayName)
                            .submitLabel(.next)
                            .onSubmit { focused = .email }
                    }

                    field("EMAIL",
                          hint: viewModel.emailError,
                          hintIsError: true) {
                        TextField("you@example.com", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .disabled(viewModel.emailLocked)
                            .opacity(viewModel.emailLocked ? 0.6 : 1)
                            .focused($focused, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focused = .phone }
                    }

                    field("PHONE NUMBER (OPTIONAL)",
                          hint: viewModel.phoneError ?? "Lets friends find you by phone.",
                          hintIsError: viewModel.phoneError != nil) {
                        TextField("(555) 555-5555", text: $viewModel.phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .focused($focused, equals: .phone)
                    }

                    if viewModel.needsPassword {
                        field("PASSWORD",
                              hint: viewModel.passwordError ?? "At least 8 characters.",
                              hintIsError: viewModel.passwordError != nil) {
                            SecureField("Password", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .focused($focused, equals: .password)
                                .submitLabel(.next)
                                .onSubmit { focused = .confirm }
                        }

                        field("CONFIRM PASSWORD",
                              hint: viewModel.confirmError,
                              hintIsError: true) {
                            SecureField("Confirm password", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .focused($focused, equals: .confirm)
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    focused = nil
                    Task { await viewModel.submit() }
                } label: {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create account").font(.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 14).fill(ProfilePalette.calmGreen))
                }
                .disabled(!viewModel.canSubmit)
                .opacity(viewModel.canSubmit ? 1 : 0.5)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .fontDesign(.rounded)
        .foregroundStyle(ProfilePalette.primaryText)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
    }

    // MARK: - Pieces

    private func field<Content: View>(_ label: String,
                                      hint: String? = nil,
                                      hintIsError: Bool = false,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ProfilePalette.secondaryText)

            content()
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(ProfilePalette.lavender, lineWidth: 1.5))

            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(hintIsError ? Color.red : ProfilePalette.secondaryText)
            }
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel())
}
