import SwiftUI
import AVKit

/// Screen 2/3 of the session-feedback flow: the full transcript page.
/// Reached from the feedback summary via "See Transcript". Tapping a transcript
/// moment — or a pin on the video timeline — highlights it, reveals the matching
/// finding inline (screen 3), and seeks the video to that point.
struct SessionTranscriptView: View {

    let transcript: Transcript
    let report: AnalysisReport
    var videoURL: URL?
    var dateText: String = "Recorded Oct 18, 2026 · 4:35"

    /// Cap heights so long transcripts/moments scroll within their own pane.
    /// Each pane still shrinks to fit when its content is shorter than the cap.
    private let transcriptPaneHeight: CGFloat = 300
    private let momentsPaneHeight: CGFloat = 200

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSegmentID: TranscriptSegment.ID?
    @State private var player: AVPlayer?
    @State private var transcriptContentHeight: CGFloat = 0
    @State private var momentsContentHeight: CGFloat = 0

    private var segments: [TranscriptSegment] {
        Self.makeSegments(words: transcript.words, findings: report.findings)
    }

    /// Length of the video timeline, used to place the findings pins.
    private var timelineDuration: TimeInterval {
        max(transcript.words.last?.end ?? 0, report.findings.map(\.start).max() ?? 0, 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SonoraPageHeader(title: "Session Feedback", subtitle: dateText)
                videoSection
                transcriptSection
                momentsSection
                metricsSection
                progressSection
                bottomButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(SonoraColor.background)
        .navigationTitle("Session Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { makePlayerIfNeeded() }
        .onChange(of: videoURL) { _, _ in makePlayerIfNeeded() }
    }

    // MARK: - Video

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SonoraSectionHeader("Video Playback")
            VStack(spacing: 12) {
                Group {
                    if let player {
                        VideoPlayer(player: player)
                            .frame(height: 210)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(SonoraColor.accent.opacity(0.12))
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 46))
                                .foregroundStyle(SonoraColor.accent)
                        }
                        .frame(height: 210)
                    }
                }
                if !report.findings.isEmpty {
                    findingsTimeline
                }
            }
            .sonoraCard()
        }
    }

    /// A thin timeline under the video with a tappable pin at each finding.
    private var findingsTimeline: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(SonoraColor.track)
                        .frame(height: 4)
                        .frame(maxHeight: .infinity, alignment: .center)
                    ForEach(Array(report.findings.enumerated()), id: \.offset) { _, finding in
                        let fraction = finding.start / timelineDuration
                        let x = min(max(CGFloat(fraction) * width, 8), width - 8)
                        Button {
                            selectMoment(finding)
                        } label: {
                            Circle()
                                .fill(SonoraColor.warning)
                                .frame(width: 15, height: 15)
                                .overlay(Circle().stroke(SonoraColor.card, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .offset(x: x - 7.5)
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                }
            }
            .frame(height: 16)
            HStack {
                Text("0:00")
                Spacer()
                Text(timelineDuration.asClock)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(SonoraColor.textSecondary)
        }
    }

    // MARK: - Transcript

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SonoraSectionHeader("Transcript")
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(segments) { segment in
                            transcriptRow(segment)
                                .id(segment.id)
                        }
                    }
                    .padding(.vertical, 2)
                    .background(heightReader)
                }
                .frame(height: min(transcriptContentHeight, transcriptPaneHeight))
                .onPreferenceChange(PaneHeightKey.self) { transcriptContentHeight = $0 }
                .onChange(of: selectedSegmentID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private func transcriptRow(_ segment: TranscriptSegment) -> some View {
        let isSelected = selectedSegmentID == segment.id
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(segment.start.asClock)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(SonoraColor.accent)
                    .frame(width: 44, alignment: .leading)
                Text(segment.text)
                    .font(.subheadline)
                    .foregroundStyle(SonoraColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !segment.findings.isEmpty {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(SonoraColor.warning)
                }
            }

            if isSelected {
                if segment.findings.isEmpty {
                    Text("No flagged moments in this segment.")
                        .font(.caption)
                        .foregroundStyle(SonoraColor.textSecondary)
                        .padding(.leading, 56)
                } else {
                    ForEach(Array(segment.findings.enumerated()), id: \.offset) { _, finding in
                        HStack(alignment: .top, spacing: 8) {
                            SonoraTag(text: finding.start.asClock)
                            Text(finding.message)
                                .font(.caption)
                                .foregroundStyle(SonoraColor.warningText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.leading, 56)
                    }
                }
            }
        }
        .sonoraCard(highlighted: isSelected)
        .contentShape(Rectangle())
        .onTapGesture { select(segment) }
    }

    // MARK: - Moments to Review

    private var momentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SonoraSectionHeader("Moments to Review")
            if report.findings.isEmpty {
                Text("No moments flagged — nice work!")
                    .font(.subheadline)
                    .foregroundStyle(SonoraColor.textSecondary)
                    .sonoraCard()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(report.findings.enumerated()), id: \.offset) { _, finding in
                            Button {
                                selectMoment(finding)
                            } label: {
                                HStack(spacing: 12) {
                                    SonoraTag(text: finding.start.asClock)
                                    Text(finding.message)
                                        .font(.subheadline)
                                        .foregroundStyle(SonoraColor.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "play.circle")
                                        .font(.body)
                                        .foregroundStyle(SonoraColor.accent)
                                }
                                .sonoraCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                    .background(heightReader)
                }
                .frame(height: min(momentsContentHeight, momentsPaneHeight))
                .onPreferenceChange(PaneHeightKey.self) { momentsContentHeight = $0 }
            }
        }
    }

    // MARK: - Metrics
    
    /// Lists every computed metric entry (name + value), and show nothing when there is none.
    @ViewBuilder
    private var metricsSection: some View {
        if !report.metrics.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SonoraSectionHeader("Metrics")
                VStack(spacing: 0) {
                    ForEach(Array(report.metrics.enumerated()), id: \.offset) { index, metric in
                        HStack {
                            Text(metric.name)
                                .font(.subheadline)
                                .foregroundStyle(SonoraColor.textPrimary)
                            Spacer()
                            Text(String(format: "%.1f", metric.value))
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(SonoraColor.textPrimary)
                        }
                        .padding(.vertical, 8)
                        
                        if index < report.metrics.count - 1 {
                            Divider()
                        }
                    }
                }
                .sonoraCard()
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SonoraSectionHeader("Progress")
            VStack(alignment: .leading, spacing: 12) {
                Text("Filler words across recent sessions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SonoraColor.textPrimary)
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(Self.progressSample.enumerated()), id: \.offset) { index, value in
                        let isLatest = index == Self.progressSample.count - 1
                        Capsule()
                            .fill(isLatest ? SonoraColor.accent : SonoraColor.track)
                            .frame(height: CGFloat(value) * 10)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 90, alignment: .bottom)
                Text("Trending down — fewer fillers than last session.")
                    .font(.caption)
                    .foregroundStyle(SonoraColor.textSecondary)
            }
            .sonoraCard()
        }
        .padding(.top, 10)
    }

    private var bottomButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Back to Recommendations")
        }
        .buttonStyle(SonoraPrimaryButtonStyle())
        .padding(.top, 20)
    }

    // MARK: - Actions

    private func makePlayerIfNeeded() {
        guard player == nil, let videoURL else { return }
        // Use the playback category so audio is heard even when the ring/silent
        // switch is set to silent (the default ambient category stays muted).
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        player = AVPlayer(url: videoURL)
    }

    /// Toggles selection of a transcript segment and seeks the video to its start.
    private func select(_ segment: TranscriptSegment) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedSegmentID = (selectedSegmentID == segment.id) ? nil : segment.id
        }
        if selectedSegmentID == segment.id {
            seek(to: segment.start)
        }
    }

    /// Selects the transcript segment nearest a finding and seeks the video there.
    private func selectMoment(_ finding: Finding) {
        guard let segment = nearestSegment(to: finding.start) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedSegmentID = segment.id
        }
        seek(to: finding.start)
    }

    /// The segment containing the time, or the closest one by start if it falls in a gap.
    private func nearestSegment(to time: TimeInterval) -> TranscriptSegment? {
        let all = segments
        if let containing = all.first(where: { time >= $0.start && time <= $0.end }) {
            return containing
        }
        return all.min { abs($0.start - time) < abs($1.start - time) }
    }

    private func seek(to seconds: TimeInterval) {
        guard let player else { return }
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        player.play()
    }

    // MARK: - Helpers

    /// Measures the content height of a pane so its scroll view can hug the content
    /// (up to its cap) instead of leaving dead space.
    private var heightReader: some View {
        GeometryReader { geo in
            Color.clear.preference(key: PaneHeightKey.self, value: geo.size.height)
        }
    }

    /// Illustrative recent-session filler counts for the Progress placeholder.
    private static let progressSample = [7, 6, 8, 5, 4]

    /// Groups transcript words into readable segments (new segment on a pause gap
    /// or after a max run of words) and attaches any findings that fall in each range.
    static func makeSegments(words: [TranscriptWord], findings: [Finding]) -> [TranscriptSegment] {
        guard !words.isEmpty else { return [] }

        let gapThreshold: TimeInterval = 0.6
        let maxWords = 12

        var segments: [TranscriptSegment] = []
        var current: [TranscriptWord] = []

        func flush() {
            guard let first = current.first, let last = current.last else { return }
            let text = current.map(\.text).joined(separator: " ")
            let inRange = findings.filter { $0.start >= first.start && $0.start <= last.end }
            segments.append(
                TranscriptSegment(start: first.start, end: last.end, text: text, findings: inRange)
            )
            current = []
        }

        for word in words {
            if let prev = current.last, word.start - prev.end > gapThreshold || current.count >= maxWords {
                flush()
            }
            current.append(word)
        }
        flush()
        return segments
    }
}

