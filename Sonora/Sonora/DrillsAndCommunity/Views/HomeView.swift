//
//  HomeView.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 11/12/26.
//

import SwiftUI

/// Colors from the home page Figma
enum HomeColor {
    static let background = Color(hex: 0xFCF6E3)
    static let purple = Color(hex: 0x4F4A7A)
    static let text = Color(hex: 0x1F1F24)
    static let olive = Color(hex: 0xA6B36A)
    static let lavender = Color(hex: 0xC7C5E3)
    static let yellow = Color(hex: 0xF8DFA2)
    static let border = Color(hex: 0xC9C9D3)
    static let track = Color(hex: 0xE8E8E8)
    static let inactive = Color(hex: 0x8E8FA3)
}

struct HomeView: View {
    @Environment(AuthManager.self) private var auth
    @State private var viewModel = HomeViewModel()
    @State private var showPairing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statPills
                practiceBanner
                section("Quick start") { quickStart }
                section("Recent session") { recentSession }
                section("Your progress") { progressCards }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(HomeColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: auth.userID) {
            if let userId = auth.userID { await viewModel.load(userId: userId) }
        }
        .fullScreenCover(isPresented: $showPairing) { PairingSetupView() }
    }

    // MARK: Header

    private var header: some View {
        let name = auth.currentUser?.username ?? "there"
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting),")
                    .font(.system(size: 18))
                    .foregroundStyle(HomeColor.text)
                Text(name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(HomeColor.purple)
            }
            Spacer()
            Text(name.prefix(1).uppercased())
                .font(.headline)
                .foregroundStyle(HomeColor.olive)
                .frame(width: 46, height: 46)
                .background(Color(hex: 0xE9F0DF), in: Circle())
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12: return "Good morning"
        case ..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var statPills: some View {
        let confidence = viewModel.skillProfile.map { "\($0.confidence.score)" } ?? "–"
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill("🔥 \(auth.currentUser?.streak ?? 0) day streak", HomeColor.yellow)
                pill("🌿 \(confidence) confidence", HomeColor.olive)
                pill("⚡ \(viewModel.progress?.completedSessions ?? 0) sessions", HomeColor.lavender)
            }
        }
    }

    private func pill(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(HomeColor.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color, in: Capsule())
    }

    // MARK: Banner

    private var practiceBanner: some View {
        Button { showPairing = true } label: {
            HStack(spacing: 16) {
                Tuxley(mood: .wave)
                    .frame(width: 80, height: 96)
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Interview Practice")
                        .font(.system(size: 18, weight: .bold))
                    Text("Focus on speaking and confidence")
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(0.7)
                }
                .foregroundStyle(HomeColor.purple)
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(HomeColor.lavender, in: RoundedRectangle(cornerRadius: 22))
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "arrow.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(HomeColor.olive, in: Circle())
                    .padding(14)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Sections

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(HomeColor.text)
            content()
        }
    }

    private var quickStart: some View {
        HStack(spacing: 12) {
            Button { showPairing = true } label: {
                quickStartCard("AI Opponent", icon: "circle.grid.3x3.fill", tint: Color(hex: 0x9BAE63), fill: Color(hex: 0xEFF1DE))
            }
            Button { showPairing = true } label: {
                quickStartCard("Live Pairing", icon: "person.2", tint: Color(hex: 0x5B5FC0), fill: Color(hex: 0xEEF2FC))
            }
            NavigationLink {
                SpeakingProgressView(viewModel: SpeakingProgressViewModel())
            } label: {
                quickStartCard("Deltas", icon: "chart.bar.fill", tint: Color(hex: 0x9A6BCB), fill: Color(hex: 0xF2EDF8))
            }
        }
        .buttonStyle(.plain)
    }

    private func quickStartCard(_ title: String, icon: String, tint: Color, fill: Color) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 36, height: 36)
                .background(.white, in: Circle())
            Text(title)
                .font(.system(size: 13))
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(fill, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HomeColor.border.opacity(0.5)))
    }

    @ViewBuilder
    private var recentSession: some View {
        if let session = viewModel.recentSession {
            HStack(spacing: 14) {
                Tuxley(mood: TuxleyMood(score: session.averageScore ?? 70))
                    .padding(6)
                    .frame(width: 44, height: 44)
                    .background(HomeColor.background, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(session.mode.homeTitle) · \(session.dayText)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HomeColor.purple)
                    Text(session.detailText)
                        .font(.caption)
                        .foregroundStyle(HomeColor.inactive)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(HomeColor.text)
            }
            .homeCard()
        } else {
            Text("No sessions yet — start one above!")
                .font(.subheadline)
                .foregroundStyle(HomeColor.inactive)
                .homeCard()
        }
    }

    // MARK: Progress

    private var progressCards: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Confidence")
                    .font(.system(size: 14))
                    .foregroundStyle(HomeColor.purple)
                Text(viewModel.skillProfile.map { "\($0.confidence.score)" } ?? "–")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(HomeColor.text)
                HomeProgressBar(score: viewModel.skillProfile?.confidence.score ?? 0, color: HomeColor.olive)
            }
            .homeCard()

            VStack(alignment: .leading, spacing: 8) {
                Text("Skills")
                    .font(.system(size: 14))
                    .foregroundStyle(HomeColor.purple)
                HStack(spacing: 6) {
                    ForEach(Array(viewModel.weakestSkills.enumerated()), id: \.offset) { index, skill in
                        VStack(spacing: 8) {
                            Text(skill.name)
                                .font(.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .foregroundStyle(index == 0 ? HomeColor.purple : Color(hex: 0x5E7A3A))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(index == 0 ? Color(hex: 0xEDEBF8) : Color(hex: 0xE6EED8), in: Capsule())
                            HomeProgressBar(score: skill.score, color: HomeColor.yellow)
                        }
                    }
                }
            }
            .homeCard()
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HomeProgressBar: View {
    let score: Int
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(HomeColor.track)
                Capsule().fill(color)
                    .frame(width: geo.size.width * CGFloat(min(max(score, 0), 100)) / 100)
            }
        }
        .frame(height: 12)
    }
}

private extension View {
    func homeCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(HomeColor.border))
    }
}

private extension Session.Mode {
    var homeTitle: String {
        switch self {
        case .interview: return "Mock Interview"
        case .debate: return "Debate"
        case .speech: return "Speech"
        }
    }
}

private extension Session {
    /// Average of the 4 skill scores (0-100)
    var averageScore: Int? {
        guard let s = sessionSkillScore else { return nil }
        return (s.content.score + s.engagement.score + s.clarity.score + s.confidence.score) / 4
    }

    /// "Today", "Yesterday", or a short date
    var dayText: String {
        let date = startTime ?? createdAt
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    /// "Tech · 12 min · 3/5"
    var detailText: String {
        [
            topic.map { "\($0)".capitalized },
            durationSeconds.map { "\(max(1, $0 / 60)) min" },
            averageScore.map { "\(Int((Double($0) / 20).rounded()))/5" }
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }
}
