//
//  ProfileViewModel.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/15/26.
//

//  ViewModel for the main Profile page.
//  ObservableObject to match HeatMapViewModel.

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - State
    @Published private(set) var profile: UserProfile
    @Published private(set) var streak: Int
    @Published private(set) var errorMessage: String?

    // MARK: - Navigation state (the view binds to these)
    @Published var showEditProfile = false
    @Published var showProgress = false

    // MARK: - Hooks for pages that don't exist yet.
    // The buttons are real buttons; whoever presents this screen
    // assigns what they do.
    var onBack: (() -> Void)?                  // nil = no back button shown
    var onSettings: () -> Void = {}
    var onAddMasteredTopic: () -> Void = {}
    var onAddChallengingTopic: () -> Void = {}
    var onAddMode: () -> Void = {}

    private let sessionScores: [SessionSkillScore]
    private let repository: any ProfileRepository

    init(
        profile: UserProfile,
        streak: Int,
        sessionScores: [SessionSkillScore]? = nil,
        repository: (any ProfileRepository)? = nil
    ) {
        self.profile = profile
        self.streak = streak
        // nil -> sample data (swap for real data once Firebase is connected)
        self.sessionScores = sessionScores ?? exampleSessionScores
        self.repository = repository ?? MockProfileRepository(profile: profile)
    }

    // MARK: - Display values
    var displayName: String { profile.fullName.isEmpty ? profile.username : profile.fullName }
    var handle: String { "@\(profile.username)" }
    var initials: String { profile.initials }

    var sessionsText: String { "\(profile.totalSessions)" }

    var speakingTimeText: String {
        let seconds = profile.totalSpeakingSeconds
        if seconds < 3600 { return "\(seconds / 60)m" }
        return String(format: "%.1fh", Double(seconds) / 3600)
    }

    var streakText: String { "\(streak) day\(streak == 1 ? "" : "s")" }

    var masteredTopics: [String] { profile.masteredTopics }
    var challengingTopics: [String] { profile.challengingTopics }
    var modes: [String] { profile.modes }

    // MARK: - Loading
    func load() async {
        do {
            profile = try await repository.fetchProfile(userId: profile.id)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load your profile."
        }
    }

    // MARK: - Actions
    func editProfileTapped() { showEditProfile = true }
    func viewProgressTapped() { showProgress = true }
    func settingsTapped() { onSettings() }
    func addMasteredTopicTapped() { onAddMasteredTopic() }
    func addChallengingTopicTapped() { onAddChallengingTopic() }
    func addModeTapped() { onAddMode() }

    // MARK: - Child ViewModels
    func makeEditViewModel() -> EditProfileViewModel {
        EditProfileViewModel(profile: profile, repository: repository) { [weak self] updated in
            self?.profile = updated
        }
    }

    func makeProgressViewModel() -> SpeakingProgressViewModel {
        SpeakingProgressViewModel(sessionScores: sessionScores)
    }
}
