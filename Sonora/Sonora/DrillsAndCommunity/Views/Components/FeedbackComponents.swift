//
//  FeedbackComponents.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/7/26.
//

import SwiftUI

// MARK: - Colors
extension Color {
    static let sonoraBlue = Color(red: 0.208, green: 0.388, blue: 0.914)
    static let sonoraBlueLight = Color(red: 0.655, green: 0.769, blue: 0.969)
    static let sonoraBlueMid = Color(red: 0.435, green: 0.627, blue: 0.949)
    static let sonoraOrange = Color(red: 0.91, green: 0.635, blue: 0.227)
    static let sonoraOrangeText = Color(red: 0.706, green: 0.373, blue: 0.024)
    static let sonoraYellow = Color(red: 0.961, green: 0.839, blue: 0.361)
    static let sonoraGreen = Color(red: 0.122, green: 0.541, blue: 0.357)
}

// MARK: - Card container
struct FeedbackCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
            )
    }
}

// MARK: - Section header
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.title3.weight(.bold))
            .padding(.horizontal, 8)
    }
}

// MARK: - Small caps label
struct CardLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Skill bar
struct SkillBar: View {
    let title: String
    let valueText: String
    let fraction: Double
    var color: Color = .sonoraBlue
    var valueColor: Color = .sonoraBlue

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(valueText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(valueColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * min(max(fraction, 0), 1))
                }
            }
            .frame(height: 7)
        }
    }
}

// MARK: - Summary tag (Strength / Focus on)
struct SummaryTag: View {
    enum Style { case strength, focus }

    let style: Style
    let text: String

    private var title: String { style == .strength ? "Strength" : "Focus on" }
    private var tint: Color { style == .strength ? .sonoraGreen : .sonoraOrangeText }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.bold))
                .foregroundStyle(tint)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Moments timeline
struct MomentsTimeline: View {
    let duration: Int
    let moment: ReviewMoment?

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let total = Double(max(duration, 1))
            let start = Double(moment?.startSeconds ?? 0) / total
            let end = Double(moment?.endSeconds ?? 0) / total

            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Rectangle().fill(Color.sonoraBlueLight)
                        .frame(width: width * start)
                    Rectangle().fill(Color.sonoraYellow)
                        .frame(width: width * max(end - start, 0))
                    Rectangle().fill(Color.sonoraBlueMid)
                }
                .frame(height: 11)
                .clipShape(Capsule())

                if moment != nil {
                    Circle()
                        .fill(Color.sonoraOrange)
                        .frame(width: 19, height: 19)
                        .overlay(Circle().stroke(Color(.secondarySystemGroupedBackground), lineWidth: 3))
                        .offset(x: width * start - 9.5)
                }
            }
            .frame(height: 19)
        }
        .frame(height: 19)
    }
}

// MARK: - Sparkline
struct Sparkline: View {
    let values: [Int]

    var body: some View {
        GeometryReader { geo in
            let points = normalizedPoints(in: geo.size)

            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: geo.size.height))
                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                }
                .stroke(Color(.separator).opacity(0.6), lineWidth: 1.5)

                Path { p in
                    guard let first = points.first else { return }
                    p.move(to: first)
                    points.dropFirst().forEach { p.addLine(to: $0) }
                }
                .stroke(Color.sonoraBlue,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                if let last = points.last {
                    Circle()
                        .fill(Color.sonoraBlue)
                        .frame(width: 11, height: 11)
                        .position(last)
                }
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard values.count > 1,
              let minV = values.min(), let maxV = values.max() else { return [] }
        let range = Double(max(maxV - minV, 1))
        let inset: CGFloat = 8
        let usableH = size.height - inset * 2
        let usableW = size.width - inset * 2
        return values.enumerated().map { index, value in
            let x = inset + usableW * CGFloat(index) / CGFloat(values.count - 1)
            let y = inset + usableH * (1 - CGFloat(Double(value - minV) / range))
            return CGPoint(x: x, y: y)
        }
    }
}
