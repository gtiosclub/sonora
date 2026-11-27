//
//  FriendSearchTestView.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 10/26/26.
//
import SwiftUI

struct FriendSearchTestView: View {
    @Environment(AuthManager.self) private var auth
    @State private var query = ""
    @State private var results: [User] = []
    @State private var statusMessage = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("Friend Search Testing")
                .font(.title2.bold())
            Text("Search by username (start of it) or full email")
                .font(.footnote)
                .foregroundStyle(.secondary)

            TextField("Username or email", text: $query)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(runSearch)

            Button("Search", action: runSearch)
                .buttonStyle(.borderedProminent)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            List(results) { user in
                VStack(alignment: .leading) {
                    Text(user.username).font(.headline)
                    Text(user.email).font(.subheadline).foregroundStyle(.secondary)
                    Text(user.userId).font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .listStyle(.plain)
        }
        .padding()
    }

    private func runSearch() {
        Task {
            do {
                results = try await FriendSearchService.search(query, excluding: auth.userID)
                statusMessage = results.isEmpty ? "No users found" : "✅ Found \(results.count) user(s)"
            } catch {
                results = []
                statusMessage = "❌ Error: \(error.localizedDescription)"
                print("FriendSearchService error: \(error)")
            }
        }
    }
}
