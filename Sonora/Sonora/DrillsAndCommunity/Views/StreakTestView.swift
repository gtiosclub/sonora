//
//  StreakTestView.swift
//  Sonora
//
//  Created by Kosei Tsukamoto on 10/8/26.
//

import SwiftUI

struct StreakTestView: View {
    @Environment(AuthManager.self) private var auth
    @State private var status = "Not loaded"
    @State private var streakInput = ""

    var body: some View {
        List {
            Section("Result") {
                Text(status)
            }

            Section("Get Streak") {
                Button("Test Get Streak") { Task { await getStreak() } }
            }

            Section("Update Streak") {
                TextField("New streak", text: $streakInput)
                    .keyboardType(.numberPad)
                Button("Test Update Streak") { Task { await updateStreak() } }
            }
        }
        .navigationTitle("Streak Test")
    }

    private func getStreak() async {
        guard let uid = auth.userID else { status = "Not signed in"; return }
        do {
            if let streak = try await UserService.getStreak(userID: uid) {
                status = "Streak: \(streak)"
            } else {
                status = "No user doc for \(uid)"
            }
        } catch {
            status = "Get failed: \(error.localizedDescription)"
        }
    }

    private func updateStreak() async {
        guard let uid = auth.userID else { status = "Not signed in"; return }
        guard let newStreak = Int(streakInput) else { status = "Enter a whole number"; return }
        do {
            try await UserService.updateStreak(userID: uid, streak: newStreak)
            await getStreak() // read back to confirm the write
        } catch {
            status = "Update failed: \(error.localizedDescription)"
        }
    }
}
