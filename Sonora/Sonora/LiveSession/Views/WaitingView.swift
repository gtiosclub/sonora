import SwiftUI
import Combine
import FirebaseFirestore

// Screen 2: Waiting
struct WaitingView: View {
    let mode: Session.Mode
    let matchingStartedAt: Date
    let onSessionUpdate: (Session) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth

    @State private var elapsedSeconds = 0
    @State private var showAIPrompt = false
    @State private var showTimeoutError = false
    @State private var showAIError = false
    @State private var isWaiting = true

    @State private var sessionListener: ListenerRegistration?
    @State private var listenerError: String?
    @State private var routedSessionId: String?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        mode: Session.Mode,
        matchingStartedAt: Date = Date(),
        onSessionUpdate: @escaping (Session) -> Void = { _ in }
    ) {
        self.mode = mode
        self.matchingStartedAt = matchingStartedAt
        self.onSessionUpdate = onSessionUpdate
    }

    var body: some View {
        AppLayout {
            VStack(spacing: 20) {
                Text("Searching...")
                    .font(.title2)
                    .bold()

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
                    stopListening()
                    Task {
                        do {
                            try await cancelWaitingRequest(userId: auth.userID ?? "")
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
        .alert("Still looking for a match", isPresented: $showAIPrompt) {
            Button("Practice with AI") {
                isWaiting = false
                Task { await switchToAI() }
            }
            Button("Keep Waiting", role: .cancel) { }
        } message: {
            Text("No live match has been found yet. Would you like to practice with AI instead?")
        }
        .alert("Matchmaking Timed Out", isPresented: $showTimeoutError) {
            Button("OK") { dismiss() }
        } message: {
            Text("We couldn't find a live match within 5 minutes. Please try again later.")
        }
        .alert("Unable to Start AI Practice", isPresented: $showAIError) {
            Button("OK") { dismiss() }
        } message: {
            Text("Something went wrong while starting your AI session. Please try again.")
        }
        .onReceive(timer) { _ in
            guard isWaiting, !showTimeoutError else { return }

            elapsedSeconds += 1

            if elapsedSeconds == 120 {
                showAIPrompt = true
            }

            if elapsedSeconds == 300 {
                isWaiting = false
                stopListening()
                Task {
                    var wasRemoved = await handleTimeout()
                    if !wasRemoved { wasRemoved = await handleTimeout() }
                    print(wasRemoved
                          ? "Matchmaking timeout cleanup successful"
                          : "Matchmaking timeout cleanup failed")
                    showTimeoutError = true
                }
            }
        }
        .onAppear {
            isWaiting = true
            startListeningForSession()
        }
        .onDisappear {
            isWaiting = false
            stopListening()
        }
    }

    // MARK: - AI fallback

    private func switchToAI() async {
        guard let userId = auth.userID else {
            showAIError = true
            return
        }

        stopListening()   // don't let a late live match fight with the AI session

        do {
            try await cancelWaitingRequest(userId: userId)
            let session = try await createAISession(userId: userId, mode: mode)
            onSessionUpdate(session)   // router pushes .active
        } catch {
            print("Failed to switch to AI practice: \(error)")
            showAIError = true
        }
    }

    // MARK: - Timeout

    private func handleTimeout() async -> Bool {
        guard let userId = auth.userID else { return false }

        do {
            try await cancelWaitingRequest(userId: userId)
            return true
        } catch {
            print("Failed to remove user from queue: \(error)")
            return false
        }
    }

    // MARK: - Listener

    private func stopListening() {
        sessionListener?.remove()
        sessionListener = nil
    }

    private func startListeningForSession() {
        guard sessionListener == nil, let userId = auth.userID else {
            print("waiting: no listener (already listening or userID nil)")
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
                    isWaiting = false
                    stopListening()
                    onSessionUpdate(session)   // router does the navigation
                case .failure(let error):
                    listenerError = "Couldn't listen for a match: \(error.localizedDescription)"
                }
            }
        }
    }
}
