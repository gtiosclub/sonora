//
//  FriendshipTestView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/3/26.
//

//
//  FriendshipTestView.swift
//  Sonora
//

import SwiftUI
import FirebaseAuth

struct FriendshipTestView: View {
    private let service = FriendshipService()

    @State private var otherUserId = ""
    @State private var friendships: [Friendship] = []
    @State private var message = ""

    private var myId: String { Auth.auth().currentUser?.uid ?? "" }

    var body: some View {
        List {
            Section("Your UID") {
                Text(myId.isEmpty ? "Not signed in" : myId)
                    .font(.caption)
                    .textSelection(.enabled)
            }

            Section("Other user's UID") {
                TextField("Paste their UID", text: $otherUserId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Send request") {
                    run { try await service.sendRequest(to: otherUserId) }
                }
                .buttonStyle(.borderless)
                Button("Block user") {
                    run { try await service.block(userId: otherUserId) }
                }
                .buttonStyle(.borderless)
            }

            Section("Your friendships") {
                ForEach(friendships) { friendship in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(friendship.status.rawValue) with \(friendship.otherUserId(for: myId) ?? "?")")
                            .font(.caption)
                        HStack(spacing: 16) {
                            if let id = friendship.id {
                                if friendship.isIncomingRequest(for: myId) {
                                    Button("Accept") {
                                        run { try await service.acceptRequest(friendshipId: id) }
                                    }
                                    .buttonStyle(.borderless)
                                }
                                Button("Delete", role: .destructive) {
                                    run { try await service.delete(friendshipId: id) }
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                Button("Refresh") { Task { await refresh() } }
                    .buttonStyle(.borderless)
            }

            if !message.isEmpty {
                Section("Result") { Text(message) }
            }
        }
        .task { await refresh() }
    }

    private func run(_ action: @escaping () async throws -> Void) {
        Task {
            do {
                try await action()
                message = "Success ✅"
            } catch {
                message = "Error: \(error.localizedDescription)"
            }
            await refresh()
        }
    }

    private func refresh() async {
        do {
            friendships = try await service.fetchMyFriendships()
        } catch {
            message = "Error: \(error.localizedDescription)"
        }
    }
}
