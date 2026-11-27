//
//  AddFriendViewModel.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/6/26.
//

import Foundation
import Combine
import FirebaseAuth

enum UserSearchMode: String, CaseIterable, Identifiable {
    case username = "Username"
    case phone = "Phone number"

    var id: String { rawValue }
}

@MainActor
final class AddFriendViewModel: ObservableObject {
    @Published var mode: UserSearchMode = .username
    @Published var query = ""
    @Published private(set) var result: FoundUser?
    @Published private(set) var isLoading = false
    @Published private(set) var requestSent = false
    @Published private(set) var message: String?

    private let userSearch: UserSearchService
    private let friendships: FriendshipService

    init(userSearch: UserSearchService = UserSearchService(),
         friendships: FriendshipService = FriendshipService()) {
        self.userSearch = userSearch
        self.friendships = friendships
    }

    var canSearch: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    /// Clears the previous search (called when switching username/phone).
    func reset() {
        query = ""
        result = nil
        requestSent = false
        message = nil
    }

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        result = nil
        requestSent = false
        message = nil
        defer { isLoading = false }

        do {
            let found: FoundUser?
            switch mode {
            case .username: found = try await userSearch.findUser(username: trimmed)
            case .phone:    found = try await userSearch.findUser(phone: trimmed)
            }

            guard let found else {
                message = "No user found."
                return
            }
            if found.id == Auth.auth().currentUser?.uid {
                message = "That's you!"
                return
            }
            result = found
        } catch {
            message = error.localizedDescription
        }
    }

    func sendRequest() async {
        guard let user = result else { return }

        isLoading = true
        message = nil
        defer { isLoading = false }

        do {
            try await friendships.sendRequest(to: user.id)
            requestSent = true
        } catch {
            message = error.localizedDescription
        }
    }
}
