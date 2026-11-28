import SwiftUI

struct LiveSessionView: View {
    let session: Session

    var body: some View {
        AppLayout {
            VStack(alignment: .leading, spacing: 20) {
                Text("Practice session")
                    .font(.title2.bold())

                OutlinedCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(session.mode.displayName, systemImage: "person.2.fill")
                            .font(.headline)

                        if let prompt = session.prompt, !prompt.isEmpty {
                            Text("Today's prompt")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(prompt)
                                .font(.body)
                        } else {
                            Text("Your practice partner has accepted. You can begin your session.")
                                .font(.body)
                        }
                    }
                }

                Spacer()
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
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
    LiveSessionView(
        session: Session(
            id: "preview",
            participants: ["user", "partner"],
            status: .active,
            acceptedBy: ["user", "partner"],
            mode: .interview,
            opponentType: .human,
            startTime: .now,
            createdAt: .now
        )
    )
}
