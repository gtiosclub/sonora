//
//  SettingsView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/14/26.
//

import SwiftUI

enum SettingsRoute: Hashable, Identifiable {
    case editProfile, changePassword, email
    case privacyData, connectedApps
    case appNotifications

    var id: Self { self }

    var title: String {
        switch self {
        case .editProfile: "Edit Profile"
        case .changePassword: "Change Password"
        case .email: "Email"
        case .privacyData: "Privacy & Data"
        case .connectedApps: "Connected Apps"
        case .appNotifications: "App Notifications"
        }
    }
}

struct SettingsView: View {
    let initials: String
    let makeEditViewModel: () -> EditProfileViewModel

    @State private var route: SettingsRoute?

    private let sections: [(title: String, rows: [SettingsRoute])] = [
        ("Account", [.editProfile, .changePassword, .email]),
        ("Preferences", [.privacyData, .connectedApps]),
        ("Notifications", [.appNotifications])
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SonoraTopBar(title: "Settings") {
                    BackButton()
                } trailing: {
                    SmallAvatar(initials: String(initials.prefix(1)), size: 40)
                }

                ForEach(sections, id: \.title) { section in
                    VStack(spacing: 0) {
                        Text(section.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(ProfilePalette.deepPlum)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(ProfilePalette.sectionFill))
                            .padding(.bottom, 4)

                        ForEach(Array(section.rows.enumerated()), id: \.element) { index, row in
                            Button { route = row } label: {
                                HStack {
                                    Text(row.title).font(.footnote.weight(.medium))
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.footnote)
                                }
                                .foregroundStyle(ProfilePalette.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if index < section.rows.count - 1 {
                                Divider().padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .fontDesign(.rounded)
        .background(ProfilePalette.softBeige.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $route) { route in
            switch route {
            case .editProfile:
                EditProfileView(viewModel: makeEditViewModel())
            case .changePassword:
                ChangePasswordView()
            default:
                ComingSoonView(title: route.title)
            }
        }
    }
}

