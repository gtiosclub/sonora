//
//  ProfileView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/12/26.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ScreenHeader(title: "Profile", onBack: viewModel.onBack) {
                        Button { viewModel.settingsTapped() } label: {
                            Image(systemName: "gearshape")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel("Settings")
                    }

                    identity

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
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $viewModel.showEditProfile) {
                EditProfileView(viewModel: viewModel.makeEditViewModel())
            }
            .navigationDestination(isPresented: $viewModel.showProgress) {
                SpeakingProgressView(viewModel: viewModel.makeProgressViewModel())
            }
            .task { await viewModel.load() }
        }
    }

    // MARK: - Sections

    private var identity: some View {
        VStack(spacing: 6) {
            ProfileAvatar(initials: viewModel.initials)
            Text(viewModel.displayName)
                .font(.title2.weight(.bold))
                .padding(.top, 8)
            Text(viewModel.handle)
                .foregroundStyle(.secondary)
            Button("Edit Profile") { viewModel.editProfileTapped() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
                .overlay(Capsule().strokeBorder(Color(.systemGray4), lineWidth: 1))
                .padding(.top, 4)
        }
    }

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

            ProgressPromoCard { viewModel.viewProgressTapped() }
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel(profile: exampleUserProfile, streak: 5))
}
