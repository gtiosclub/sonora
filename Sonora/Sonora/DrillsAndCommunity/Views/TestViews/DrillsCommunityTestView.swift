//
//  TestView.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 10/11/26.
//

import SwiftUI


struct DrillsCommunityTestView: View {

    @State private var skillProfile: SkillProfile?
    @State private var isLoadingProfile = false
    @State private var profileError: String?

    /// Test account whose SkillProfile the "Load skill profile" button fetches.
    private let testProfileUserId = "0EGGJvUjGsQwYAa77CFXx47Dnpy2"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DrillTopBar(title: "Drills & Community")

                DrillBanner(
                    mood: .wave,
                    title: "Test lab",
                    message: "Try out the drills and community features before they're wired into the app."
                )

                section("Drills") {
                    TestLinkRow(title: "Interview drills", subtitle: "Pick an interview, get a drill", icon: Session.Mode.interview.icon) {
                        DrillListView(mode: .interview)
                    }
                    TestLinkRow(title: "Presentation drills", subtitle: "Pick a presentation, get a drill", icon: Session.Mode.speech.icon) {
                        DrillListView(mode: .speech)
                    }
                    TestLinkRow(title: "Debate drills", subtitle: "Pick a debate, get a drill", icon: Session.Mode.debate.icon) {
                        DrillListView(mode: .debate)
                    }
                }

                section("XP") {
                    TestLinkRow(title: "XP test", subtitle: "Earn and check XP", icon: "bolt.fill") {
                        XPTestView()
                    }
                    TestLinkRow(title: "Leaderboard", subtitle: "Weekly and all-time XP rankings", icon: "trophy") {
                        LeaderboardView()
                    }
                }

                section("Skill profile") {
                    skillProfileCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(HomeColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            DrillSectionHeader(title)
            content()
        }
    }

    private var skillProfileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                Task { await loadSkillProfile() }
            } label: {
                if isLoadingProfile {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Loading…")
                    }
                } else {
                    Label(skillProfile == nil ? "Load test skill profile" : "Reload skill profile", systemImage: "arrow.down.circle")
                }
            }
            .buttonStyle(DrillPrimaryButtonStyle())
            .disabled(isLoadingProfile)

            if let profileError {
                Label(profileError, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: 0xB07A1A))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HomeColor.yellow.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
            }

            profileLine("Profile ID", skillProfile?.id)
            profileLine("Clarity", skillProfile?.clarity.summary)
            profileLine("Content", skillProfile?.content.summary)
            profileLine("Confidence", skillProfile?.confidence.summary)
            profileLine("Engaging", skillProfile?.engaging.summary)
        }
        .drillCard()
    }

    private func profileLine(_ label: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(HomeColor.purple)
            Text(value ?? "No data")
                .font(.system(size: 14))
                .foregroundStyle(value == nil ? HomeColor.inactive : HomeColor.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func loadSkillProfile() async {
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        do {
            skillProfile = try await SkillProfileService.fetch(for: testProfileUserId)
            profileError = nil
        } catch {
            print("Error found: \(String(reflecting: error))")
            profileError = Self.describe(error)
        }
    }

    /// Short, readable version of a load error (decoding errors name the missing field).
    private static func describe(_ error: Error) -> String {
        if case let DecodingError.keyNotFound(key, context) = error {
            let path = (context.codingPath.map(\.stringValue) + [key.stringValue]).joined(separator: ".")
            return "Couldn't read this profile: it's missing \"\(path)\". It may be in an older format."
        }
        return "Couldn't load the profile: \(error.localizedDescription)"
    }
}

/// White card row that opens a test screen: icon, title, subtitle, chevron.
private struct TestLinkRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HomeColor.purple)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xEDEBF8), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(HomeColor.purple)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(HomeColor.inactive)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(HomeColor.text)
            }
            .drillCard()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        DrillsCommunityTestView()
    }
    .environment(AuthManager())
}
