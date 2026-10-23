//
//  MatchFoundView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//

import FirebaseFirestore
import SwiftUI

struct MatchFoundView: View {
    @Environment(AuthManager.self) private var auth
    @State private var sessionListener: ListenerRegistration?
    @State private var hasAccepted = false
    @State private var isSubmitting = false
    @State private var actionError: String?

    let session: Session
    let onSessionUpdate: (Session) -> Void

    var body: some View {
        AppLayout {
            VStack(alignment: .leading, spacing: 20) {
                Text("Session invitation")
                    .font(.title2.bold())

                OutlinedCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 42))
                            .frame(maxWidth: .infinity)

                        Text(session.mode.displayName)
                            .font(.headline)

                        Text(session.prompt ?? "A practice partner invited you to join this session.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Both participants need to accept before the session starts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if hasAccepted {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Waiting for the other participant to accept…")
                            .font(.subheadline)
                    }
                }

                if let actionError {
                    Text(actionError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()

                PrimaryButton(
                    title: isSubmitting ? "Please wait…" : (hasAccepted ? "Accepted" : "Accept session"),
                    action: acceptInvitation
                )
                .disabled(isSubmitting || hasAccepted)

                Button(action: declineInvitation) {
                    Text("Decline")
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray)
                        }
                }
                .disabled(isSubmitting)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            hasAccepted = session.acceptedBy.contains(auth.userID ?? "")
            startListening()
        }
        .onDisappear {
            sessionListener?.remove()
            sessionListener = nil
        }
    }

    private func startListening() {
        guard sessionListener == nil else { return }

        sessionListener = listenToSession(sessionId: session.id) { result in
            Task { @MainActor in
                switch result {
                case .success(let updatedSession):
                    hasAccepted = updatedSession.acceptedBy.contains(auth.userID ?? "")
                    if updatedSession.status != .pending {
                        onSessionUpdate(updatedSession)
                    }
                case .failure(let error):
                    actionError = "Couldn't follow this session: \(error.localizedDescription)"
                }
            }
        }
    }

    private func acceptInvitation() {
        guard let userId = auth.userID else {
            actionError = "Sign in again to accept this session."
            return
        }

        isSubmitting = true
        actionError = nil
        Task {
            do {
                try await acceptSession(userId: userId, sessionID: session.id)
                hasAccepted = true
            } catch {
                actionError = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func declineInvitation() {
        guard let userId = auth.userID else {
            actionError = "Sign in again to decline this session."
            return
        }

        isSubmitting = true
        actionError = nil
        Task {
            do {
                try await declineSession(userId: userId, sessionID: session.id)
                isSubmitting = false
            } catch {
                actionError = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

private extension Session.Mode {
    var displayName: String {
        switch self {
        case .interview: "Interview practice"
        case .debate: "Debate"
        case .speech: "Public speaking"
        }
    }
}

#Preview {
    MatchFoundView(
        session: Session(
            id: "preview",
            participants: ["user", "partner"],
            status: .pending,
            acceptedBy: [],
            mode: .interview,
            opponentType: .human,
            startTime: nil,
            createdAt: .now
        ),
        onSessionUpdate: { _ in }
    )
}
