//
//  DebateDrillDetailView.swift
//  Sonora
//
//  Created by Eshaan Dixit on 10/13/26.
//

import SwiftUI

extension DrillTaskType {
    var title: String {
        switch self {
        case .rebuttal: "Rebuttal"
        case .analyzeSession: "Session review"
        case .newArgument: "New argument"
        case .argueOtherSide: "Argue the other side"
        case .closingStatement: "Closing statement"
        case .crossExamination: "Cross-examination"
        }
    }

    var icon: String {
        switch self {
        case .rebuttal: "arrow.uturn.backward"
        case .analyzeSession: "magnifyingglass"
        case .newArgument: "lightbulb"
        case .argueOtherSide: "arrow.left.arrow.right"
        case .closingStatement: "flag"
        case .crossExamination: "questionmark.bubble"
        }
    }
}

struct DebateDrillDetailView: View {
    let debate: Session
    let responseMode: DrillResponseMode
    let taskType: DrillTaskType
    let drillText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SonoraPageHeader(title: "Your drill", subtitle: debate.displayPrompt)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: taskType.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SonoraColor.accent)
                            .frame(width: 36, height: 36)
                            .background(SonoraColor.accentLight, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(taskType.title)
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

                if let skills = debate.sessionSkillScore,
                   let weakest = skills.weakest,
                   let strongest = skills.strongest {
                    SonoraSectionHeader("From that debate")
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
        DebateDrillDetailView(
            debate: DebateSessions.debateSession1,
            responseMode: .audio,
            taskType: .closingStatement,
            drillText: "Your argument didn't fully wrap up your stance. You should try delivering a concise closing statement for your side."
        )
    }
}
