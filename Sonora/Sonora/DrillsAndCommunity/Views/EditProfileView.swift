//
//  EditProfileView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/15/26.
//
//  VIEW: layout only. Reached from the pencil on Profile AND from Settings > Edit Profile.

import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss

    private let pronounOptions = ["She/Her", "He/Him", "They/Them"]

    init(viewModel: EditProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SonoraTopBar(title: "Edit Profile") {
                    BackButton(systemImage: "xmark")
                } trailing: {
                    Button { saveTapped() } label: {
                        Image(systemName: "checkmark")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(RoundedRectangle(cornerRadius: 10).fill(ProfilePalette.calmGreen))
                    }
                    .disabled(!viewModel.canSave)
                    .opacity(viewModel.canSave ? 1 : 0.4)
                    .accessibilityLabel("Save changes")
                }

                avatar

                LabeledField(label: "Displayed Name:") {
                    TextField("Full name", text: $viewModel.fullName)
                        .textContentType(.name)
                }

                pronounPicker

                LabeledField(label: "Email:") {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                LabeledField(label: "Phone Number") {
                    TextField("Phone number", text: $viewModel.phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                LabeledField(label: "Bio") {
                    TextField("Tell people about yourself", text: $viewModel.bio, axis: .vertical)
                        .lineLimit(4...8)
                }

                if let error = viewModel.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .fontDesign(.rounded)
        .foregroundStyle(ProfilePalette.primaryText)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func saveTapped() {
        Task {
            await viewModel.save()
            if viewModel.didSave { dismiss() }
        }
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            ProfileAvatar(initials: viewModel.initials)
            Button { viewModel.changePhotoTapped() } label: {
                Image(systemName: "pencil")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(ProfilePalette.deepPlum)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(ProfilePalette.softBeige))
                    .overlay(Circle().strokeBorder(ProfilePalette.deepPlum.opacity(0.4), lineWidth: 1))
            }
            .accessibilityLabel("Change photo")
            .offset(x: -6, y: -6)
        }
    }

    private var pronounPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pronouns:")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ProfilePalette.deepPlum)
            HStack {
                ForEach(pronounOptions, id: \.self) { option in
                    Button { viewModel.pronouns = option } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.pronouns == option
                                  ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(ProfilePalette.deepPlum)
                            Text(option).font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(viewModel.pronouns == option ? .isSelected : [])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    EditProfileView(
        viewModel: EditProfileViewModel(
            profile: exampleUserProfile,
            repository: MockProfileRepository(profile: exampleUserProfile)
        )
    )
}
