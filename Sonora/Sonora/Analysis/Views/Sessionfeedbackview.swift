import SwiftUI

// MARK: - Model

struct SkillMetric: Identifiable {
    let id = UUID()
    let name: String
    let progress: Double          // 0...1, how full the bar is
    let valueLabel: String        // e.g. "146 WPM", "88%"
    let barColor: Color
    let labelColor: Color
}

struct TimelineSegment: Identifiable {
    let id = UUID()
    let start: Double             // 0...1
    let end: Double               // 0...1
    let color: Color
}

struct ReviewMoment {
    let timestamp: String         // e.g. "2:41"
    let message: String
    let position: Double          // 0...1 along the timeline
}

struct SessionFeedback {
    let sessionType: String
    let duration: String
    let overallScore: Int
    let pointsChange: Int
    let skills: [SkillMetric]
    let timeline: [TimelineSegment]
    let moment: ReviewMoment
    let recentScores: [Double]    // oldest -> newest
    let progressChange: Int       // percent
}

// MARK: - Theme

enum Theme {
    static let background   = Color(hex: 0xF7F8FA)
    static let card         = Color.white
    static let cardBorder   = Color(hex: 0xE3E6EC)
    static let textPrimary  = Color(hex: 0x1A2233)
    static let textSecondary = Color(hex: 0x6B7280)
    static let track        = Color(hex: 0xE6E8EC)

    static let blue         = Color(hex: 0x8AA4EC)
    static let blueDark     = Color(hex: 0x6E9BEA)
    static let blueLight    = Color(hex: 0xA9C8F2)
    static let orange       = Color(hex: 0xE8A33D)
    static let orangeText   = Color(hex: 0xB4581F)
    static let yellow       = Color(hex: 0xF2CF6B)
    static let cta          = Color(hex: 0xF0907E)
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Screen

struct SessionFeedbackView: View {
    let feedback: SessionFeedback
    var transcript: Transcript = Transcript(words: [])
    var report: AnalysisReport = SpeechReportBuilder().buildReport(from: Transcript(words: []))
    var videoURL: URL? = nil
    var onReviewMoment: () -> Void = {}
    @State private var showTranscript = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                overallCard

                section("Skill breakdown") { skillCard }
                section("Moments to review") { momentCard }
                section("Progress") { progressCard }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
        // Floating button: pinned above the home indicator, and the scroll
        // content insets itself so the last card is never hidden behind it.
        .safeAreaInset(edge: .bottom) {
            transcriptPlaybackButton
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(
                    LinearGradient(
                        colors: [Theme.background.opacity(0), Theme.background],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
        } .navigationDestination(isPresented: $showTranscript) {
            SessionTranscriptView(transcript: transcript, report: report, videoURL: videoURL)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Session feedback")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(feedback.sessionType) · \(feedback.duration)")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: Overall

    private var overallCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("OVERALL")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(feedback.overallScore)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("/100")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Label("\(feedback.pointsChange) points", systemImage: "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.blue)
                    .labelStyle(TightLabelStyle())
                Text("from your last\ninterview")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(20)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    // MARK: Skills

    private var skillCard: some View {
        VStack(spacing: 22) {
            ForEach(feedback.skills) { skill in
                VStack(spacing: 10) {
                    HStack {
                        Text(skill.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(skill.valueLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(skill.labelColor)
                    }
                    ProgressBar(progress: skill.progress, color: skill.barColor)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(20)
        .cardStyle()
    }

    // MARK: Moments

    private var momentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TIMELINE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)

            TimelineBar(segments: feedback.timeline, markerPosition: feedback.moment.position)
                .frame(height: 16)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(feedback.moment.timestamp)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(feedback.moment.message)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }

            Button("Review moment", action: onReviewMoment)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.blue)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: Progress

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAST \(feedback.recentScores.count) SESSIONS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            Sparkline(values: feedback.recentScores, changeLabel: "+\(feedback.progressChange)%")
                .frame(height: 64)
        }
        .padding(20)
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress over last \(feedback.recentScores.count) sessions, up \(feedback.progressChange) percent")
    }

    // MARK: Buttons

    private var transcriptPlaybackButton: some View {
        Button { showTranscript = true } label: {
            Text("See transcript playback")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.white)
                .background(Theme.cta)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Theme.cta.opacity(0.35), radius: 12, y: 4)
        }
    }

    // MARK: Helpers

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            content()
        }
    }
}

