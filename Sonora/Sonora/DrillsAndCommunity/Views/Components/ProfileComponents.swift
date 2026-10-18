//
//  ProfileComponents.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/15/26.
//

import SwiftUI

// MARK: - Colors
extension Color {
    static let profileAccent = Color(red: 1.0, green: 0.478, blue: 0.122)
    static let profileAccentDark = Color(red: 0.84, green: 0.37, blue: 0.05)
    static let profilePeach = Color(red: 1.0, green: 0.78, blue: 0.69)
    static let profileBlue = Color(red: 0.208, green: 0.388, blue: 0.914)
}

// MARK: - Duolingo-style chunky button
struct ChunkyButtonStyle: ButtonStyle {
    var color: Color = .profileAccent
    var edge: Color = .profileAccentDark

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(color))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(edge)
                    .offset(y: pressed ? 0 : 4)
            )
            .offset(y: pressed ? 4 : 0)
            .padding(.bottom, 4)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

// MARK: - Card
struct ProfileCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(.systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(.systemGray5), lineWidth: 2)
            )
    }
}

// MARK: - Circle icon button (back button)
struct CircleIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(.secondarySystemBackground)))
        }
        .accessibilityLabel(label)
    }
}

// MARK: - Screen header
struct ScreenHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let onBack: (() -> Void)?
    private let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.weight(.bold))
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            trailing
        }
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, onBack: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, onBack: onBack) { EmptyView() }
    }
}

// MARK: - Avatar
struct ProfileAvatar: View {
    let initials: String
    var size: CGFloat = 160

    var body: some View {
        ZStack {
            Circle().fill(Color.profilePeach)
            Text(initials)
                .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Stat card
struct StatCard: View {
    let systemImage: String
    let tint: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(tint)
            Text(value)
                .font(.title2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemBackground)))
    }
}

// MARK: - Wrapping layout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
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
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Topic chips
struct TopicChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(.secondarySystemBackground)))
    }
}

struct TopicSection: View {
    let title: String
    let systemImage: String
    let tint: Color
    let items: [String]
    let addLabel: String
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title).font(.headline)
            } icon: {
                Image(systemName: systemImage).foregroundStyle(tint)
            }

            ProfileCard(padding: 12) {
                FlowLayout(spacing: 8) {
                    ForEach(items, id: \.self) { TopicChip(text: $0) }
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    }
                    .accessibilityLabel(addLabel)
                }
            }
        }
    }
}

// MARK: - "View My Progress" card
struct ProgressPromoCard: View {
    let action: () -> Void

    var body: some View {
        ProfileCard {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Speaking Progress").font(.headline)
                        Text("Explore your skills and performance over time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Button(action: action) {
                    HStack(spacing: 6) {
                        Text("View My Progress")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(ChunkyButtonStyle())
            }
        }
    }
}

// MARK: - Form field (Edit Profile)
struct FormFieldContainer<Content: View>: View {
    let label: String
    private let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            content
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemBackground)))
        }
    }
}

// MARK: - Skill row (Speaking Progress)
struct SkillProgressRow: View {
    let skill: SkillSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(skill.name).font(.subheadline.weight(.semibold))
                Spacer()
                Text(skill.scoreText).font(.footnote).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill))
                    Capsule()
                        .fill(Color.profileBlue)
                        .frame(width: geo.size.width * skill.fraction)
                }
            }
            .frame(height: 8)
            Text(skill.tip)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }
}
