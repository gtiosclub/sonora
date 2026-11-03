//
//  PairingSetupView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//



import SwiftUI

//Screen 1: Pairing Setup
struct PairingSetupView: View {
    @Environment(AuthManager.self) private var auth
    @State private var practiceType = "Select"
    @State private var topic = ""
    @State private var sessionLength = 10
    @State private var showWaiting = false
    @State private var matchedSession: Session?
    @State private var showMatchFound = false
    @State private var selectedDebateTopic: DebateTopic = .aiInEducation
    @State private var practicePartner = "Live person"

    let practiceTypes = [
        "Select",
        "Interview Practice",
        "Public Speaking",
        "Debate"
    ]
    
    let practicePartners = ["Live person", "AI partner"]

    let sessionLengths = [5, 10, 20, 30]

    var body: some View {
        NavigationStack {
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
                        Task {
                            do {
                                print("button called")
                                var selectedMode: Session.Mode {
                                    switch practiceType {
                                    case "Interview Practice":
                                        return .interview
                                    case "Debate":
                                        return .debate
                                    case "Public Speaking":
                                        return .speech
                                    default:
                                        return .interview
                                    }
                                }
                                var session = nil as Session?
                                
                                if practicePartner == "AI partner" {
                                    session = try await createAISession(
                                        userId: auth.currentUser?.id ?? "",
                                        mode: selectedMode
                                    )
                                    
                                    matchedSession = session
                                    showMatchFound = true
                                } else {
                                    
                                    session = try await requestRandomMatch(
                                        userId: auth.currentUser?.id ?? "",
                                        mode: selectedMode,
                                        topic: selectedMode == .debate ? selectedDebateTopic : nil
                                    )
                                }

                                if let session {
                                    matchedSession = session
                                    showMatchFound = true
                                    print("session found")

                                } else {
                                    showWaiting = true
                                    print("session not found")

                                }
                            } catch {
                                print("Matching failed: \(error)")
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
                .navigationDestination(isPresented: $showWaiting) {
                    WaitingView()
                }
                .navigationDestination(isPresented: $showMatchFound) {
                    if let matchedSession {
                        MatchFoundView(session: matchedSession)
                    }
                }
            }
        }
    }
}

#Preview {
    PairingSetupView()
}
