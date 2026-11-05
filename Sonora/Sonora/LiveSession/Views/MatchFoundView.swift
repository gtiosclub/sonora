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

    @State private var opponent: User?
    @State private var opponentSkills: SkillProfile?
    @State private var showOpponentProfile = false
    @State private var isLoadingOpponent = true
    @State private var opponentError: String?
    @Environment(AuthManager.self) private var auth

        private var opponentID: String? {
            guard let currentUserID = auth.currentUser?.id else {
                return nil
            }

            return session.participants.first { participantID in
                participantID != currentUserID
            }
        }
    var body: some View {
        AppLayout {
            VStack(alignment: .leading, spacing: 20) {
                Text("It's a Match!")
                    .font(.title2)
                    .bold()

                Text("Session invitation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                OutlinedCard {
                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.square")
                            .font(.system(size: 55))

                        Text(
                            session.opponentType == .ai
                                ? "AI Practice Partner"
                                : opponent?.username ?? (
                                    isLoadingOpponent ? "Loading opponent..." : "Opponent unavailable"
                                )
                        )
                        .font(.headline)
                        if session.opponentType == .human {
                            Button {
                                showOpponentProfile = true
                            } label: {
                                HStack(spacing: 6) {
                                    Text("View Opponent Profile")
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(Color.gray.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        OutlinedCard {
                            HStack {
                                Image(systemName: "checkmark.circle")

                                Text(session.prompt ?? "You're both practicing clear, confident interview answers.")
                                    .font(.caption)
                            }
                        }

                        HStack {
                            matchTag("Intermediate Speaker")
                            matchTag("10 mins")
                        }

                        matchTag(session.mode.displayName)

                        Text("Both participants need to accept before the session starts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                Text("SESSION RULES")
                    .font(.caption)
                    .foregroundColor(.gray)

                ruleRow("Take turns. Each person gets 4 minutes to practice.")
                ruleRow("Be specific. Share one useful note after each turn.")
                ruleRow("Keep it kind. This is a judgment-free practice space.")

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

                Text(hasAccepted ? "You accepted this session." : "Accept to start the session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                PrimaryButton(
                    title: isSubmitting ? "Please wait…" : (hasAccepted ? "Accepted" : "Start"),
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
        .task {
            if session.opponentType == .human {
                await loadOpponent()
            }
        }
        .sheet(isPresented: $showOpponentProfile) {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 65))
                        .foregroundStyle(.gray)

                Text(opponent?.username ?? "Opponent")
                    .font(.title2)
                    .bold()

                Text("Speaking Skills")
                    .font(.headline)
                    if isLoadingOpponent {
                        ProgressView("Loading opponent's skills...")
                            .padding()
                    } else if let opponentError = opponentError {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundStyle(.orange)

                            Text(opponentError)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else if let skills = opponentSkills {
                    VStack(spacing: 12) {
                        skillCard(title: "Content", skill: skills.content)
                        skillCard(title: "Clarity", skill: skills.clarity)
                        skillCard(title: "Confidence", skill: skills.confidence)
                        skillCard(title: "Engaging", skill: skills.engaging)
                        }
                } else {
                    Text("No skill profile available yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(24)
            .padding(.top, 20)
            }
            .presentationDetents([.medium, .large])
        }

    }

    // Reusable tags from the original match screen.
    private func matchTag(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(8)
            .background(Color.black)
            .cornerRadius(5)
    }

    // Reusable session-rule row from the original match screen.
    private func ruleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")

            Text(text)
                .font(.subheadline)
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
    private func skillCard(title: String, skill: Skill) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Text("\(skill.score)/100")
                    .font(.headline)
            }

            ProgressView(value: Double(skill.score), total: 100)
                .tint(.black)

            Text(skill.summary.isEmpty
                 ? "No feedback available yet."
                 : skill.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private func loadOpponent() async {
        isLoadingOpponent = true
        opponentError = nil
        opponent = nil
        opponentSkills = nil

        defer {
            isLoadingOpponent = false
        }

        guard let opponentID = opponentID else {
            opponentError = "Unable to identify your opponent."
            return
        }

        do {
            opponent = try await UserService.fetch(userID: opponentID)

            if opponent == nil {
                opponentError = "Opponent profile could not be found."
                return
            }

            opponentSkills = try await SkillProfileService.fetch(for: opponentID)

        } catch {
            opponentError = "Unable to load opponent information. Please try again."
            print("Failed to fetch opponent information: \(error)")
        }
    }
}

//#Preview {
//    MatchFoundView()
//}

