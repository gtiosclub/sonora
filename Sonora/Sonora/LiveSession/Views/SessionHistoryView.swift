//
//  SessionHistoryView.swift
//  Sonora
//
//  Created by Nidhi Nagumalla on 10/28/26.
//


import SwiftUI

struct SessionHistoryView: View {
    @Environment(AuthManager.self) private var auth

    @State private var sessions: [Session] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var opponentNames: [String: String] = [:]
    @State private var rematchingSessionID: String?
    @State private var rematchMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading sessions...")
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Sessions",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Recent Sessions",
                        systemImage: "clock",
                        description: Text("Your completed sessions will appear here.")
                    )
                } else {
                    List(sessions) { session in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.mode.rawValue.capitalized)
                                .font(.headline)
                            
                            Text(opponentNames[session.id] ?? "Loading opponent...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(session.createdAt, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            NavigationLink {
                                SavedSessionAnalysisView(session: session)
                            } label: {
                                Label("View Analysis", systemImage: "chart.bar.xaxis")
                            }
                            
                            if session.opponentType == .human {
                                Button {
                                    Task {
                                        await rematch(session: session)
                                    }
                                } label: {
                                    if rematchingSessionID == session.id {
                                        ProgressView()
                                    } else {
                                        Text("Rematch")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(rematchingSessionID != nil)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Recent Sessions")
            .alert(
                "Rematch",
                isPresented: Binding(
                    get: { rematchMessage != nil },
                    set: { if !$0 { rematchMessage = nil } }
                )
            ) {
                Button("OK") {
                    rematchMessage = nil
                }
            } message: {
                Text(rematchMessage ?? "")
            }

        }
        .task {
            await loadSessions()
        }
    }
    
    private func rematch(session: Session) async {
        guard let currentUserID = auth.userID else {
            rematchMessage = "You must be signed in to rematch."
            return
        }

        guard let opponentID = session.participants.first(where: {
            $0 != currentUserID
        }) else {
            rematchMessage = "Could not find your previous opponent."
            return
        }
        if session.mode == .debate &&
            (session.prompt?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
            rematchMessage = "This debate has no saved question, so a rematch cannot be created."
            return
        }
        
        rematchingSessionID = session.id
        defer { rematchingSessionID = nil }

        do {
            _ = try await inviteFriendToSession(
                fromUserId: currentUserID,
                toUserId: opponentID,
                mode: session.mode,
                prompt: session.prompt
            )

            rematchMessage = "Rematch invitation sent!"

        } catch {
            rematchMessage = "Failed to send invitation: \(error.localizedDescription)"
        }
    }

    private func opponentName(for session: Session) async -> String {
        if session.opponentType == .ai {
            return "AI Opponent"
        }

        guard let currentUserID = auth.userID,
              let opponentID = session.participants.first(where: { $0 != currentUserID })
        else {
            return "Unknown Opponent"
        }

        do {
            let opponent = try await UserService.fetch(userID: opponentID)
            return opponent?.username ?? "Unknown Opponent"
        } catch {
            return "Unknown Opponent"
        }
    }

    private func loadSessions() async {
        guard let userID = auth.userID else {
            errorMessage = "You must be signed in to view your sessions."
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            sessions = try await SessionHistoryService
                .fetchCompletedSessions(userID: userID)

            opponentNames = [:]

            for session in sessions {
                let name = await opponentName(for: session)
                opponentNames[session.id] = name
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
