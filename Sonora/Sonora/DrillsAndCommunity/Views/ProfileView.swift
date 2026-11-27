//
//  ProfileView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/12/26.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    private let friendshipService: FriendshipServicing

    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var showFriends = false
    @State private var pendingRequests = 0

    init(viewModel: ProfileViewModel, friendshipService: FriendshipServicing) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.friendshipService = friendshipService
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SonoraTopBar(title: "Profile") {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundStyle(ProfilePalette.deepPlum)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Settings")
                } trailing: {
                    HStack(spacing: 8) {
                        IconSquareButton(systemImage: "bell", label: "Friend requests",
                                         badge: pendingRequests) { showNotifications = true }
                        IconSquareButton(systemImage: "pencil", label: "Edit profile") {
                            viewModel.editProfileTapped()
                        }
                    }
                }

                ProfileBody(
                    data: displayData,
                    onFriendsTapped: { showFriends = true },
                    onAddMastered: { viewModel.addMasteredTopicTapped() },
                    onAddChallenging: { viewModel.addChallengingTopicTapped() },
                    onViewProgress: { viewModel.viewProgressTapped() }
                ) { }

                if let error = viewModel.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .navigationDestination(isPresented: $viewModel.showProgress) {
                SpeakingProgressView(viewModel: viewModel.makeProgressViewModel())
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
        .fontDesign(.rounded)
        .foregroundStyle(ProfilePalette.primaryText)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        // existing destinations
        .navigationDestination(isPresented: $viewModel.showEditProfile) {
            EditProfileView(viewModel: viewModel.makeEditViewModel())
        }
        .navigationDestination(isPresented: $viewModel.showProgress) {
            SpeakingProgressView(viewModel: viewModel.makeProgressViewModel(),
                                 initials: viewModel.initials)
        }
        // new destinations
        .navigationDestination(isPresented: $showSettings) {
            SettingsView(initials: viewModel.initials,
                         makeEditViewModel: { viewModel.makeEditViewModel() })
        }
        .navigationDestination(isPresented: $showNotifications) {
            FriendRequestsView(viewModel: FriendRequestsViewModel(service: friendshipService),
                               service: friendshipService)
        }
        .navigationDestination(isPresented: $showFriends) {
            FriendsListView(viewModel: FriendsListViewModel(service: friendshipService),
                            service: friendshipService)
        }
        .onChange(of: showNotifications) { _, isOpen in if !isOpen { refreshCounts() } }
        .onChange(of: showFriends) { _, isOpen in if !isOpen { refreshCounts() } }
        .task {
            await viewModel.load()
            await viewModel.loadFriendCount()
            await loadPending()
        }
    }

    private var displayData: ProfileDisplayData {
        ProfileDisplayData(
            displayName: viewModel.displayName,
            pronouns: viewModel.pronouns,
            initials: viewModel.initials,
            drills: viewModel.drillsText,
            sessions: viewModel.sessionsText,
            friends: viewModel.friendsText,
            speakingTime: viewModel.speakingTimeText,
            streak: viewModel.streakText,
            bio: viewModel.bio,
            mastered: viewModel.masteredTopics,
            challenging: viewModel.challengingTopics
        )
    }

    private func refreshCounts() {
        Task {
            await viewModel.loadFriendCount()
            await loadPending()
    private var journey: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your speaking journey")
                .font(.title3.weight(.bold))

            HStack(spacing: 10) {
                StatCard(systemImage: "mic.fill", tint: .secondary,
                         value: viewModel.sessionsText, label: "Sessions")
                StatCard(systemImage: "clock", tint: .secondary,
                         value: viewModel.speakingTimeText, label: "Speaking time")
                StatCard(systemImage: "flame.fill", tint: .profileAccent,
                         value: viewModel.streakText, label: "Streak")
            }

            TopicSection(title: "Mastered Topics",
                         systemImage: "trophy.fill", tint: .yellow,
                         items: viewModel.masteredTopics,
                         addLabel: "Add mastered topic") { viewModel.addMasteredTopicTapped() }

            TopicSection(title: "Challenging Topics",
                         systemImage: "mountain.2.fill", tint: .red,
                         items: viewModel.challengingTopics,
                         addLabel: "Add challenging topic") { viewModel.addChallengingTopicTapped() }

            TopicSection(title: "Mode",
                         systemImage: "hammer.fill", tint: .gray,
                         items: viewModel.modes,
                         addLabel: "Add mode") { viewModel.addModeTapped() }
            
            Text("Badges")
                .font(.title3.weight(.bold))

            ForEach([AchievementDefinition.Category.drills, .sessions], id: \.self) { category in
                Text(category == .drills ? "Drill badges" : "Session badges")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 12) {
                    ForEach(viewModel.allBadges.filter { $0.category == category }) { badge in
                        BadgeView(emoji: badge.emoji,
                                  name: badge.name,
                                  earned: viewModel.isEarned(badge))
                    }
                }
            }
            
            ProgressPromoCard { viewModel.viewProgressTapped() }
        }
        
    }

    private func loadPending() async {
        pendingRequests = (try? await friendshipService.incomingRequests().count) ?? 0
    }
}

#Preview {
    NavigationStack {
        ProfileView(viewModel: ProfileViewModel(profile: exampleUserProfile, streak: 5),
                    friendshipService: MockFriendshipService())
    }
}
