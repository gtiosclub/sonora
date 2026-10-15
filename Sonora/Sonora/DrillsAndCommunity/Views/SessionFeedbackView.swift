//
//  SessionFeedbackView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/7/26.
//

import SwiftUI

struct SessionFeedbackView: View {
    @State private var viewModel: SessionFeedbackViewModel

    init(viewModel: SessionFeedbackViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                overallCard

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Session summary")
                    summaryCard
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Skill breakdown")
                    skillCard
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Moments to review")
                    momentsCard
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Progress")
                    progressCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) { recommendationsButton }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Session feedback")
                .font(.largeTitle.weight(.bold))
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
    }

    private var overallCard: some View {
        FeedbackCard {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    CardLabel(text: "OVERALL")
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(viewModel.overallScoreText)
                            .font(.system(size: 46, weight: .heavy))
                        Text(" / 100")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let delta = viewModel.deltaText {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(delta)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(viewModel.deltaIsPositive ? Color.sonoraBlue : Color.sonoraOrangeText)
                        Text("from your last interview")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        FeedbackCard {
            VStack(alignment: .leading, spacing: 10) {
                CardLabel(text: "FEEDBACK")
                Text(viewModel.summary)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 8) {
                    SummaryTag(style: .strength, text: viewModel.strength)
                    SummaryTag(style: .focus, text: viewModel.focusArea)
                }
                .padding(.top, 4)
            }
        }
    }

    private var skillCard: some View {
        FeedbackCard {
            VStack(spacing: 18) {
                SkillBar(title: "Pace",
                         valueText: viewModel.paceText,
                         fraction: viewModel.paceFraction)
                SkillBar(title: "Voice modulation",
                         valueText: viewModel.voiceLabel,
                         fraction: viewModel.voiceFraction,
                         color: viewModel.voiceNeedsWork ? .sonoraOrange : .sonoraBlue,
                         valueColor: viewModel.voiceNeedsWork ? .sonoraOrangeText : .sonoraBlue)
                SkillBar(title: "Body posture",
                         valueText: viewModel.postureText,
                         fraction: viewModel.postureFraction)
            }
        }
    }

    private var momentsCard: some View {
        FeedbackCard {
            VStack(alignment: .leading, spacing: 12) {
                CardLabel(text: "TIMELINE")
                MomentsTimeline(duration: viewModel.durationSeconds,
                                moment: viewModel.featuredMoment)
                if let moment = viewModel.featuredMoment {
                    HStack(spacing: 10) {
                        Text(viewModel.timestamp(for: moment))
                            .font(.subheadline.weight(.bold))
                        Text(moment.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Button("Review moment") {
                        viewModel.reviewTapped(moment)
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.sonoraBlue)
                }
            }
        }
    }

    private var progressCard: some View {
        FeedbackCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    CardLabel(text: viewModel.progressLabel)
                    Spacer()
                }
                if let progress = viewModel.progressText {
                    Text(progress)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.sonoraBlue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Sparkline(values: viewModel.recentScores)
                    .frame(height: 70)
            }
        }
    }

    private var recommendationsButton: some View {
        Button {
            viewModel.seeRecommendationsTapped()
        } label: {
            Text("See AI recommendations")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Color.sonoraBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    SessionFeedbackView(
        viewModel: SessionFeedbackViewModel(
            session: exampleSession,
            feedback: exampleFeedback
        )
    )
}