/// One line of the transcript: a run of words with any findings that landed inside it.
struct TranscriptSegment: Identifiable {
    let id = UUID()
    let start: TimeInterval
    let end: TimeInterval
    let text: String
    let findings: [Finding]
}

/// Carries a pane's measured content height up to its scroll view.
private struct PaneHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    let words: [TranscriptWord] = [
        .init(text: "good", start: 0.0, end: 0.3, confidence: 0.99),
        .init(text: "morning", start: 0.3, end: 0.7, confidence: 0.99),
        .init(text: "everyone", start: 0.7, end: 1.2, confidence: 0.98),
        .init(text: "um", start: 2.1, end: 2.4, confidence: 0.8),
        .init(text: "today", start: 2.5, end: 2.9, confidence: 0.97),
        .init(text: "i", start: 2.9, end: 3.0, confidence: 0.97),
        .init(text: "want", start: 3.0, end: 3.3, confidence: 0.97),
        .init(text: "to", start: 3.3, end: 3.4, confidence: 0.97),
        .init(text: "talk", start: 3.4, end: 3.7, confidence: 0.97),
        .init(text: "about", start: 3.7, end: 4.0, confidence: 0.97),
        .init(text: "our", start: 4.0, end: 4.2, confidence: 0.97),
        .init(text: "results", start: 4.2, end: 4.8, confidence: 0.96),
        .init(text: "so", start: 6.0, end: 6.3, confidence: 0.95),
        .init(text: "uh", start: 6.4, end: 6.7, confidence: 0.82),
        .init(text: "the", start: 6.8, end: 6.9, confidence: 0.97),
        .init(text: "numbers", start: 6.9, end: 7.4, confidence: 0.96),
        .init(text: "look", start: 7.4, end: 7.7, confidence: 0.97),
        .init(text: "strong", start: 7.7, end: 8.2, confidence: 0.96),
    ]
    let transcript = Transcript(words: words)
    let report = SpeechReportBuilder().buildReport(from: transcript)
    return NavigationStack {
        SessionTranscriptView(transcript: transcript, report: report)
    }
}
