//
//  DrillTheme.swift
//  Sonora
//
//  Created by Eshaan Dixit on 11/28/26.
//

import SwiftUI

// Styling for the drill screens, matching the home page (HomeColor, white
// bordered cards, purple headings, Tuxley). Kept separate from SonoraStyle,
// which the Analysis transcript screen still uses.

extension View {
    /// White rounded card with the home page's soft border. Selected cards get a purple outline.
    func drillCard(selected: Bool = false) -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? HomeColor.purple : HomeColor.border, lineWidth: selected ? 2 : 1)
            )
    }
}

/// Section title, same as the home page's "Quick start" / "Recent session".
struct DrillSectionHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(HomeColor.text)
            .padding(.bottom, 2)
    }
}

/// Lavender banner with Tuxley, like the home page's practice banner.
struct DrillBanner: View {
    let mood: TuxleyMood
    let title: String
    let message: String
    /// Optional small pill under the message, e.g. "2 min".
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            Tuxley(mood: mood)
                .frame(width: 64, height: 76)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                if let badge {
                    DrillPill(text: badge, color: HomeColor.olive)
                        .padding(.top, 2)
                }
            }
            .foregroundStyle(HomeColor.purple)
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(HomeColor.lavender, in: RoundedRectangle(cornerRadius: 22))
    }
}

/// Small rounded pill, like the home page's stat pills.
struct DrillPill: View {
    let text: String
    var color: Color = HomeColor.yellow

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HomeColor.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color, in: Capsule())
    }
}

/// Full-width primary action in the app's purple.
struct DrillPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(HomeColor.purple.opacity(isEnabled ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Skill name, score and bar. The weakest skill uses the warm yellow, the strongest olive.
struct DrillSkillBar: View {
    let name: String
    let score: Int
    var isWeak = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HomeColor.text)
                Spacer()
                Text(isWeak ? "Needs work" : "\(score)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isWeak ? Color(hex: 0xB07A1A) : Color(hex: 0x6F7F3A))
            }
            HomeProgressBar(score: score, color: isWeak ? HomeColor.yellow : HomeColor.olive)
        }
    }
}

/// Top bar with the purple back chevron and centered title, like Speaking Progress.
struct DrillTopBar: View {
    let title: String

    var body: some View {
        SonoraTopBar(title: title) {
            BackButton()
        } trailing: {
            Color.clear.frame(width: 44, height: 44)
        }
    }
}
