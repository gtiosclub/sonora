//
//  SonoraStyle.swift
//  Sonora
//
//  Created by Eshaan Dixit on 10/13/26.
//

import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    init(light: UInt, dark: UInt) {
        self.init(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

enum SonoraColor {
    static let background = Color(light: 0xF6F7F9, dark: 0x000000)
    static let card = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let border = Color(light: 0xE5E7EB, dark: 0x38383A)
    static let track = Color(light: 0xECEEF2, dark: 0x2C2C2E)
    static let textPrimary = Color(light: 0x111827, dark: 0xF2F2F7)
    static let textSecondary = Color(light: 0x6B7280, dark: 0x9CA3AF)
    static let accent = Color(light: 0x3B63E2, dark: 0x5B82F0)
    static let accentLight = Color(light: 0xEAEFFD, dark: 0x1E2A4A)
    static let warning = Color(light: 0xE89B3C, dark: 0xE89B3C)
    static let warningText = Color(light: 0xB4610A, dark: 0xF0B45C)
    static let warningLight = Color(light: 0xFDF3E3, dark: 0x3A2A12)
}

struct SonoraCard: ViewModifier {
    var highlighted = false

    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SonoraColor.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(highlighted ? SonoraColor.accent : SonoraColor.border, lineWidth: highlighted ? 1.5 : 1)
            )
    }
}

extension View {
    func sonoraCard(highlighted: Bool = false) -> some View {
        modifier(SonoraCard(highlighted: highlighted))
    }
}

struct SonoraPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(SonoraColor.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(SonoraColor.textSecondary)
        }
        .padding(.top, 4)
        .padding(.bottom, 20)
    }
}

struct SonoraSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 19, weight: .bold))
            .foregroundStyle(SonoraColor.textPrimary)
            .padding(.top, 8)
            .padding(.bottom, 10)
    }
}

struct SonoraPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(SonoraColor.accent.opacity(configuration.isPressed ? 0.85 : 1), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct SonoraTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(SonoraColor.warningText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(SonoraColor.warningLight, in: RoundedRectangle(cornerRadius: 6))
    }
}

struct SonoraSkillBar: View {
    let name: String
    let score: Int
    var isWeak = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SonoraColor.textPrimary)
                Spacer()
                Text(isWeak ? "Needs work" : "\(score)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isWeak ? SonoraColor.warningText : SonoraColor.accent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SonoraColor.track)
                    Capsule()
                        .fill(isWeak ? SonoraColor.warning : SonoraColor.accent)
                        .frame(width: geo.size.width * CGFloat(min(max(score, 0), 100)) / 100)
                }
            }
            .frame(height: 6)
        }
    }
}
