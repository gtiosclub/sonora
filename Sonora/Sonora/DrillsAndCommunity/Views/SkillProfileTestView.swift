//
//  SkillProfileTestView.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 10/1/26.
//
import SwiftUI

struct SkillProfileTestView: View {
    @Environment(AuthManager.self) private var auth
    @State private var statusMessage = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("SkillProfile Testing")
                .font(.title2.bold())
            Text("Tap a button to test SkillProfileService")

            Button("Add Test SkillProfile") {
                run("Added") { userId in
                    try await SkillProfileService.add(.sample(userId: userId), for: userId)
                    return "SkillProfile added"
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Button("Get SkillProfile") {
                run("Fetched") { userId in
                    guard let profile = try await SkillProfileService.fetch(for: userId) else {
                        return "No SkillProfile found"
                    }
                    print(profile)
                    return "Content: \(profile.content.summary)"
                }
            }
            .buttonStyle(.bordered)

            Button("Update SkillProfile") {
                run("Updated") { userId in
                    var profile = try await SkillProfileService.fetch(for: userId) ?? .sample(userId: userId)
                    profile.content.summary = "Updated at \(Date().formatted(date: .omitted, time: .standard))"
                    try await SkillProfileService.update(profile, for: userId)
                    return "SkillProfile updated"
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
                print("SkillProfileService error: \(error)")
            }
        }
    }
}
