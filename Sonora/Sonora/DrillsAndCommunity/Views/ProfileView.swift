//
//  ProfileView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/12/26.
//

import SwiftUI

enum ProfilePalette {
    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255)
    }

    static let lavender      = rgb(196, 195, 227)  // #C4C3E3  cards + highlights
    static let deepPlum      = rgb(80, 78, 118)    // #504E76  primary buttons, titles
    static let softBeige     = rgb(253, 248, 226)  // #FDF8E2  backgrounds
    static let calmGreen     = rgb(163, 181, 101)  // #A3B565  streaks + progress
    static let lightApricot  = rgb(252, 221, 157)  // #FCDD9D  warm cards (verify in Figma)
    static let brightOrange  = rgb(241, 100, 46)   // #F1642E  calls to action
    static let primaryText   = rgb(36, 36, 36)     // #242424
    static let secondaryText = rgb(81, 81, 81)     // #515151
}

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScreenHeader(title: "Profile", onBack: viewModel.onBack) {
                    Button { viewModel.settingsTapped() } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(ProfilePalette.deepPlum)
                    }
                    .accessibilityLabel("Settings")
                }

                identity
                friendsStat
                addFriendsButton

                if let error = viewModel.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }

                Divider()
                journey
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .fontDesign(.rounded)
        .foregroundStyle(ProfilePalette.primaryText)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $viewModel.showEditProfile) {
            EditProfileView(viewModel: viewModel.makeEditViewModel())
        }
        .navigationDestination(isPresented: $viewModel.showProgress) {
            SpeakingProgressView(viewModel: viewModel.makeProgressViewModel())
        }
        .sheet(isPresented: $viewModel.showAddFriend, onDismiss: {
            Task { await viewModel.loadFriendCount() }
        }) {
            AddFriendView(viewModel: AddFriendViewModel())
        }
        .task {
            await viewModel.load()
            await viewModel.loadFriendCount()
        }
    }

    // MARK: - Sections

    private var identity: some View {
        VStack(spacing: 6) {
            ProfileAvatar(initials: viewModel.initials)
            Text(viewModel.displayName)
                .font(.title2.weight(.bold))
                .foregroundStyle(ProfilePalette.deepPlum)
                .padding(.top, 8)
            Text(viewModel.handle)
                .foregroundStyle(ProfilePalette.secondaryText)
            Button("Edit Profile") { viewModel.editProfileTapped() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ProfilePalette.deepPlum)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Capsule().fill(ProfilePalette.lavender.opacity(0.6)))
                .overlay(Capsule().strokeBorder(ProfilePalette.deepPlum.opacity(0.3), lineWidth: 1))
                .padding(.top, 4)
        }
    }

    private var friendsStat: some View {
        VStack(spacing: 2) {
            Text(viewModel.friendsText)
                .font(.title3.weight(.bold))
            Text("Friends")
                .font(.caption)
                .foregroundStyle(ProfilePalette.secondaryText)
        }
        .accessibilityElement(children: .combine)
    }

    private var addFriendsButton: some View {
        Button { viewModel.addFriendTapped() } label: {
            Label("Add Friends", systemImage: "person.badge.plus")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(Capsule().fill(ProfilePalette.calmGreen))
        }
    }

    private var journey: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your speaking journey")
                .font(.title3.weight(.bold))
                .foregroundStyle(ProfilePalette.deepPlum)

            HStack(spacing: 10) {
                StatCard(systemImage: "mic.fill", tint: ProfilePalette.deepPlum,
                         value: viewModel.sessionsText, label: "Sessions")
                StatCard(systemImage: "clock", tint: ProfilePalette.deepPlum,
                         value: viewModel.speakingTimeText, label: "Speaking time")
                StatCard(systemImage: "flame.fill", tint: ProfilePalette.brightOrange,
                         value: viewModel.streakText, label: "Streak")
            }

            TopicSection(title: "Mastered Topics",
                         systemImage: "trophy.fill", tint: ProfilePalette.calmGreen,
                         items: viewModel.masteredTopics,
                         addLabel: "Add mastered topic") { viewModel.addMasteredTopicTapped() }

            TopicSection(title: "Challenging Topics",
                         systemImage: "mountain.2.fill", tint: ProfilePalette.brightOrange,
                         items: viewModel.challengingTopics,
                         addLabel: "Add challenging topic") { viewModel.addChallengingTopicTapped() }

            TopicSection(title: "Mode",
                         systemImage: "hammer.fill", tint: ProfilePalette.deepPlum,
                         items: viewModel.modes,
                         addLabel: "Add mode") { viewModel.addModeTapped() }

            ProgressPromoCard { viewModel.viewProgressTapped() }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(viewModel: ProfileViewModel(profile: exampleUserProfile, streak: 5))
    }
}
