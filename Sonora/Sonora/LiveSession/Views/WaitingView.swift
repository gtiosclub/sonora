//
//  WaitingView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//


import SwiftUI
import Combine
import FirebaseFirestore

//Screen 2: Waiting
struct WaitingView: View {
    let mode: Session.Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth

    @State private var elapsedSeconds = 0
    @State private var showAIPrompt = false
    @State private var showTimeoutError = false
    @State private var aiSession: Session?
    @State private var showAIMatch = false
    @State private var isWaiting = true
    @State private var showAIError = false

    private let timer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()

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
                    isWaiting = false
                    Task {
                        do {
                            try await cancelWaitingRequest(userId: auth.currentUser?.id ?? "")
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
        .alert("Still looking for a match", isPresented: $showAIPrompt) {
            Button("Practice with AI") {
                isWaiting = false

                Task {
                    await switchToAI()
                }
            }

            Button("Keep Waiting", role: .cancel) {
                // Continue searching for a live opponent.
            }
        } message: {
            Text("No live match has been found yet. Would you like to practice with AI instead?")
        }

        .alert("Matchmaking Timed Out", isPresented: $showTimeoutError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("We couldn't find a live match within 5 minutes. Please try again later.")
        }
        .alert("Unable to Start AI Practice", isPresented: $showAIError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Something went wrong while starting your AI session. Please try again.")
        }

        .navigationDestination(isPresented: $showAIMatch) {
            if let aiSession {
                MatchFoundView(session: aiSession)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { _ in
            guard isWaiting && !showAIMatch && !showTimeoutError else {
                return
            }

            elapsedSeconds += 1

            if elapsedSeconds == 120 {
                showAIPrompt = true
            }

            if elapsedSeconds == 300 {
                isWaiting = false

                Task {
                    var wasRemoved = await handleTimeout()

                    if !wasRemoved {
                        print("Retrying matchmaking queue removal...")
                        wasRemoved = await handleTimeout()
                    }

                    if wasRemoved {
                        print("Matchmaking timeout cleanup successful")
                    } else {
                        print("Matchmaking timeout cleanup failed")
                    }

                    showTimeoutError = true
                }
            }
        }
        .onDisappear {
            isWaiting = false
        }
        .onAppear {
            isWaiting = true
        }
    }

    private func switchToAI() async {
        guard let userID = auth.currentUser?.id else {
            return
        }

        do {
            // Remove the user from the live matchmaking queue.
            try await cancelWaitingRequest(userId: userID)

            // Create a new AI practice session.
            let session = try await createAISession(
                userId: userID,
                mode: mode
            )

            // Save the session and navigate to the match screen.
            aiSession = session
            showAIMatch = true

        } catch {
            print("Failed to switch to AI practice: \(error)")
            showAIError = true
        }
    }

    private func handleTimeout() async -> Bool {
        guard let userID = auth.currentUser?.id else {
            return false
        }

        do {
            try await cancelWaitingRequest(userId: userID)
            print("User removed from matchmaking queue after timeout")
            return true
        } catch {
            print("Failed to remove user from queue: \(error)")
            return false
        .onAppear(perform: startListeningForSession)
        .onDisappear(perform: stopListening)
        
    }
    private func stopListening() {
        sessionListener?.remove()
        sessionListener = nil
    }
    
    private func startListeningForSession() {
        guard sessionListener == nil, let userId = auth.userID else {
            print("waiting: no listener, userID nil")
            return
        }
        print("waiting: listening as", userId)
        
        sessionListener = listenForUserSessions(userId: userId, since: matchingStartedAt) { result in
            Task { @MainActor in
                switch result {
                case .success(let sessions):
                    print("waiting: got", sessions.map { "\($0.id) \($0.status)" })
                    
                    guard let session = sessions
                        .filter({ $0.status == .pending || $0.status == .active })
                        .max(by: { $0.createdAt < $1.createdAt }),
                          session.id != routedSessionId else { return }
                    
                    routedSessionId = session.id
                    stopListening()
                    onSessionUpdate(session)   // router does the navigation
                case .failure(let error):
                    listenerError = "Couldn't listen for a match: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WaitingView(mode: .interview)
    }
}


