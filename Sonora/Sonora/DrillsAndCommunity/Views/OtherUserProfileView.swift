//
//  OtherUserProfileView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/15/26.
//

import SwiftUI
import Combine

@MainActor
final class OtherUserProfileViewModel: ObservableObject {
    @Published var profile: ProfileDisplayData?
    @Published var status: FriendRelationship = .none
    @Published var isWorking = false
    @Published var errorMessage: String?

    let userId: String
    private let service: FriendshipServicing

    init(userId: String, service: FriendshipServicing) {
        self.userId = userId
        self.service = service
    }

    func load() async {
        do {
            async let loadedProfile = service.publicProfile(userId: userId)
            async let loadedStatus = service.status(with: userId)
            profile = try await loadedProfile
            status = try await loadedStatus
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load this profile. \(error.localizedDescription)"
        }
    }

    func primaryActionTapped() async {
        let previous = status
        isWorking = true
        defer { isWorking = false }
        do {
            switch status {
            case .none:
                status = .requestSent                       // optimistic
                try await service.sendRequest(to: userId)
            case .requestSent:
                status = .none
                try await service.cancelRequest(to: userId)
            case .requestReceived:
                status = .friends
                try await service.acceptRequest(from: userId)
            case .friends:
                break
            }
            errorMessage = nil
        } catch {
            status = previous                               // roll back
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.removeFriend(userId)
            status = .none
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct OtherUserProfileView: View {
    @StateObject private var viewModel: OtherUserProfileViewModel

    init(viewModel: OtherUserProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var firstName: String {
        viewModel.profile?.displayName.split(separator: " ").first.map(String.init) ?? "User"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SonoraTopBar(title: "\(firstName)’s Profile") {
                    BackButton()
                } trailing: {
                    HStack(spacing: 8) {
                        ShareLink(item: "Add \(firstName) on Sonora!") {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body.weight(.medium))
                                .foregroundStyle(ProfilePalette.deepPlum)
                                .frame(width: 38, height: 38)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(ProfilePalette.deepPlum.opacity(0.5), lineWidth: 1))
                        }
                        .accessibilityLabel("Share profile")

                        Menu {
                            if viewModel.status == .friends {
                                Button("Remove friend", role: .destructive) {
                                    Task { await viewModel.removeFriend() }
                                }
                            }
                            // TODO: Report / Block when those exist
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.body.weight(.bold))
                                .foregroundStyle(ProfilePalette.deepPlum)
                                .frame(width: 38, height: 38)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(ProfilePalette.deepPlum.opacity(0.5), lineWidth: 1))
                        }
                        .accessibilityLabel("More options")
                    }
                }

                if let profile = viewModel.profile {
                    ProfileBody(data: profile) {
                        FriendActionButton(status: viewModel.status,
                                           isWorking: viewModel.isWorking) {
                            Task { await viewModel.primaryActionTapped() }
                        }
                    }
                } else if viewModel.errorMessage == nil {
                    ProgressView().padding(.top, 80)
                }

                if let error = viewModel.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .fontDesign(.rounded)
        .foregroundStyle(ProfilePalette.primaryText)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        OtherUserProfileView(viewModel: OtherUserProfileViewModel(
            userId: "1", service: MockFriendshipService()))
    }
}
