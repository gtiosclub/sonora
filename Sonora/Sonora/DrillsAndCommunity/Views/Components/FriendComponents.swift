//
//  FriendComponents.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/15/26.
//

import SwiftUI

struct FriendActionButton: View {
    let status: FriendRelationship
    let isWorking: Bool
    let action: () -> Void

    private var title: String {
        switch status {
        case .none: "Add friend"
        case .requestSent: "Requested"
        case .requestReceived: "Accept request"
        case .friends: "Friended"
        }
    }

    private var icon: String {
        switch status {
        case .none: "person.badge.plus"
        case .requestSent: "clock"
        case .requestReceived: "person.badge.plus"
        case .friends: "person.crop.circle.badge.checkmark"
        }
    }

    private var isPrimary: Bool { status == .none || status == .requestReceived }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isPrimary ? Color.white : ProfilePalette.secondaryText)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(Capsule().fill(isPrimary ? ProfilePalette.calmGreen : Color(.systemGray6)))
                .overlay(Capsule().strokeBorder(
                    isPrimary ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1))
        }
        .disabled(isWorking || status == .friends)
        .opacity(isWorking ? 0.6 : 1)
    }
}
