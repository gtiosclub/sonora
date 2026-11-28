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

    private enum LoadState { case loading, loaded, failed }

    @Environment(AuthManager.self) private var auth
    @State private var sessions: [Session]
    @State private var loadState: LoadState
    @State private var selectedSessionId: String?
    @State private var responseMode: DrillResponseMode = .audio
    @State private var drill: DrillPrompt?
    @State private var isGenerating = false
    @State private var showDrill = false

    /// Loads the signed-in user's real sessions from Firestore. Pass
    /// `previewSessions` (e.g. `mode.sampleSessions`) to skip loading, for previews.
    init(mode: Session.Mode, previewSessions: [Session]? = nil) {
        self.mode = mode
        _sessions = State(initialValue: previewSessions ?? [])
        _loadState = State(initialValue: previewSessions == nil ? .loading : .loaded)
        _selectedSessionId = State(initialValue: previewSessions?.first?.id)
    }

    private func loadSessions() async {
        guard loadState != .loaded else { return }
        guard let userId = auth.userID else {
            loadState = .failed
            return
        }
        loadState = .loading
        do {
            sessions = try await DrillSessionStore.recentAnalyzedSessions(userId: userId, mode: mode)
            if selectedSession == nil {
                selectedSessionId = sessions.first?.id
            }
            loadState = .loaded
        } catch {
            print("Loading drill sessions failed: \(error)")
            loadState = .failed
        }
    }

    private var selectedSession: Session? {
        sessions.first { $0.id == selectedSessionId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DrillTopBar(title: "\(mode.title) drills")

                DrillBanner(
                    mood: .wave,
                    title: "Practice your weak spots",
                    message: "Pick \(mode.nameWithArticle) and Tuxley will choose a quick drill for its weakest skill."
                )

                VStack(alignment: .leading, spacing: 12) {
                    DrillSectionHeader("Your recent \(mode.title.lowercased())s")
                    sessionList
                }

                if !sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        DrillSectionHeader("Respond with")
                        ResponseModePicker(selection: $responseMode)
                        Text(responseMode.hint)
                            .font(.footnote)
                            .foregroundStyle(HomeColor.inactive)
                    }

                    Button {
                        Task { await getDrill() }
                    } label: {
                        if isGenerating {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text("Writing your drill…")
                            }
                        } else {
                            Label("Get drill", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(DrillPrimaryButtonStyle())
                    .disabled(selectedSession == nil || isGenerating)
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(HomeColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadSessions() }
        .refreshable {
            loadState = .loading
            await loadSessions()
        }
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

    @ViewBuilder
    private var sessionList: some View {
        switch loadState {
        case .loading:
            HStack(spacing: 10) {
                ProgressView().tint(HomeColor.purple)
                Text("Loading your \(mode.title.lowercased())s…")
                    .font(.subheadline)
                    .foregroundStyle(HomeColor.inactive)
            }
            .drillCard()
        case .failed:
            VStack(alignment: .leading, spacing: 8) {
                Text("Couldn't load your \(mode.title.lowercased())s.")
                    .font(.subheadline)
                    .foregroundStyle(HomeColor.inactive)
                Button("Try again") { Task { await loadSessions() } }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(HomeColor.purple)
            }
            .drillCard()
        case .loaded where sessions.isEmpty:
            HStack(spacing: 14) {
                Tuxley(mood: .thinking)
                    .frame(width: 52, height: 60)
                VStack(alignment: .leading, spacing: 4) {
                    Text("No \(mode.title.lowercased())s yet")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(HomeColor.purple)
                    Text("Complete \(mode.nameWithArticle) to get drills. They use your session's feedback once it's analyzed.")
                        .font(.caption)
                        .foregroundStyle(HomeColor.inactive)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .drillCard()
        case .loaded:
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
    }

    private func getDrill() async {
        guard let selectedSession else { return }
        isGenerating = true
        defer { isGenerating = false }

        drill = await DrillGenerator.generate(for: selectedSession)
        showDrill = true
    }
}

// Previews use the sample sessions so the screen can be designed without Firestore.
#Preview("Debate") {
    NavigationStack {
        DrillListView(mode: .debate, previewSessions: Session.Mode.debate.sampleSessions)
    }
    .environment(AuthManager())
}

#Preview("Interview") {
    NavigationStack {
        DrillListView(mode: .interview, previewSessions: Session.Mode.interview.sampleSessions)
    }
    .environment(AuthManager())
}

#Preview("Presentation") {
    NavigationStack {
        DrillListView(mode: .speech, previewSessions: Session.Mode.speech.sampleSessions)
    }
    .environment(AuthManager())
}
