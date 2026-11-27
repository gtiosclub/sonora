//
//  SonoraDesign.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/10/26.
//

import SwiftUI

// MARK: - Palette additions

extension ProfilePalette {
    static let sectionFill = Color(red: 246 / 255, green: 241 / 255, blue: 214 / 255)
    static let chipRose    = Color(red: 240 / 255, green: 205 / 255, blue: 205 / 255)
    static let cardFill    = Color.white
}

// MARK: - Display model shared by "my profile" and "other user's profile"

struct ProfileDisplayData: Equatable {
    var userId: String? = nil
    var displayName: String
    var pronouns: String
    var initials: String
    var drills: String
    var sessions: String
    var friends: String
    var speakingTime: String
    var streak: String
    var bio: String
    var mastered: [String]
    var challenging: [String]
}

// MARK: - Top bar / buttons

struct SonoraTopBar<Leading: View, Trailing: View>: View {
    let title: String
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(ProfilePalette.deepPlum)
            HStack {
                leading
                Spacer()
                trailing
            }
        }
        .frame(minHeight: 48)
    }
}

/// Back chevron (or X) that dismisses the current screen.
struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    var systemImage = "chevron.left"

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(ProfilePalette.deepPlum)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(systemImage == "xmark" ? "Close" : "Back")
    }
}

/// Rounded-square outlined icon button (share / edit / bell / more in the Figma).
struct IconSquareButton: View {
    let systemImage: String
    let label: String
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(ProfilePalette.deepPlum)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 10).fill(ProfilePalette.cardFill))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(ProfilePalette.deepPlum.opacity(0.5), lineWidth: 1))
                .overlay(alignment: .topTrailing) {
                    if badge > 0 {
                        Text(badge > 9 ? "9+" : "\(badge)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Capsule().fill(ProfilePalette.brightOrange))
                            .offset(x: 6, y: -6)
                    }
                }
        }
        .accessibilityLabel(badge > 0 ? "\(label), \(badge) pending" : label)
    }
}

// MARK: - Avatars

/// Small circular avatar for list rows. Swap the Text for the mascot image once users can pick one.
struct SmallAvatar: View {
    let initials: String
    var size: CGFloat = 44

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
            .foregroundStyle(ProfilePalette.deepPlum)
            .frame(width: size, height: size)
            .background(Circle().fill(ProfilePalette.lavender.opacity(0.6)))
            .overlay(Circle().strokeBorder(ProfilePalette.deepPlum.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Profile pieces

struct StatColumn: View {
    let title: String
    let value: String
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityHint("Shows your \(title.lowercased())")
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 2) {
            Text(title).font(.subheadline)
            Text(value).font(.title2.weight(.bold))
        }
        .foregroundStyle(ProfilePalette.deepPlum)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct StatsStrip: View {
    let sessions: String
    let speakingTime: String
    let streak: String

    var body: some View {
        HStack(spacing: 0) {
            cell("mic", "Sessions", sessions, tint: ProfilePalette.deepPlum)
            Divider().frame(height: 44)
            cell("clock", "Speaking Time", speakingTime, tint: ProfilePalette.deepPlum)
            Divider().frame(height: 44)
            cell("flame", "Streak", streak, tint: ProfilePalette.brightOrange)
        }
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(ProfilePalette.lavender.opacity(0.25)))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .strokeBorder(ProfilePalette.deepPlum.opacity(0.4), lineWidth: 1))
    }

    private func cell(_ icon: String, _ label: String, _ value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title3).foregroundStyle(tint.opacity(0.7))
            Text(label).font(.caption).foregroundStyle(ProfilePalette.deepPlum)
            Text(value).font(.caption.weight(.bold)).foregroundStyle(ProfilePalette.deepPlum)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ProfilePalette.deepPlum)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TopicPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(ProfilePalette.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color))
    }
}

struct TopicCard: View {
    let title: String
    let items: [String]
    let chipColors: [Color]
    var onAdd: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.semibold))
            ChipFlowLayout(spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    TopicPill(text: item, color: chipColors[index % chipColors.count])
                }
                if let onAdd {
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ProfilePalette.secondaryText)
                            .frame(width: 30, height: 26)
                            .background(Capsule().fill(Color(.systemGray5)))
                    }
                    .accessibilityLabel("Add topic")
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 16).fill(ProfilePalette.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(ProfilePalette.lavender, lineWidth: 1))
    }
}

struct SpeakingProgressCard: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "chart.bar.fill").foregroundStyle(ProfilePalette.deepPlum)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Speaking Progress").font(.subheadline.weight(.bold))
                    Text("Explore your skills and performance over time.")
                        .font(.caption2)
                        .foregroundStyle(ProfilePalette.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            }
            Button(action: action) {
                Text("View My Progress →")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(ProfilePalette.calmGreen))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(ProfilePalette.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(ProfilePalette.lavender, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// MARK: - Shared profile body (used by my profile AND other users' profiles)

struct ProfileBody<Action: View>: View {
    let data: ProfileDisplayData
    var onFriendsTapped: (() -> Void)? = nil
    var onAddMastered: (() -> Void)? = nil
    var onAddChallenging: (() -> Void)? = nil
    var onViewProgress: (() -> Void)? = nil
    @ViewBuilder var action: Action

    private let masteredColors: [Color] = [
        ProfilePalette.lavender.opacity(0.45),
        ProfilePalette.calmGreen.opacity(0.3),
        ProfilePalette.lightApricot.opacity(0.5)
    ]

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                ProfileAvatar(initials: data.initials)
                Text(data.displayName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(ProfilePalette.deepPlum)
                    .padding(.top, 6)
                if !data.pronouns.isEmpty {
                    Text(data.pronouns)
                        .font(.subheadline)
                        .foregroundStyle(ProfilePalette.secondaryText)
                }
            }

            HStack(spacing: 0) {
                StatColumn(title: "Drills", value: data.drills)
                StatColumn(title: "Sessions", value: data.sessions)
                StatColumn(title: "Friends", value: data.friends, action: onFriendsTapped)
            }

            action

            StatsStrip(sessions: data.sessions, speakingTime: data.speakingTime, streak: data.streak)

            ProfileSection(title: "Bio:") {
                Text(data.bio.isEmpty ? "No bio yet." : data.bio)
                    .font(.footnote)
                    .foregroundStyle(data.bio.isEmpty ? ProfilePalette.secondaryText : ProfilePalette.primaryText)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(ProfilePalette.cardFill))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(ProfilePalette.lavender, lineWidth: 1))
            }

            ProfileSection(title: "Topic Progress:") {
                HStack(alignment: .top, spacing: 10) {
                    TopicCard(title: "Mastered Topics:", items: data.mastered,
                              chipColors: masteredColors, onAdd: onAddMastered)
                    TopicCard(title: "Challenging Topics:", items: data.challenging,
                              chipColors: [ProfilePalette.chipRose], onAdd: onAddChallenging)
                }
            }

            if let onViewProgress {
                SpeakingProgressCard(action: onViewProgress)
            }
        }
    }
}

// MARK: - Form field used by Edit Profile

struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ProfilePalette.deepPlum)
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(ProfilePalette.cardFill))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(ProfilePalette.deepPlum.opacity(0.35), lineWidth: 1))
        }
    }
}

// MARK: - Wrapping layout for topic chips

struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, usedWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            usedWidth = max(usedWidth, x - spacing)
        }
        return CGSize(width: usedWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
