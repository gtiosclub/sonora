//
//  PairingSetupView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//



import SwiftUI
import Observation

//Screen 1: Pairing Setup
struct PairingSetupView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var practiceType = "Select"
    @State private var topic = ""
    @State private var sessionLength = 10
    @State private var router = PairingNavigationRouter()
    @State private var selectedDebateTopic: DebateTopic = .aiInEducation
    @State private var practicePartner = "Live person"
    @State private var matchingError: String?

    let practiceTypes = [
        "Select",
        "Interview Practice",
        "Public Speaking",
        "Debate"
    ]
    
    let practicePartners = ["Live person", "AI partner"]

    let sessionLengths = [5, 10, 20, 30]

    var body: some View {
        NavigationStack(path: $router.path) {
            AppLayout {
                VStack(alignment: .leading, spacing: 20) {

                    Text("Join A Practice Session")
                        .font(.title2)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRACTICE WITH")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            ForEach(practicePartners, id: \.self) { partner in
                                let isSelected = practicePartner == partner

                                Button {
                                    practicePartner = partner
                                } label: {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Image(systemName: partner == "Live person"
                                              ? "person.2"
                                              : "sparkles")
                                            .font(.title2)

                                        Text(partner)
                                            .font(.headline)

                                        Text(partner == "Live person"
                                             ? "Practice with another user"
                                             : "Practice with AI")
                                            .font(.caption)
                                            .foregroundStyle(
                                                isSelected ? .white.opacity(0.8) : .secondary
                                            )
                                            .multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .frame(height: 112)
                                    .background(isSelected ? Color.black : Color.white)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                isSelected ? Color.black : Color.gray.opacity(0.4),
                                                lineWidth: 1
                                            )
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Practice type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRACTICE TYPE")
                            .font(.caption)

                        Picker("Practice Type", selection: $practiceType) {
                            ForEach(practiceTypes, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .tint(.black)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray)
                        )
                    }

                    // Topic
                    if practiceType == "Debate" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DEBATE TOPIC")
                                .font(.caption)

                            Picker("Debate Topic", selection: $selectedDebateTopic) {
                                ForEach(DebateTopic.allCases) { topic in
                                    Text(topic.question)
                                        .tag(topic)
                                }
                            }
                            .tint(.black)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray)
                            )
                        }
                    }

                    // Session length
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SESSION LENGTH")
                            .font(.caption)

                        HStack(spacing: 8) {
                            ForEach(sessionLengths, id: \.self) { length in
                                Button("\(length) mins") {
                                    sessionLength = length
                                }
                                .font(.caption)
                                .padding(10)
                                .foregroundColor(
                                    sessionLength == length ? .white : .black
                                )
                                .background(
                                    sessionLength == length ? Color.black : Color.white
                                )
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray)
                                )
                            }
                        }
                    }

                    Spacer()
                    
                    Button {
                        Task { @MainActor in
                            do {
                                print("button called")
                                let selectedMode: Session.Mode
                                switch practiceType {
                                case "Interview Practice":
                                    selectedMode = .interview
                                case "Debate":
                                    selectedMode = .debate
                                case "Public Speaking":
                                    selectedMode = .speech
                                default:
                                    selectedMode = .interview
                                }

                                if practicePartner == "AI partner" {
                                    let session = try await createAISession(
                                        userId: auth.currentUser?.id ?? "",
                                        mode: selectedMode
                                    )
                                    routeToSession(session)
                                } else {
                                    let matchingStartedAt = Date()
                                    let session = try await requestRandomMatch(
                                        userId: auth.currentUser?.id ?? "",
                                        mode: selectedMode,
                                        topic: selectedMode == .debate ? selectedDebateTopic : nil
                                    )

                                    if let session {
                                        routeToSession(session)
                                        print("session found")
                                    } else {
                                        router.path.append(.waiting(matchingStartedAt))
                                        print("session not found")
                                    }
                                }
                            } catch {
                                print("Matching failed: \(error)")
                                matchingError = error.localizedDescription
                            }
                        }
                            
                    } label: {
                        Text("Find a match")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(6)
                    }

                }
            }
            .navigationDestination(for: PairingRoute.self) { route in
                switch route {
                case .waiting(let matchingStartedAt):
                    WaitingView(matchingStartedAt: matchingStartedAt) { session in
                        routeFromWaiting(session)
                    }
                case .invitation(let session):
                    MatchFoundView(session: session) { updatedSession in
                        handleInvitationUpdate(updatedSession)
                    }
                case .active(let session):
                    LiveSessionView(session: session)
                }
            }
            .alert("Couldn't find a match", isPresented: Binding(
                get: { matchingError != nil },
                set: { if !$0 { matchingError = nil } }
            )) {
                Button("OK", role: .cancel) { matchingError = nil }
            } message: {
                Text(matchingError ?? "Please try again.")
            }
        }
    }

    private func routeToSession(_ session: Session) {
        switch session.status {
        case .pending:
            router.path.append(.invitation(session))
        case .active:
            router.path.append(.active(session))
        case .declined, .deleted, .completed:
            router.path.removeAll()
            dismiss()
        }
    }

    private func routeFromWaiting(_ session: Session) {
        switch session.status {
        case .pending:
            router.path = router.path + [.invitation(session)]
        case .active:
            router.path = router.path + [.active(session)]
        case .declined, .deleted, .completed:
            router.path.removeAll()
            dismiss()
        }
    }

    private func handleInvitationUpdate(_ session: Session) {
        switch session.status {
        case .pending:
            break
        case .active:
            if let lastRoute = router.path.last,
               case .invitation(let currentSession) = lastRoute,
               currentSession.id == session.id {
                router.path[router.path.count - 1] = .active(session)
            }
        case .declined, .deleted, .completed:
            router.path.removeAll()
            dismiss()
        }
    }
}

private enum PairingRoute: Hashable {
    case waiting(Date)
    case invitation(Session)
    case active(Session)

    static func == (lhs: PairingRoute, rhs: PairingRoute) -> Bool {
        switch (lhs, rhs) {
        case let (.waiting(lhsDate), .waiting(rhsDate)):
            return lhsDate == rhsDate
        case let (.invitation(lhsSession), .invitation(rhsSession)):
            return lhsSession.id == rhsSession.id
        case let (.active(lhsSession), .active(rhsSession)):
            return lhsSession.id == rhsSession.id
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .waiting(let date):
            hasher.combine(0)
            hasher.combine(date)
        case .invitation(let session):
            hasher.combine(1)
            hasher.combine(session.id)
        case .active(let session):
            hasher.combine(2)
            hasher.combine(session.id)
        }
    }
}

@MainActor
@Observable
private final class PairingNavigationRouter {
    var path: [PairingRoute] = []
}

#Preview {
    PairingSetupView()
}
