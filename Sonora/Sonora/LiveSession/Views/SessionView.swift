//
//  SessionView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 14/10/26.
//

import SwiftUI

// Main view that manages which screen is displayed
struct MatchmakingView: View {
    var body: some View {
        // Display the appropriate screen
    }
}

// Screen 1: Choose a mode
struct ModePickerView: View {
    var body: some View {
        Text("Choose a Mode")
    }
}

// Screen 2: Finding a match
struct FindingMatchView: View {
    var body: some View {
        Text("Finding a Match...")
    }
}

// Screen 3: Found Match
struct MatchFoundView: View {
    var body: some View {
        Text("Match Found!")
        
        HStack {
            Button("Leave Queue") {
                print("Left Queue")
            }
    }
}

// Screen 4: Accept or decline a match
struct AcceptOrDecline: View {
    var body: some View {
        VStack {
            Text("Accept or Decline")

            HStack {
                Button("Accept") {
                    print("Match accepted!")
                }

                Button("Decline") {
                    print("Match declined!")
                }
            }
        }
    }
}


// Screen 5: Waiting for the other person (if user accepts the match)
struct WaitingForAcceptanceView: View {
    var body: some View {
        Text("Waiting for the other person...")
    }
}
