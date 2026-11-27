//
//  DrillComponents.swift
//  Sonora
//
//  Created by Eshaan Dixit on 10/13/26.
//

import SwiftUI

// MARK: - Session row

struct SessionRow: View {
    let session: Session
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : session.mode.icon)
                .font(.system(size: 15))
                .foregroundStyle(isSelected ? SonoraColor.accent : SonoraColor.textSecondary)
                .frame(width: 34, height: 34)
                .background(isSelected ? SonoraColor.accentLight : SonoraColor.background, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayPrompt)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SonoraColor.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(session.detailLine)
                    .font(.footnote)
                    .foregroundStyle(SonoraColor.textSecondary)
                if let weakest = session.sessionSkillScore?.weakest {
                    SonoraTag(text: "Weakest: \(weakest.name)")
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .sonoraCard(highlighted: isSelected)
    }
}

// MARK: - Response mode picker

struct ResponseModePicker: View {
    @Binding var selection: DrillResponseMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DrillResponseMode.allCases) { mode in
                let isOn = mode == selection
                Button {
                    selection = mode
                } label: {
                    Label(mode.title, systemImage: mode.icon)
                        .font(.subheadline.weight(isOn ? .semibold : .regular))
                        .foregroundStyle(isOn ? SonoraColor.textPrimary : SonoraColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isOn {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(SonoraColor.card)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(SonoraColor.border))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(SonoraColor.track, in: RoundedRectangle(cornerRadius: 12))
    }
}
