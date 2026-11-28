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
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: isSelected ? "checkmark" : session.mode.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? .white : HomeColor.purple)
                .frame(width: 38, height: 38)
                .background(isSelected ? HomeColor.purple : Color(hex: 0xEDEBF8), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayPrompt)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(HomeColor.purple)
                    .multilineTextAlignment(.leading)
                Text(session.detailLine)
                    .font(.caption)
                    .foregroundStyle(HomeColor.inactive)
                if let weakest = session.sessionSkillScore?.weakest {
                    DrillPill(text: "Weakest: \(weakest.name)")
                        .padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
        }
        .drillCard(selected: isSelected)
    }
}

// MARK: - Response mode picker

struct ResponseModePicker: View {
    @Binding var selection: DrillResponseMode

    var body: some View {
        ThemedSegmentedPicker(options: DrillResponseMode.allCases, selection: $selection) { mode in
            Label(mode.title, systemImage: mode.icon)
        }
    }
}

/// Segmented toggle styled like the tab bar: beige track, white selected segment.
struct ThemedSegmentedPicker<Option: Hashable, LabelView: View>: View {
    let options: [Option]
    @Binding var selection: Option
    @ViewBuilder let label: (Option) -> LabelView

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isOn = option == selection
                Button {
                    selection = option
                } label: {
                    label(option)
                        .font(.system(size: 15, weight: isOn ? .bold : .regular))
                        .foregroundStyle(isOn ? HomeColor.purple : HomeColor.inactive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background {
                            if isOn {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(HomeColor.border))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(hex: 0xF4F2EC), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HomeColor.border.opacity(0.6)))
    }
}
