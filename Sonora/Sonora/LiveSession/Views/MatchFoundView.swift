//
//  MatchFoundView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//


import SwiftUI

//Screen 3: Match Found
struct MatchFoundView: View {
    let session: Session
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

                                Text("You're both practicing clear, confident interview answers.")
                                    .font(.caption)
                            }
                        }

                        HStack {
                            matchTag("Intermediate Speaker")
                            matchTag("10 mins")
                        }

                        matchTag("Interview Practice")
                    }
                    .frame(maxWidth: .infinity)
                }

                Text("SESSION RULES")
                    .font(.caption)
                    .foregroundColor(.gray)

                ruleRow("Take turns. Each person gets 4 minutes to practice.")

                ruleRow("Be specific. Share one useful note after each turn.")

                ruleRow("Keep it kind. This is a judgment-free practice space.")

                Spacer()

                PrimaryButton(title: "Start") {
                    print("Start live session")
                }
            }
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

    // Reusable tags
    func matchTag(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(8)
            .background(Color.black)
            .cornerRadius(5)
    }

    // Reusable rule row
    func ruleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")

            Text(text)
                .font(.subheadline)
        }
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

