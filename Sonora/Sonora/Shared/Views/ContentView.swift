//
//  ContentView.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/13/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        VStack {
            NavigationStack {
                Text("Hi, \(auth.currentUser?.username ?? "there")")
                    .font(.title2.bold())
                Text(auth.currentUser?.email ?? "")
                    .foregroundStyle(.secondary)
                Text(auth.userID ?? "no user")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Button("Sign out", role: .destructive) {
                    try? auth.signOut()
                }
                .padding(.top, 8)

                NavigationLink(destination: TestView()) {
                    Text("Go to Test View")
                }

                NavigationLink(destination: SkillProfileTestView()) {
                    Text("Go to SkillProfile Test View")
                }
                NavigationLink(destination: PreferenceProfileTestView()) {
                    Text("Go to PreferenceProfile Test View")
                }
                NavigationLink(destination: DrillsCommunityTestView()) {
                    Text("Go to Drills & Community Test View")
                }
                NavigationLink(destination: ProfileView(viewModel: ProfileViewModel(profile: exampleUserProfile, streak: 5))) {
                    Text("Go to Profile View")
                
                NavigationLink(destination: PairingSetupView()) {
                    Text("Go to Live Session Pairing View")
                }

                NavigationLink(destination: SessionReviewView(
                    videoURL: Bundle.main.url(forResource: "sample_presentation", withExtension: "mov"),
                    savedTranscript: Self.savedDemoTranscript
                )) {
                    Text("Go to Analysis Feedback View")
                }
            }
        }
        .padding()
    }

    /// Offline fallback transcript for the Analysis demo flow.
    private static var savedDemoTranscript: Transcript? {
        guard let url = Bundle.main.url(forResource: "deepgram_fillers_on", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? DeepgramDecoder().decode(data) else { return nil }
        return decoded
    }
}

#Preview {
    ContentView()
}
