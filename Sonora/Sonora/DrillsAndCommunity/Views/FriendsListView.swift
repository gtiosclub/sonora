//
//  FriendsListView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/14/26.
//

import SwiftUI
import Combine

@MainActor
final class FriendsListViewModel: ObservableObject {
    @Published var friends: [FriendSummary] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: FriendshipServicing

    init(service: FriendshipServicing) { self.service = service }

    var filtered: [FriendSummary] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return friends }
        return friends.filter {
            $0.displayName.lowercased().contains(q) || $0.username.lowercased().contains(q)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            friends = try await service.friends().sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct FriendsListView: View {
    @StateObject private var viewModel: FriendsListViewModel
    private let service: FriendshipServicing
    @State private var showAddFriend = false

    init(viewModel: FriendsListViewModel, service: FriendshipServicing) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.service = service
    }

    var body: some View {
        VStack(spacing: 14) {
            SonoraTopBar(title: "Friends") {
                BackButton()
            } trailing: {
                IconSquareButton(systemImage: "person.badge.plus", label: "Add friends") {
                    showAddFriend = true
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(ProfilePalette.secondaryText)
                TextField("Search friends", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(ProfilePalette.deepPlum.opacity(0.35), lineWidth: 1))

            if let error = viewModel.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
            }

            if viewModel.filtered.isEmpty && !viewModel.isLoading {
                Spacer()
                Image(systemName: "person.2").font(.largeTitle).foregroundStyle(ProfilePalette.lavender)
                Text(viewModel.friends.isEmpty ? "No friends yet. Tap + to find some!" : "No matches")
                    .font(.subheadline)
                    .foregroundStyle(ProfilePalette.secondaryText)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filtered) { friend in
                            NavigationLink {
                                OtherUserProfileView(viewModel: OtherUserProfileViewModel(
                                    userId: friend.id, service: service))
                            } label: {
                                HStack(spacing: 12) {
                                    SmallAvatar(initials: friend.initials)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(friend.displayName).font(.subheadline.weight(.bold))
                                        Text("@\(friend.username)").font(.caption)
                                            .foregroundStyle(ProfilePalette.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.footnote)
                                        .foregroundStyle(ProfilePalette.secondaryText)
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(ProfilePalette.lavender, lineWidth: 1))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .refreshable { await viewModel.load() }
            }
        }
        .padding(.horizontal, 16)
        .fontDesign(.rounded)
        .foregroundStyle(ProfilePalette.primaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddFriend, onDismiss: { Task { await viewModel.load() } }) {
            AddFriendView(viewModel: AddFriendViewModel())
        }
        .task { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        FriendsListView(viewModel: FriendsListViewModel(service: MockFriendshipService()),
                        service: MockFriendshipService())
    }
}
