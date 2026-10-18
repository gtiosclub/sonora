import SwiftUI
import AVKit

/// Screen 2/3 of the session-feedback flow: the full transcript page.
/// Reached from the feedback summary via "See Transcript". Tapping a transcript
/// moment highlights it, reveals the matching finding inline (screen 3), and seeks
/// the video to that point.
struct SessionTranscriptView: View {

    let transcript: Transcript
    let report: AnalysisReport
    var videoURL: URL?
    var dateText: String = "Recorded Oct 18, 2026 · 4:35"

    /// Fixed heights so long transcripts/moments scroll within their own pane
    /// instead of stretching the whole page.
    private let transcriptPaneHeight: CGFloat = 300
    private let momentsPaneHeight: CGFloat = 200

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSegmentID: TranscriptSegment.ID?
    @State private var player: AVPlayer?

    private var segments: [TranscriptSegment] {
        Self.makeSegments(words: transcript.words, findings: report.findings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SonoraPageHeader(title: "Session Feedback", subtitle: dateText)
                videoSection
                transcriptSection
                momentsSection
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
            .sonoraCard()
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
                }
                .frame(height: transcriptPaneHeight)
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
                Text(Self.timestamp(segment.start))
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
                            SonoraTag(text: Self.timestamp(finding.start))
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
                                    SonoraTag(text: Self.timestamp(finding.start))
                                    Text(finding.message)
                                        .font(.subheadline)
                                        .foregroundStyle(SonoraColor.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(SonoraColor.textSecondary)
                                }
                                .sonoraCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: momentsPaneHeight)
            }
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

    /// Selects the transcript segment a finding falls in and seeks the video to it.
    private func selectMoment(_ finding: Finding) {
        guard let segment = segments.first(where: {
            finding.start >= $0.start && finding.start <= $0.end
        }) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedSegmentID = segment.id
        }
        seek(to: finding.start)
    }

    private func seek(to seconds: TimeInterval) {
        guard let player else { return }
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        player.play()
    }

    // MARK: - Helpers

    /// Illustrative recent-session filler counts for the Progress placeholder.
    private static let progressSample = [7, 6, 8, 5, 4]

    static func timestamp(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

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
