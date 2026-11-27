//
//  AddFriendView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/6/26.
//

import SwiftUI

struct AddFriendView: View {
    @StateObject private var viewModel: AddFriendViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddFriendViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("Search by", selection: $viewModel.mode) {
                        ForEach(UserSearchMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    searchField

                    Button {
                        Task { await viewModel.search() }
                    } label: {
                        Text("Search")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(ProfilePalette.deepPlum))
                    }
                    .disabled(!viewModel.canSearch)
                    .opacity(viewModel.canSearch ? 1 : 0.5)

                    if viewModel.isLoading {
                        ProgressView()
                    }

                    if let user = viewModel.result {
                        resultCard(user)
                    }

                    if let message = viewModel.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(16)
            }
            .fontDesign(.rounded)
            .foregroundStyle(ProfilePalette.primaryText)
            .background(ProfilePalette.softBeige.ignoresSafeArea())
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(ProfilePalette.deepPlum)
                }
            }
            .onChange(of: viewModel.mode) { _, _ in viewModel.reset() }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Pieces

    private var searchField: some View {
        TextField(viewModel.mode == .email ? "Email address" : "@username",
                  text: $viewModel.query)
            .keyboardType(viewModel.mode == .email ? .emailAddress : .default)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit { Task { await viewModel.search() } }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(ProfilePalette.lavender, lineWidth: 1.5))
    }

    private func resultCard(_ user: FoundUser) -> some View {
        HStack(spacing: 12) {
            Text(String(user.displayName.prefix(1)).uppercased())
                .font(.title3.weight(.bold))
                .foregroundStyle(ProfilePalette.deepPlum)
                .frame(width: 46, height: 46)
                .background(Circle().fill(ProfilePalette.lavender))

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName).font(.headline)
                if !user.username.isEmpty {
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundStyle(ProfilePalette.secondaryText)
                }
            }

            Spacer()

            if viewModel.requestSent {
                Label("Sent", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ProfilePalette.calmGreen)
            } else {
                Button {
                    Task { await viewModel.sendRequest() }
                } label: {
                    Text("Add")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(ProfilePalette.calmGreen))
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .strokeBorder(ProfilePalette.lavender, lineWidth: 1.5))
    }
}

#Preview {
    AddFriendView(viewModel: AddFriendViewModel())
}
