//
//  SpeakingProgressView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/14/26.
//

//  VIEW: layout only. Pushed from ProfileView via "View My Progress".
//  Hosts the heatmap plus the latest session's skill bars.

import SwiftUI
import Combine

struct SpeakingProgressView: View {
    @StateObject private var viewModel: SpeakingProgressViewModel
    private let initials: String

    private let labelWidth: CGFloat = 76
    private let cellHeight: CGFloat = 34
    private let gap: CGFloat = 6
    private let progressGreen = Color(red: 138 / 255, green: 154 / 255, blue: 91 / 255)
    private let barText = Color(red: 99 / 255, green: 117 / 255, blue: 53 / 255)

    init(viewModel: SpeakingProgressViewModel, initials: String = "") {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.initials = initials
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SonoraTopBar(title: viewModel.title) {
                    BackButton()
                } trailing: {
                    if initials.isEmpty {
                        Color.clear.frame(width: 40, height: 40)
                    } else {
                        SmallAvatar(initials: String(initials.prefix(1)), size: 40)
                    }
                }

                heatMapCard
                sessionSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .fontDesign(.rounded)
        .foregroundStyle(ProfilePalette.primaryText)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedSession)
    }

    // MARK: - Heatmap

    private var heatMapCard: some View {
        let rows = viewModel.heatMapRows
        let columns = rows.first?.colors.count ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            Text("SKILL HEATMAP")
                .font(.footnote.weight(.heavy))
                .tracking(0.8)

            if rows.isEmpty {
                Text("Complete a session to see your progress here.")
                    .font(.subheadline)
                    .foregroundStyle(ProfilePalette.secondaryText)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    VStack(spacing: gap) {
                        ForEach(rows) { row in
                            Text(SpeakingProgressViewModel.heatMapLabel(row.name))
                                .font(.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .foregroundStyle(ProfilePalette.secondaryText)
                                .frame(width: labelWidth, height: cellHeight, alignment: .trailing)
                        }
                    }

                    VStack(spacing: gap) {
                        ForEach(rows) { row in
                            HStack(spacing: gap) {
                                ForEach(Array(row.colors.enumerated()), id: \.offset) { column, color in
                                    cell(color: color, row: row.name, column: column)
                                }
                            }
                        }
                    }
                }

                HStack(spacing: gap) {
                    ForEach(0..<columns, id: \.self) { index in
                        Text("\(index + 1)")
                            .font(.caption2.weight(viewModel.selectedSession == index ? .bold : .regular))
                            .foregroundStyle(ProfilePalette.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .contentShape(Rectangle())
                            .onTapGesture { viewModel.selectSession(index) }
                            .accessibilityLabel("Session \(index + 1)")
                            .accessibilityAddTraits(.isButton)
                    }
                }
                .padding(.leading, labelWidth + 8)

                Text("Sessions progress from oldest to newest.")
                    .font(.caption2)
                    .foregroundStyle(ProfilePalette.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(ProfilePalette.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(ProfilePalette.lavender, lineWidth: 1))
    }

    private func cell(color: RGBColor, row: String, column: Int) -> some View {
        let isSelected = viewModel.selectedSession == column
        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color(red: color.red, green: color.green, blue: color.blue))
            .frame(height: cellHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(ProfilePalette.deepPlum, lineWidth: isSelected ? 2 : 0)
            )
            .contentShape(Rectangle())
            .onTapGesture { viewModel.selectSession(column) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(SpeakingProgressViewModel.heatMapLabel(row)), session \(column + 1)")
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - Session selector + detail

    private var sessionSection: some View {
        let expanded = viewModel.selectedSession != nil

        return VStack(spacing: 0) {
            Button { viewModel.toggleSelector() } label: {
                HStack {
                    Text(viewModel.selectorTitle)
                        .font(.headline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .foregroundStyle(barText)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 14,
                                           bottomLeadingRadius: expanded ? 0 : 14,
                                           bottomTrailingRadius: expanded ? 0 : 14,
                                           topTrailingRadius: 14)
                        .fill(ProfilePalette.calmGreen.opacity(expanded ? 0.45 : 0.15))
                )
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 14,
                                           bottomLeadingRadius: expanded ? 0 : 14,
                                           bottomTrailingRadius: expanded ? 0 : 14,
                                           topTrailingRadius: 14)
                        .strokeBorder(progressGreen, lineWidth: 1)
                )
            }
            .disabled(!viewModel.hasSessions)
            .accessibilityHint(expanded ? "Collapses the session details" : "Shows your latest session")

            if let index = viewModel.selectedSession {
                detailCard(viewModel.skills(forSession: index))
            } else {
                placeholder
            }
        }
    }

    private func detailCard(_ skills: [SkillSummary]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                if index > 0 { Divider().padding(.horizontal, 16) }
                skillRow(skill)
            }
        }
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16,
                                   bottomTrailingRadius: 16, topTrailingRadius: 0)
                .fill(ProfilePalette.cardFill)
        )
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16,
                                   bottomTrailingRadius: 16, topTrailingRadius: 0)
                .strokeBorder(ProfilePalette.deepPlum.opacity(0.35), lineWidth: 1)
        )
    }

    private func skillRow(_ skill: SkillSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(SpeakingProgressViewModel.cardTitle(skill.name))
                    .font(.headline.weight(.regular))
                Spacer()
                Text(skill.scoreText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ProfilePalette.deepPlum)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule().fill(progressGreen)
                        .frame(width: proxy.size.width * skill.fraction)
                }
            }
            .frame(height: 6)
            Text(skill.tip)
                .font(.caption)
                .foregroundStyle(ProfilePalette.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityValue(skill.scoreText)
    }

    private var placeholder: some View {
        VStack(spacing: 14) {
            // "Hmm" pose already has the question mark baked into the artwork
            TuxelyImage(name: "Hmm")
                .frame(width: 130, height: 130)
                .accessibilityHidden(true)
            Text(viewModel.hasSessions ? "Tap a session to see how you did" : "No sessions yet")
                .font(.subheadline)
                .foregroundStyle(ProfilePalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 36)
    }
}

// MARK: - Mascot

/// Shows the Tuxely asset. If the asset is missing or misnamed it shows a bird symbol instead of
/// nothing, so you can tell the image didn't load. Asset name must be exactly "Tuxely".
struct TuxelyImage: View {
    var name = "Tuxely"

    var body: some View {
        if UIImage(named: name) != nil {
            Image(name).resizable().scaledToFit()
        } else {
            Image(systemName: "bird.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(ProfilePalette.lavender)
        }
    }
}

#Preview {
    NavigationStack {
        SpeakingProgressView(viewModel: SpeakingProgressViewModel(), initials: "BB")
    }
}
