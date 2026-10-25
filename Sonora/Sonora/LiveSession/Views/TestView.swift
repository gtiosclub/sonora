
//
//  TestView.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/24/26.
//
import SwiftUI

struct TestView: View {
    @Environment(AuthManager.self) private var auth
    @State private var output = "Tap a button to test"   // shows the result on screen
    @State private var selectedDebateTopic: DebateTopic = .aiInEducation
    @State private var randomMatchOutput = "Tap random match button to test"

    var body: some View {
        VStack {
            Text("Testing View")
                .font(.title2.bold())
            Text("Add a button that calls your function so we can test it ")
            Picker("Debate Topic", selection: $selectedDebateTopic) {
                ForEach(DebateTopic.allCases) { topic in
                    Text(topic.question).tag(topic)
                }
            }
            Button("Example", role: .destructive) {}
                .padding(.top, 8)

            Button("Test Accept Session") {
                Task {
                    do {
                        try await acceptSession(userId: auth.currentUser?.id ?? "", sessionID: "Cm5gIWdmyuNpGFMGgn7I")
                    } catch {
                        print("Failed with error: \(error.localizedDescription)")
                    }
                }
            }
            
            Button("Test Create Session with Friend") {
                Task {
                    do {
                        try await inviteFriendToSession(fromUserId: auth.currentUser?.id ?? "", toUserId: "friend-user", mode: Session.Mode.debate)
                    } catch {
                        print("Failed with error: \(error.localizedDescription)")
                    }
                }
            }


            // Ticket 1: looks for a waiting user in .interview mode
            Button("Test Find Waiting Match") {
                Task {
                    do {
                        let match = try await findWaitingMatch(userId: auth.currentUser?.id ?? "", mode: .interview)
                        output = match.map { "Match: \($0.userId)" } ?? "no match"
                    } catch {
                        output = "ERROR: \(error.localizedDescription)"
                    }
                }
            }

            Text(output)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button ("Test Request Random Match") {
                Task {
                    let userID = auth.currentUser?.id ?? ""

                    do {
                        let session = try await requestRandomMatch(
                            userId: userID,
                            mode: .interview
                        )

                        if let session {
                            let opponentID = session.participants.first { $0 != userID } ?? "unknown"
                            randomMatchOutput = "Matched! Session: \(session.id)\nOpponent: \(opponentID)"
                        } else {
                            randomMatchOutput = "No match yet — added to the interview queue."
                        }
                    } catch {
                        randomMatchOutput = "ERROR: \(error.localizedDescription)"
                    }
                }
            }
            Text(randomMatchOutput)
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            Button("Test Join Wait Queue") {
                Task {
                        do {
                            try await joinQueue(userId: auth.currentUser?.id ?? "", mode: Session.Mode.interview)
                        } catch {
                            print("Failed with error: \(error.localizedDescription)")
                        }
                    }
            }
            Button("Test Join Debate Queue") {
                Task {
                    do {
                        guard let userId = auth.currentUser?.id else {
                            output = "ERROR: No user logged in"
                            return
                        }
                        try await joinQueue(userId: userId, mode: .debate, topic: selectedDebateTopic)
                        output = "Joined debate queue: \(selectedDebateTopic.question)"
                    } catch {
                        output = "ERROR: \(error.localizedDescription)"
                    }
                }
            }
            Button("Test Find Debate Match") {
                Task {
                    do {
                        guard let userId = auth.currentUser?.id else {
                            output = "ERROR: No user logged in"
                            return
                        }
                        let match = try await findWaitingMatch(userId: userId, mode: .debate, topic: selectedDebateTopic)
                        if let match = match {
                            output = "Match found: \(match.userId)"
                        } else {
                            output = "No users waiting for this debate topic"
                        }
                    } catch {
                        output = "ERROR: \(error.localizedDescription)"
                    }
                }
            }
            Button("Test Remove From Queue") {
                Task {
                    do {
                        try await cancelWaitingRequest(userId: auth.currentUser?.id ?? "")
                    } catch {
                        print("Failed with error: \(error.localizedDescription)")
                    }
                }
            }
            Button("Test Decline Sesion") {
                Task {
                        do {
                            try await declineSession(userId: auth.currentUser?.id ?? "", sessionID: "nfVcbgKJpHJSLFi70YjH")
                        } catch {
                            print("Failed with error: \(error.localizedDescription)")
                        }
                    }
            
            }
            Button ("Create Pending Session") {
                Task {
                        do {
                            try await createPendingSession(userID1: "abcd", userID2: "abc", mode: .interview)
                        } catch {
                            print("Failed with error: \(error.localizedDescription)")
                        }
                    }
            }
            Button("Test Create AI Session") {
                            Task {
                                do {
                                    let session = try await createAISession(userId: auth.currentUser?.id ?? "", mode: .interview)
                                    output = "Created: \(session.id)"
                                } catch {
                                    output = "ERROR: \(error.localizedDescription)"
                                }
                            }
                        }

                        Text(output)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
            
            Button("Test Complete Session") {
                Task {
                    do {
                        try await completeSession(sessionID: "LYtYJeufsUqX7lRXoN3S")
                    } catch {
                        print("Failed with error: \(error.localizedDescription)")
                    }
                }
            }
        }
        .padding()
    }
}
