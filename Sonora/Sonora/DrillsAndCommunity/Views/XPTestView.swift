//
//  XPTestView.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 11/5/26.
//
import SwiftUI

struct XPTestView: View {
    @Environment(AuthManager.self) private var auth
    @State private var drillImprovement = 0
    @State private var totalXP: Int?
    @State private var lastSessionID: String?
    @State private var statusMessage = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("XP Testing")
                .font(.title2.bold())

            if let totalXP {
                let level = XPService.level(for: totalXP)
                Text("Total XP: \(totalXP)")
                    .font(.headline)
                Text("Tier \(level.tier) · Level \(level.level) · \(level.xpIntoLevel)/\(level.xpForLevel) XP")
                    .foregroundStyle(.secondary)
            }

            Stepper("Drill improvement: \(drillImprovement)", value: $drillImprovement, in: -50...50, step: 5)

            Button("Award Drill XP (\(XPService.drillXP(improvement: drillImprovement)))") {
                run { userId in
                    let xp = XPService.drillXP(improvement: drillImprovement)
                    try await XPService.awardXP(xp, to: userId)
                    return "Drill: +\(xp) XP"
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Award Session XP (sample scores vs your SkillProfile)") {
                run { userId in
                    guard let scores = DebateSessions.debateSession1.sessionSkillScore else {
                        return "Sample session has no scores"
                    }
                    // Older SkillProfile docs have no scores and won't decode; fall back to sign-up defaults (50s)
                    let saved = try? await SkillProfileService.fetch(for: userId)
                    let profile = saved ?? SkillProfile.makeNew(userId: userId)
                    let xp = XPService.sessionXP(scores: scores, previous: profile)
                    try await XPService.awardXP(xp, to: userId)
                    return "Session: +\(xp) XP" + (saved == nil ? " (used default SkillProfile scores)" : "")
                }
            }
            .buttonStyle(.bordered)
            
            Button("Test: +1 drill and check badges") {
                run { userId in
                    try await UserProgressService.record(userId: userId, drills: 1, xp: 0)
                    try await AchievementService.evaluate(userId: userId, sourceId: "test")
                    return "Drill counted, badges checked"
                }
            }
            .buttonStyle(.bordered)
            
            Button("Test: new session, count it, check badges") {
                run { userId in
                    guard let scores = DebateSessions.debateSession1.sessionSkillScore else {
                        return "Sample session has no scores"
                    }
                    // A real Sessions document, so the double-count guard has something to write to
                    let session = try await createAISession(userId: userId, mode: .interview)
                    lastSessionID = session.id
                    try await UserProgressService.recordSessionCompletion(
                        sessionID: session.id, userId: userId, scores: scores)
                    // Run the check again directly so a failure shows up here as an error
                    // (inside recordSessionCompletion it is only printed to the console).
                    try await AchievementService.evaluate(userId: userId, sourceId: session.id)
                    let p = try await UserProgressService.fetch(for: userId)
                    let earned = try await AchievementService.fetchEarned(userId: userId)
                        .map(\.achievementId).sorted()
                    return "Session counted. Total sessions: \(p.completedSessions). Badges in Firebase: \(earned.joined(separator: ", "))"
                }
            }
            .buttonStyle(.bordered)

            Button("Test: re-count the SAME session (should do nothing)") {
                run { userId in
                    guard let id = lastSessionID,
                          let scores = DebateSessions.debateSession1.sessionSkillScore else {
                        return "Tap the new-session button first"
                    }
                    try await UserProgressService.recordSessionCompletion(
                        sessionID: id, userId: userId, scores: scores)
                    let p = try await UserProgressService.fetch(for: userId)
                    return "Re-counted \(id). Total sessions: \(p.completedSessions) (should be unchanged)"
                }
            }
            .buttonStyle(.bordered)

            Button("Refresh XP") {
                run { _ in "Refreshed" }
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
        .task { run { _ in "" } }
    }

    // Runs the action, then reloads the user's total XP
    private func run(_ action: @escaping (String) async throws -> String) {
        guard let userId = auth.userID else {
            statusMessage = "Not logged in — sign in first."
            return
        }
        Task {
            do {
                let message = try await action(userId)
                totalXP = try await XPService.fetchXP(for: userId)
                statusMessage = message.isEmpty ? "" : "✅ " + message
            } catch {
                statusMessage = "❌ Error: \(error.localizedDescription)"
                print("XPService error: \(error)")
            }
        }
    }
}
