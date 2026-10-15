//
//  DebateDrillListView.swift
//  Sonora
//
//  Created by Eshaan Dixit on 10/13/26.
//

import SwiftUI

enum DrillResponseMode: String, CaseIterable, Identifiable {
    case audio
    case video

    var id: Self { self }

    var title: String {
        switch self {
        case .audio: "Audio only"
        case .video: "Video"
        }
    }

    var icon: String {
        switch self {
        case .audio: "mic"
        case .video: "video"
        }
    }

    var hint: String {
        switch self {
        case .audio: "Records your voice only. Body language isn't scored."
        case .video: "Records your voice and camera."
        }
    }
}

extension Session {
    var displayPrompt: String {
        let text = (prompt ?? "Untitled debate").trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    var detailLine: String {
        var parts = [(startTime ?? createdAt).formatted(.dateTime.month(.abbreviated).day())]
        if let durationSeconds {
            parts.append("\(durationSeconds / 60) min")
        }
        parts.append(opponentType == .ai ? "vs AI" : "vs peer")
        return parts.joined(separator: " · ")
    }
}

extension SessionSkillScore {
    var namedScores: [(name: String, score: Int)] {
        [
            ("Content", content.score),
            ("Clarity", clarity.score),
            ("Confidence", confidence.score),
            ("Engagement", engagement.score),
        ]
    }

    var weakest: (name: String, score: Int)? {
        namedScores.min { $0.score < $1.score }
    }

    var strongest: (name: String, score: Int)? {
        namedScores.max { $0.score < $1.score }
    }
}

struct DebateDrillListView: View {
    private let debates = DebateSessions.lastFive

    @State private var selectedDebateId: String? = DebateSessions.lastFive.first?.id
    @State private var responseMode: DrillResponseMode = .audio
    @State private var drill: DebateDrillPrompt?
    @State private var isGenerating = false
    @State private var showDrill = false

    private var selectedDebate: Session? {
        debates.first { $0.id == selectedDebateId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SonoraPageHeader(title: "Debate drills", subtitle: "Pick a debate to practice from.")

                SonoraSectionHeader("Your recent debates")
                VStack(spacing: 10) {
                    ForEach(debates) { debate in
                        Button {
                            selectedDebateId = debate.id
                        } label: {
                            DebateRow(debate: debate, isSelected: debate.id == selectedDebateId)
                        }
                        .buttonStyle(.plain)
                    }
                }

                SonoraSectionHeader("Respond with")
                    .padding(.top, 12)
                ResponseModePicker(selection: $responseMode)
                Text(responseMode.hint)
                    .font(.footnote)
                    .foregroundStyle(SonoraColor.textSecondary)
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                Button {
                    Task { await getDrill() }
                } label: {
                    if isGenerating {
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("Writing your drill…")
                        }
                    } else {
                        Text("Get drill")
                    }
                }
                .buttonStyle(SonoraPrimaryButtonStyle())
                .disabled(selectedDebate == nil || isGenerating)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(SonoraColor.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showDrill) {
            if let selectedDebate, let drill {
                DebateDrillDetailView(
                    debate: selectedDebate,
                    responseMode: responseMode,
                    taskType: drill.taskType,
                    drillText: drill.drillContext
                )
            }
        }
    }

    private func getDrill() async {
        guard let selectedDebate else { return }
        isGenerating = true
        defer { isGenerating = false }

        drill = await DebateDrillGenerator.generate(for: selectedDebate)
        showDrill = true
    }
}

private struct DebateRow: View {
    let debate: Session
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "bubble.left.and.bubble.right")
                .font(.system(size: 15))
                .foregroundStyle(isSelected ? SonoraColor.accent : SonoraColor.textSecondary)
                .frame(width: 34, height: 34)
                .background(isSelected ? SonoraColor.accentLight : SonoraColor.background, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(debate.displayPrompt)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SonoraColor.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(debate.detailLine)
                    .font(.footnote)
                    .foregroundStyle(SonoraColor.textSecondary)
                if let weakest = debate.sessionSkillScore?.weakest {
                    SonoraTag(text: "Weakest: \(weakest.name)")
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .sonoraCard(highlighted: isSelected)
    }
}

private struct ResponseModePicker: View {
    @Binding var selection: DrillResponseMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DrillResponseMode.allCases) { mode in
                let isOn = mode == selection
                Button {
                    selection = mode
                } label: {
                    Label(mode.title, systemImage: mode.icon)
                        .font(.subheadline.weight(isOn ? .semibold : .regular))
                        .foregroundStyle(isOn ? SonoraColor.textPrimary : SonoraColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isOn {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(SonoraColor.card)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(SonoraColor.border))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(SonoraColor.track, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        DebateDrillListView()
    }
}
