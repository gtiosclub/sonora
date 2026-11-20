//
//  PreferenceProfileTestView.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 10/15/26.
//
import SwiftUI

struct PreferenceProfileTestView: View {
    @Environment(AuthManager.self) private var auth
    @State private var statusMessage = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("PreferenceProfile Testing")
                .font(.title2.bold())
            Text("Tap a button to test PreferenceProfileService")

            Button("Add Test PreferenceProfile") {
                run("Added") { userId in
                    try await PreferenceProfileService.add(.sample(userId: userId), for: userId)
                    return "PreferenceProfile added"
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Button("Get PreferenceProfile") {
                run("Fetched") { userId in
                    guard let profile = try await PreferenceProfileService.fetch(for: userId) else {
                        return "No PreferenceProfile found"
                    }
                    print(profile)
                    return """
                    Length: \(profile.practiceLength.rawValue), difficulty: \(profile.difficulty.rawValue), feedback: \(profile.feedbackStyle.rawValue)
                    Good topics: \(profile.goodTopics)
                    Bad topics: \(profile.badTopics)
                    Modes: \(profile.modes.map(\.rawValue))
                    """
                }
            }
            .buttonStyle(.bordered)

            Button("Update PreferenceProfile") {
                run("Updated") { userId in
                    var profile = try await PreferenceProfileService.fetch(for: userId) ?? .sample(userId: userId)
                    // Toggle history so each tap visibly changes the doc
                    if let index = profile.goodTopics.firstIndex(of: .history) {
                        profile.goodTopics.remove(at: index)
                    } else {
                        profile.goodTopics.append(.history)
                    }
                    try await PreferenceProfileService.update(profile, for: userId)
                    return "PreferenceProfile updated — good topics: \(profile.goodTopics)"
                }
            }
            .buttonStyle(.bordered)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private func run(_ label: String, _ action: @escaping (String) async throws -> String) {
        guard let userId = auth.userID else {
            statusMessage = "Not logged in — sign in first."
            return
        }
        Task {
            do {
                statusMessage = "✅ " + (try await action(userId))
                print("\(label): \(statusMessage)")
            } catch {
                statusMessage = "❌ Error: \(error.localizedDescription)"
                print("PreferenceProfileService error: \(error)")
            }
        }
    }
}
