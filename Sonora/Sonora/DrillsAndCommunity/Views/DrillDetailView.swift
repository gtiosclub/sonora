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
            VStack(alignment: .leading, spacing: 0) {
                SonoraPageHeader(title: "Your drill", subtitle: session.displayPrompt)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: drill.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SonoraColor.accent)
                            .frame(width: 36, height: 36)
                            .background(SonoraColor.accentLight, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(drill.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(SonoraColor.textPrimary)
                            Text("2 min drill")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(SonoraColor.accent)
                        }
                    }
                    Text(drillText)
                        .font(.subheadline)
                        .foregroundStyle(SonoraColor.textPrimary)
                        .lineSpacing(3)
                }
                .sonoraCard()

                if let skills = session.sessionSkillScore,
                   let weakest = skills.weakest,
                   let strongest = skills.strongest {
                    SonoraSectionHeader("From that \(session.mode.title.lowercased())")
                        .padding(.top, 12)
                    VStack(spacing: 18) {
                        SonoraSkillBar(name: weakest.name, score: weakest.score, isWeak: true)
                        SonoraSkillBar(name: strongest.name, score: strongest.score)
                    }
                    .sonoraCard()
                }

                Label(responseMode.title, systemImage: responseMode.icon)
                    .font(.subheadline)
                    .foregroundStyle(SonoraColor.textSecondary)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                Button {
                } label: {
                    Label("Start recording", systemImage: "record.circle")
                }
                .buttonStyle(SonoraPrimaryButtonStyle())

                Button("Get a different drill") {
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SonoraColor.accent)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(SonoraColor.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
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
