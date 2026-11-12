//
//  DrillListView.swift
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

extension Session.Mode {
    var title: String {
        switch self {
        case .debate: "Debate"
        case .interview: "Interview"
        case .speech: "Presentation"
        }
    }

    var nameWithArticle: String {
        switch self {
        case .debate: "a debate"
        case .interview: "an interview"
        case .speech: "a presentation"
        }
    }

    var icon: String {
        switch self {
        case .debate: "bubble.left.and.bubble.right"
        case .interview: "person.2"
        case .speech: "person.wave.2"
        }
    }

    var sampleSessions: [Session] {
        switch self {
        case .debate: DebateSessions.lastFive
        case .interview: InterviewSessions.lastFive
        case .speech: PresentationSessions.lastFive
        }
    }
}

extension Session {
    var displayPrompt: String {
        let text = (prompt ?? "Untitled \(mode.title.lowercased())").trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    var detailLine: String {
        var parts = [(startTime ?? createdAt).formatted(.dateTime.month(.abbreviated).day())]
        if let durationSeconds {
            parts.append("\(durationSeconds / 60) min")
        }
        switch mode {
        case .debate: parts.append(opponentType == .ai ? "vs AI" : "vs peer")
        case .interview: parts.append(opponentType == .ai ? "AI interviewer" : "Peer interviewer")
        case .speech: break
        }
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

struct DrillListView: View {
    let mode: Session.Mode
    private let sessions: [Session]

    @State private var selectedSessionId: String?
    @State private var responseMode: DrillResponseMode = .audio
    @State private var drill: DrillPrompt?
    @State private var isGenerating = false
    @State private var showDrill = false

    init(mode: Session.Mode) {
        self.mode = mode
        self.sessions = mode.sampleSessions
        _selectedSessionId = State(initialValue: sessions.first?.id)
    }

    private var selectedSession: Session? {
        sessions.first { $0.id == selectedSessionId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SonoraPageHeader(
                    title: "\(mode.title) drills",
                    subtitle: "Pick \(mode.nameWithArticle) to practice from."
                )

                SonoraSectionHeader("Your recent \(mode.title.lowercased())s")
                if sessions.isEmpty {
                    Text("Complete \(mode.nameWithArticle) to get drills.")
                        .font(.subheadline)
                        .foregroundStyle(SonoraColor.textSecondary)
                        .sonoraCard()
                } else {
                    VStack(spacing: 10) {
                        ForEach(sessions) { session in
                            Button {
                                selectedSessionId = session.id
                            } label: {
                                SessionRow(session: session, isSelected: session.id == selectedSessionId)
                            }
                            .buttonStyle(.plain)
                        }
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
                .disabled(selectedSession == nil || isGenerating)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(SonoraColor.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showDrill) {
            if let selectedSession, let drill {
                DrillDetailView(
                    session: selectedSession,
                    responseMode: responseMode,
                    drill: drill.drill,
                    drillText: drill.drillContext
                )
            }
        }
    }

    private func getDrill() async {
        guard let selectedSession else { return }
        isGenerating = true
        defer { isGenerating = false }

        drill = await DrillGenerator.generate(for: selectedSession)
        showDrill = true
    }
}

private struct SessionRow: View {
    let session: Session
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : session.mode.icon)
                .font(.system(size: 15))
                .foregroundStyle(isSelected ? SonoraColor.accent : SonoraColor.textSecondary)
                .frame(width: 34, height: 34)
                .background(isSelected ? SonoraColor.accentLight : SonoraColor.background, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayPrompt)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SonoraColor.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(session.detailLine)
                    .font(.footnote)
                    .foregroundStyle(SonoraColor.textSecondary)
                if let weakest = session.sessionSkillScore?.weakest {
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

#Preview("Debate") {
    NavigationStack {
        DrillListView(mode: .debate)
    }
}

#Preview("Interview") {
    NavigationStack {
        DrillListView(mode: .interview)
    }
}

#Preview("Presentation") {
    NavigationStack {
        DrillListView(mode: .speech)
    }
}
