//
//  LeaderboardView.swift
//  Sonora
//
//  Created by Eshaan Dixit on 11/28/26.
//

import SwiftUI

@Observable
final class LeaderboardViewModel {
    enum State: Equatable {
        case loading
        case loaded(Leaderboard)
        case failed
    }

    var period: LeaderboardPeriod = .weekly
    var scope: LeaderboardScope = .everyone
    private(set) var state: State = .loading

    /// One result per tab, so switching back is instant.
    private var cache: [String: Leaderboard] = [:]
    private var friendIds: [String]?

    private var cacheKey: String { "\(period.rawValue)-\(scope.rawValue)" }

    func load(userId: String, forceRefresh: Bool = false) async {
        let key = cacheKey
        if !forceRefresh, let cached = cache[key] {
            state = .loaded(cached)
            return
        }
        if cache[key] == nil { state = .loading }
        do {
            if scope == .friends, friendIds == nil || forceRefresh {
                friendIds = try await LeaderboardService.friendIds(for: userId)
            }
            let board = try await LeaderboardService.load(
                period: period, scope: scope, userId: userId, friendIds: friendIds ?? []
            )
            cache[key] = board
            if key == cacheKey { state = .loaded(board) } // ignore if the user switched tabs meanwhile
        } catch {
            print("Leaderboard load failed: \(error)")
            if key == cacheKey { state = .failed }
        }
    }
}

struct LeaderboardView: View {
    @Environment(AuthManager.self) private var auth
    @State private var viewModel = LeaderboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DrillTopBar(title: "Leaderboard")

                VStack(spacing: 10) {
                    ThemedSegmentedPicker(options: LeaderboardPeriod.allCases, selection: $viewModel.period) { Text($0.title) }
                    ThemedSegmentedPicker(options: LeaderboardScope.allCases, selection: $viewModel.scope) { scope in
                        Label(scope.title, systemImage: scope == .everyone ? "globe" : "person.2")
                    }
                }

                content
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(HomeColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: "\(viewModel.period.rawValue)-\(viewModel.scope.rawValue)-\(auth.userID ?? "")") {
            if let userId = auth.userID { await viewModel.load(userId: userId) }
        }
        .refreshable {
            if let userId = auth.userID { await viewModel.load(userId: userId, forceRefresh: true) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            HStack(spacing: 10) {
                ProgressView().tint(HomeColor.purple)
                Text("Loading the leaderboard…")
                    .font(.subheadline)
                    .foregroundStyle(HomeColor.inactive)
            }
            .drillCard()
        case .failed:
            VStack(alignment: .leading, spacing: 8) {
                Text("Couldn't load the leaderboard.")
                    .font(.subheadline)
                    .foregroundStyle(HomeColor.inactive)
                Button("Try again") {
                    Task { if let userId = auth.userID { await viewModel.load(userId: userId, forceRefresh: true) } }
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(HomeColor.purple)
            }
            .drillCard()
        case .loaded(let board):
            yourRank(board.currentUser)
            VStack(alignment: .leading, spacing: 12) {
                DrillSectionHeader(viewModel.scope == .friends ? "You and your friends" : "Top \(LeaderboardService.pageSize)")
                if isEmpty(board) {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(board.entries.enumerated()), id: \.element.id) { index, entry in
                            if index > 0 { Divider().overlay(HomeColor.border.opacity(0.5)) }
                            LeaderboardRow(entry: entry, isYou: entry.userId == board.currentUser.userId)
                        }
                    }
                    .padding(.vertical, 4)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(HomeColor.border))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    /// Everyone: nobody has XP yet. Friends: it's just you (no friends added).
    private func isEmpty(_ board: Leaderboard) -> Bool {
        switch viewModel.scope {
        case .everyone: board.entries.allSatisfy { $0.xp == 0 }
        case .friends: board.entries.allSatisfy { $0.userId == board.currentUser.userId }
        }
    }

    private func yourRank(_ me: LeaderboardEntry) -> some View {
        let xpText = "\(me.xp.formatted()) XP" + (viewModel.period == .weekly ? " this week" : " all-time")
        return DrillBanner(
            mood: me.xp > 0 && me.rank <= 3 ? .happy : .wave,
            title: me.xp > 0 ? "You're #\(me.rank)" : "Not ranked yet",
            message: me.xp > 0 ? xpText : "Finish a session or drill to earn XP.",
            badge: viewModel.period == .weekly ? resetText : nil
        )
    }

    /// "Resets in 2 days" / "Resets in 5 hours" (Sunday midnight ET).
    private var resetText: String {
        let reset = LeaderboardWeek.nextReset()
        let hours = max(1, Int(reset.timeIntervalSinceNow / 3600))
        return hours >= 48 ? "Resets in \(hours / 24) days" : "Resets in \(hours) hour\(hours == 1 ? "" : "s")"
    }

    private var emptyState: some View {
        HStack(spacing: 14) {
            Tuxley(mood: .thinking)
                .frame(width: 52, height: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.scope == .friends ? "No friends yet" : "No XP yet")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(HomeColor.purple)
                Text(viewModel.scope == .friends
                     ? "Add friends to compare XP with them."
                     : "Be the first to earn XP \(viewModel.period == .weekly ? "this week" : "")!")
                    .font(.caption)
                    .foregroundStyle(HomeColor.inactive)
            }
        }
        .drillCard()
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isYou: Bool

    var body: some View {
        HStack(spacing: 12) {
            rankBadge
            Text(entry.username.prefix(1).uppercased())
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(HomeColor.olive)
                .frame(width: 36, height: 36)
                .background(Color(hex: 0xE9F0DF), in: Circle())
            HStack(spacing: 6) {
                Text(entry.username)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(HomeColor.purple)
                    .lineLimit(1)
                if isYou { DrillPill(text: "You", color: HomeColor.lavender) }
            }
            Spacer(minLength: 8)
            Text("\(entry.xp.formatted()) XP")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(HomeColor.text)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isYou ? Color(hex: 0xEDEBF8) : .clear)
    }

    /// Gold / silver / bronze circles for the top 3, plain numbers after that.
    private var rankBadge: some View {
        let medal: Color? = switch entry.xp > 0 ? entry.rank : 0 { // no medals for 0 XP
        case 1: HomeColor.yellow
        case 2: Color(hex: 0xE3E3EA)
        case 3: Color(hex: 0xF3D2B5)
        default: nil
        }
        return Text("\(entry.rank)")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(HomeColor.text)
            .frame(width: 30, height: 30)
            .background(medal ?? .clear, in: Circle())
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
    .environment(AuthManager())
}
