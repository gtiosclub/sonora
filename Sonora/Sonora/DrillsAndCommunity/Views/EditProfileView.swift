//
//  EditProfileView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/15/26.
//

//  VIEW: layout only. Pushed from ProfileView via "Edit Profile".

import SwiftUI
 
struct EditProfileView: View {
    @StateObject private var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss
 
    init(viewModel: EditProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
 
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScreenHeader(title: "Edit Profile", onBack: { dismiss() })
 
                avatar
 
                FormFieldContainer(label: "FULL NAME") {
                    TextField("Full name", text: $viewModel.fullName)
                        .textContentType(.name)
                }
 
                FormFieldContainer(label: "EMAIL") {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
 
                FormFieldContainer(label: "PHONE NUMBER") {
                    TextField("Phone number", text: $viewModel.phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
 
                FormFieldContainer(label: "BIO") {
                    TextField("Tell people about yourself", text: $viewModel.bio, axis: .vertical)
                        .lineLimit(4...8)
                }
 
                if let error = viewModel.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
 
                Button("SAVE") {
                    Task {
                        await viewModel.save()
                    }
                }
                .buttonStyle(ChunkyButtonStyle())
                .disabled(!viewModel.canSave)
                .opacity(viewModel.canSave ? 1 : 0.5)
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .fontDesign(.rounded)
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .navigationBar)
    }
 
    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            ProfileAvatar(initials: viewModel.initials)
            Button { viewModel.changePhotoTapped() } label: {
                Image(systemName: "pencil")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.profileAccent))
                    .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: 3))
            }
            .accessibilityLabel("Change photo")
            .offset(x: -10, y: -10)
        }
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
