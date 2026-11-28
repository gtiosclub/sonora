//
//  DrillDetailView.swift
//  Sonora
//
//  Created by Eshaan Dixit on 10/13/26.
//

import SwiftUI

struct DrillDetailView: View {
    let session: Session
    let responseMode: DrillResponseMode
    let drill: any DrillKind
    let drillText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DrillTopBar(title: "Your drill")

                DrillBanner(mood: .happy, title: drill.title, message: session.displayPrompt, badge: "2 min drill")

                VStack(alignment: .leading, spacing: 10) {
                    Label("Coach's note", systemImage: drill.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HomeColor.purple)
                    Text(drillText)
                        .font(.system(size: 15))
                        .foregroundStyle(HomeColor.text)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .drillCard()

                if let skills = session.sessionSkillScore,
                   let weakest = skills.weakest,
                   let strongest = skills.strongest {
                    VStack(alignment: .leading, spacing: 12) {
                        DrillSectionHeader("From that \(session.mode.title.lowercased())")
                        VStack(spacing: 16) {
                            DrillSkillBar(name: weakest.name, score: weakest.score, isWeak: true)
                            DrillSkillBar(name: strongest.name, score: strongest.score)
                        }
                        .drillCard()
                    }
                }

                VStack(spacing: 14) {
                    Label(responseMode.title, systemImage: responseMode.icon)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(HomeColor.inactive)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                    } label: {
                        Label("Start recording", systemImage: "record.circle")
                    }
                    .buttonStyle(DrillPrimaryButtonStyle())

                    Button("Get a different drill") {
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(HomeColor.purple)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(HomeColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        DrillDetailView(
            session: DebateSessions.debateSession1,
            responseMode: .audio,
            drill: DrillTaskType.closingStatement,
            drillText: "Your argument didn't fully wrap up your stance. You should try delivering a concise closing statement for your side."
        )
    }
}
