import SwiftUI
import Combine
import FirebaseFirestore

// Screen 2: Waiting
struct WaitingView: View {
    let mode: Session.Mode
    let topic: DebateTopic?
    let matchingStartedAt: Date
    let onSessionUpdate: (Session) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth

    @State private var elapsedSeconds = 0
    @State private var showAIPrompt = false
    @State private var showAIError = false
    @State private var isWaiting = true
    @State private var hasReachedDeadline = false
    @State private var hasPromptedForEmptyQueue = false
    @State private var isClaimingMatch = false
    @State private var pendingCandidateUpdate: [WaitingUser]?

    @State private var sessionListener: ListenerRegistration?
    @State private var queueListener: ListenerRegistration?
    @State private var listenerError: String?
    @State private var routedSessionId: String?

    private let matchingDeadline = 120
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        mode: Session.Mode,
        topic: DebateTopic? = nil,
        matchingStartedAt: Date = Date(),
        onSessionUpdate: @escaping (Session) -> Void = { _ in }
    ) {
        self.mode = mode
        self.topic = topic
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

                Text("We'll match you with the best available person within 2 minutes.")
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

                Button(action: leaveQueue) {
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
        .alert("No live match is available", isPresented: $showAIPrompt) {
            Button("Practice with AI") {
                isWaiting = false
                stopListening()
                Task { await switchToAI() }
            }
            Button("Leave queue", role: .destructive, action: leaveQueue)
            Button("Keep waiting", role: .cancel) { }
        } message: {
            Text("There isn't a compatible person in the queue right now. Would you like to practice with AI or leave the queue?")
        }
        .alert("Unable to Start AI Practice", isPresented: $showAIError) {
            Button("OK") { dismiss() }
        } message: {
            Text("Something went wrong while starting your AI session. Please try again.")
        }
        .onReceive(timer) { _ in
            guard isWaiting else { return }

            elapsedSeconds = max(0, Int(Date().timeIntervalSince(matchingStartedAt)))
            guard elapsedSeconds >= matchingDeadline, !hasReachedDeadline else { return }

            hasReachedDeadline = true
            Task { await matchBestAvailableCandidate() }
        }
        .onAppear {
            isWaiting = true
            elapsedSeconds = max(0, Int(Date().timeIntervalSince(matchingStartedAt)))
            startListeningForSession()
            startListeningForCandidates()
        }
        .onDisappear {
            isWaiting = false
            stopListening()
        }
    }

    // MARK: - Candidate selection

    private func handleCandidateUpdate(_ candidates: [WaitingUser]) async {
        guard isWaiting else { return }

        if isClaimingMatch {
            pendingCandidateUpdate = candidates
            return
        }

        guard !candidates.isEmpty else {
            if !hasPromptedForEmptyQueue {
                hasPromptedForEmptyQueue = true
                showAIPrompt = true
            }
            return
        }

        hasPromptedForEmptyQueue = false
        await tryMatching(candidates, requireThreshold: true)
    }

    private func matchBestAvailableCandidate() async {
        while isWaiting && isClaimingMatch {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        guard isWaiting, let userId = auth.userID else { return }

        do {
            // Another client can claim a candidate between the query and transaction,
            // so refresh once and try the current best candidates again.
            for _ in 0..<2 {
                let latestCandidates = try await findWaitingCandidates(
                    userId: userId,
                    mode: mode,
                    topic: topic
                )

                guard isWaiting else { return }
                if latestCandidates.isEmpty {
                    showAIPrompt = true
                    return
                }

                await tryMatching(latestCandidates, requireThreshold: false)
                guard isWaiting else { return }
            }

            showAIPrompt = true
        } catch {
            listenerError = "Couldn't check the queue: \(error.localizedDescription)"
        }
    }

    private func tryMatching(_ candidates: [WaitingUser], requireThreshold: Bool) async {
        guard isWaiting, let userId = auth.userID else { return }
        guard !isClaimingMatch else {
            pendingCandidateUpdate = candidates
            return
        }

        isClaimingMatch = true
        defer {
            isClaimingMatch = false
            if let latestCandidates = pendingCandidateUpdate {
                pendingCandidateUpdate = nil
                Task { @MainActor in
                    await handleCandidateUpdate(latestCandidates)
                }
            }
        }

        let rankedCandidates: [(candidate: WaitingUser, score: Double)]
        do {
            rankedCandidates = try await rankWaitingCandidates(
                userID: userId,
                candidates: candidates
            )
        } catch {
            listenerError = "Couldn't calculate match scores: \(error.localizedDescription)"
            return
        }

        for rankedCandidate in rankedCandidates {
            if requireThreshold && rankedCandidate.score < matchSimilarityThreshold { break }

            do {
                guard let session = try await claimWaitingCandidate(
                    userId: userId,
                    candidate: rankedCandidate.candidate,
                    mode: mode,
                    topic: topic
                ) else { continue }

                guard session.id != routedSessionId else { return }
                routedSessionId = session.id
                isWaiting = false
                stopListening()
                onSessionUpdate(session)
                return
            } catch {
                listenerError = "Couldn't create a match: \(error.localizedDescription)"
                return
            }
        }
    }

    private func switchToAI() async {
        guard let userId = auth.userID else {
            showAIError = true
            return
        }

        do {
            try await cancelWaitingRequest(userId: userId)
            let session = try await createAISession(userId: userId, mode: mode, topic: topic)
            onSessionUpdate(session)   // router pushes .active
        } catch {
            print("Failed to switch to AI practice: \(error)")
            showAIError = true
        }
    }

    private func leaveQueue() {
        isWaiting = false
        stopListening()
        Task {
            if let userId = auth.userID {
                do {
                    try await cancelWaitingRequest(userId: userId)
                } catch {
                    print("Failed to remove user from queue: \(error)")
                }
            }
            dismiss()
        }
    }

    // MARK: - Listeners

    private func stopListening() {
        sessionListener?.remove()
        sessionListener = nil
        queueListener?.remove()
        queueListener = nil
    }

    private func startListeningForCandidates() {
        guard queueListener == nil, let userId = auth.userID else { return }

        queueListener = listenForWaitingCandidates(
            userId: userId,
            mode: mode,
            topic: topic
        ) { result in
            Task { @MainActor in
                switch result {
                case .success(let candidates):
                    await handleCandidateUpdate(candidates)
                case .failure(let error):
                    listenerError = "Couldn't listen for queue updates: \(error.localizedDescription)"
                }
            }
        }
    }

    private func startListeningForSession() {
        guard sessionListener == nil, let userId = auth.userID else { return }

        sessionListener = listenForUserSessions(userId: userId, since: matchingStartedAt) { result in
            Task { @MainActor in
                switch result {
                case .success(let sessions):
                    guard let session = sessions
                        .filter({ $0.status == .pending || $0.status == .active })
                        .max(by: { $0.createdAt < $1.createdAt }),
                          session.id != routedSessionId else { return }

                    routedSessionId = session.id
                    isWaiting = false
                    stopListening()
                    onSessionUpdate(session)
                case .failure(let error):
                    listenerError = "Couldn't listen for a match: \(error.localizedDescription)"
                }
            }
        }
    }
}
