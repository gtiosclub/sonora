//
//  TestView.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/24/26.
//
import SwiftUI

struct TestView: View {
    @Environment(AuthManager.self) private var auth
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
            Button("Test Join Wait Queue") {
                Task {
                        do {
                            try await joinQueue(userID: auth.currentUser?.id ?? "", mode: Session.Mode.interview)
                        } catch {
                            print("Failed with error: \(error.localizedDescription)")
                        }
                    }
            }
            NavigationLink("Debate Drill Test") { DebateDrillTestView() }
        }
        .padding()
    }
}
