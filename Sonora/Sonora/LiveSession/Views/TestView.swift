
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

    var body: some View {
        VStack {
            Text("Testing View")
                .font(.title2.bold())
            Text("Add a button that calls your function so we can test it ")
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


            // Ticket 1: looks for a waiting user in .interview mode
            Button("Test Find Waiting Match") {
                Task {
                    do {
                        let match = try await findWaitingMatch(mode: .interview)
                        output = match.map { "Match: \($0.userID)" } ?? "no match"
                    } catch {
                        output = "ERROR: \(error.localizedDescription)"
                    }
                }
            }

            Text(output)
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
        }
        .padding()
    }
}
