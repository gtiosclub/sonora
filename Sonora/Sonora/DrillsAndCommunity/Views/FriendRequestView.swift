//
//  FriendRequestView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/16/26.
//

import SwiftUI
import Combine

@MainActor
final class FriendRequestsViewModel: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case incoming = "Incoming"
        case outgoing = "Outgoing"
        var id: Self { self }
    }

    @Published var tab: Tab = .incoming
    @Published var incoming: [FriendSummary] = []
    @Published var outgoing: [FriendSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: FriendshipServicing

    init(service: FriendshipServicing) { self.service = service }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let inc = service.incomingRequests()
            async let out = service.outgoingRequests()
            incoming = try await inc
            outgoing = try await out
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ user: FriendSummary) async {
        await perform { try await self.service.acceptRequest(from: user.id); self.incoming.removeAll { $0.id == user.id } }
    }

    func decline(_ user: FriendSummary) async {
        await perform { try await self.service.declineRequest(from: user.id); self.incoming.removeAll { $0.id == user.id } }
    }

    func cancel(_ user: FriendSummary) async {
        await perform { try await self.service.cancelRequest(to: user.id); self.outgoing.removeAll { $0.id == user.id } }
    }

    private func perform(_ work: () async throws -> Void) async {
        do { try await work(); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
}

struct FriendRequestsView: View {
    @StateObject private var viewModel: FriendRequestsViewModel
    private let service: FriendshipServicing

    init(viewModel: FriendRequestsViewModel, service: FriendshipServicing) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.service = service
    }

    private var rows: [FriendSummary] {
        viewModel.tab == .incoming ? viewModel.incoming : viewModel.outgoing
    }

    var body: some View {
        VStack(spacing: 14) {
            SonoraTopBar(title: "Friend Requests") {
                BackButton()
            } trailing: {
                Color.clear.frame(width: 44, height: 44)
            }

            Picker("Requests", selection: $viewModel.tab) {
                ForEach(FriendRequestsViewModel.Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if let error = viewModel.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
            }

            if rows.isEmpty && !viewModel.isLoading {
                Spacer()
                Image(systemName: "bell.slash").font(.largeTitle).foregroundStyle(ProfilePalette.lavender)
                Text(viewModel.tab == .incoming ? "No incoming requests" : "No outgoing requests")
                    .font(.subheadline).foregroundStyle(ProfilePalette.secondaryText)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(rows) { user in
                            row(for: user)
                        }
                    }
                }
                .refreshable { await viewModel.load() }
            }
        }
        .padding(.horizontal, 16)
        .fontDesign(.rounded)
        .foregroundStyle(ProfilePalette.primaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }

    private func row(for user: FriendSummary) -> some View {
        HStack(spacing: 12) {
            NavigationLink {
                OtherUserProfileView(viewModel: OtherUserProfileViewModel(userId: user.id, service: service))
            } label: {
                HStack(spacing: 12) {
                    SmallAvatar(initials: user.initials)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName).font(.subheadline.weight(.bold))
                        Text("@\(user.username)").font(.caption).foregroundStyle(ProfilePalette.secondaryText)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if viewModel.tab == .incoming {
                Button { Task { await viewModel.accept(user) } } label: {
                    Text("Accept").font(.footnote.weight(.bold)).foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(ProfilePalette.calmGreen))
                }
                Button { Task { await viewModel.decline(user) } } label: {
                    Image(systemName: "xmark").font(.footnote.weight(.bold))
                        .foregroundStyle(ProfilePalette.secondaryText)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(.systemGray5)))
                }
                .accessibilityLabel("Decline")
            } else {
                Button { Task { await viewModel.cancel(user) } } label: {
                    Text("Cancel").font(.footnote.weight(.semibold))
                        .foregroundStyle(ProfilePalette.secondaryText)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color(.systemGray5)))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(ProfilePalette.lavender, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        FriendRequestsView(viewModel: FriendRequestsViewModel(service: MockFriendshipService()),
                           service: MockFriendshipService())
    }
}
