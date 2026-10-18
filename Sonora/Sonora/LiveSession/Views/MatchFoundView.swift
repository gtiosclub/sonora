//
//  MatchFoundView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//


import SwiftUI

//Screen 3: Match Found
struct MatchFoundView: View {
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

                        Text("Jason C.")
                            .font(.headline)

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
}

#Preview {
    MatchFoundView()
}