// MARK: - Components

struct ProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 7)
    }
}

struct TimelineBar: View {
    let segments: [TimelineSegment]
    let markerPosition: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .leading) {
                ForEach(segments) { seg in
                    Capsule()
                        .fill(seg.color)
                        .frame(width: max((seg.end - seg.start) * w, 0), height: 8)
                        .offset(x: seg.start * w)
                }
                Circle()
                    .fill(Theme.orange)
                    .overlay(Circle().stroke(Theme.card, lineWidth: 2))
                    .frame(width: h, height: h)
                    .offset(x: markerPosition * w - h / 2)
            }
            .frame(height: h)
        }
    }
}

struct SparklineShape: Shape {
    let values: [Double]

    func points(in rect: CGRect) -> [CGPoint] {
        guard values.count > 1, let lo = values.min(), let hi = values.max() else { return [] }
        let range = max(hi - lo, 1)
        let step = rect.width / CGFloat(values.count - 1)
        return values.enumerated().map { i, v in
            CGPoint(x: CGFloat(i) * step,
                    y: rect.height - CGFloat((v - lo) / range) * rect.height)
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pts = points(in: rect)
        guard let first = pts.first else { return path }
        path.move(to: first)
        for p in pts.dropFirst() { path.addLine(to: p) }
        return path
    }
}

struct Sparkline: View {
    let values: [Double]
    let changeLabel: String

    var body: some View {
        GeometryReader { geo in
            // Leave room at the bottom for the baseline, at the top for the dot
            let rect = CGRect(x: 0, y: 6, width: geo.size.width, height: geo.size.height - 16)
            let shape = SparklineShape(values: values)
            let last = shape.points(in: rect).last ?? .zero

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Theme.track)
                    .frame(height: 1)
                    .offset(y: geo.size.height - 1)

                shape.path(in: rect)
                    .stroke(Theme.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                Circle()
                    .fill(Theme.blue)
                    .frame(width: 9, height: 9)
                    .position(last)

                Text(changeLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.blue)
                    .fixedSize()
                    .position(x: last.x - 14, y: last.y + 16)
            }
        }
    }
}

struct TightLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.font(.system(size: 11, weight: .bold))
            configuration.title
        }
    }
}

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}

// MARK: - Sample data + Preview

extension SessionFeedback {
    static let sample = SessionFeedback(
        sessionType: "Interview",
        duration: "6 min 42 sec",
        overallScore: 84,
        pointsChange: 8,
        skills: [
            SkillMetric(name: "Pace", progress: 0.76, valueLabel: "146 WPM",
                        barColor: Theme.blue, labelColor: Theme.blue),
            SkillMetric(name: "Voice modulation", progress: 0.57, valueLabel: "Needs variety",
                        barColor: Theme.orange, labelColor: Theme.orangeText),
            SkillMetric(name: "Body posture", progress: 0.88, valueLabel: "88%",
                        barColor: Theme.blue, labelColor: Theme.blue)
        ],
        timeline: [
            TimelineSegment(start: 0.00, end: 0.40, color: Theme.blueLight),
            TimelineSegment(start: 0.36, end: 0.64, color: Theme.yellow),
            TimelineSegment(start: 0.60, end: 1.00, color: Theme.blueDark)
        ],
        moment: ReviewMoment(timestamp: "2:41",
                             message: "You sped up while giving your example.",
                             position: 0.42),
        recentScores: [62, 66, 65, 72, 70, 78, 84].suffix(6).map { $0 },
        progressChange: 15
    )
}

#Preview {
    SessionFeedbackView(feedback: .sample)
}
