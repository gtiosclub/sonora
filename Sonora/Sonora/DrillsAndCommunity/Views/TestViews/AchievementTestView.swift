//
//  AchievementTestView.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 11/16/26.
//

import SwiftUI

struct AchievementTestView: View {
    @Environment(AuthManager.self) private var auth
    @State private var badge: EarnedAchievement?
    @State private var streak: Int?
    @State private var streakInput = ""
    @State private var status = ""

    var body: some View {
        List {
            Section("Current streak badge") {
                if let badge, let definition = StreakAchievementService.streakAchievement(for: badge) {
                    Text("\(definition.artworkName) \(definition.name)")
                        .font(.title2.bold())
                    Text("Earned \(badge.earnedAt.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                } else {
                    Text("No streak badge")
                        .foregroundStyle(.secondary)
                }
                Text("Streak: \(streak.map(String.init) ?? "–") days")
            }

            Section("Set streak (saves to Firebase)") {
                TextField("New streak", text: $streakInput)
                    .keyboardType(.numberPad)
                Button("Update Streak") { Task { await updateStreak() } }
            }

            if !status.isEmpty {
                Section { Text(status) }
            }
        }
        .navigationTitle("Streak Badge Test")
        .task { await load() }
    }

    private func load() async {
        guard let uid = auth.userID else { status = "Not signed in"; return }
        do {
            streak = try await UserService.getStreak(userID: uid)
            badge = try await StreakAchievementService.fetchStreakAchievement(userId: uid)
        } catch {
            status = "❌ Load failed: \(error.localizedDescription)"
        }
    }

    private func updateStreak() async {
        guard let uid = auth.userID else { status = "Not signed in"; return }
        guard let newStreak = Int(streakInput) else { status = "Enter a whole number"; return }
        do {
            // updateStreak also syncs the streak badge
            try await UserService.updateStreak(userID: uid, streak: newStreak)
            await load()
            status = "✅ Streak set to \(newStreak)"
        } catch {
            status = "❌ Update failed: \(error.localizedDescription)"
        }
    }
}
