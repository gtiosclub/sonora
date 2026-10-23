//
//  WaitingView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//


import SwiftUI
import FirebaseFirestore

//Screen 2: Waiting 
struct WaitingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @State private var sessionListener: ListenerRegistration?
    @State private var listenerError: String?
    @State private var routedSessionId: String?
    @State private var routedSession: Session?

    let matchingStartedAt: Date
    let onSessionUpdate: (Session) -> Void

    init(
        matchingStartedAt: Date = Date(),
        onSessionUpdate: @escaping (Session) -> Void = { _ in }
    ) {
        self.matchingStartedAt = matchingStartedAt
        self.onSessionUpdate = onSessionUpdate
    }

    var body: some View {
        AppLayout {
            VStack(spacing: 20) {

                Text("Searching...")
                    .font(.title2)
                    .bold()

                // Placeholder for searching animation
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))

                    ProgressView()
                        .scaleEffect(1.5)
                }
                .frame(height: 230)

                Text("Estimated wait time: 2 mins")
                    .font(.caption)
                    .foregroundColor(.gray)

                if let listenerError {
                    Text(listenerError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                OutlinedCard {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")

                        Text("Tip: Speak slightly slower than you think you need to!")
                            .font(.caption)
                    }
                }

                Spacer()

                Button {
                    Task {
                            do {
                                try await cancelWaitingRequest(
                                    userId: auth.currentUser?.id ?? ""
                                )
                            } catch {
                                print("Failed to cancel waiting request: \(error)")
                            }
                        }
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray)
                        )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: startListeningForSession)
        .onDisappear {
            sessionListener?.remove()
            sessionListener = nil
        }
        .fullScreenCover(isPresented: Binding(
            get: { routedSession != nil },
            set: { if !$0 { routedSession = nil } }
        )) {
            NavigationStack {
                if let session = routedSession {
                    switch session.status {
                    case .pending:
                        MatchFoundView(session: session) { updatedSession in
                            switch updatedSession.status {
                            case .pending:
                                break
                            case .active:
                                routedSession = updatedSession
                            case .declined, .deleted, .completed:
                                routedSession = nil
                                onSessionUpdate(updatedSession)
                            }
                        }
                    case .active:
                        LiveSessionView(session: session)
                    case .declined, .deleted, .completed:
                        EmptyView()
                    }
                }
            }
        }
    }

    private func startListeningForSession() {
        guard sessionListener == nil, let userId = auth.userID else { return }

        sessionListener = listenForUserSessions(userId: userId) { result in
            Task { @MainActor in
                switch result {
                case .success(let sessions):
                    guard let session = sessions
                        .filter({ $0.createdAt >= matchingStartedAt })
                        .max(by: { $0.createdAt < $1.createdAt }),
                          session.id != routedSessionId else {
                        return
                    }

                    switch session.status {
                    case .pending, .active:
                        routedSessionId = session.id
                        routedSession = session
                    case .declined:
                        routedSessionId = session.id
                        onSessionUpdate(session)
                    case .deleted, .completed:
                        break
                    }
                case .failure(let error):
                    listenerError = "Couldn't listen for a match: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WaitingView()
    }
}


