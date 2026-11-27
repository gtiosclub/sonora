//
//  MainTabView.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 11/12/26.
//

import SwiftUI

/// Signed-in root: the 4 tabs from the home page Figma
struct MainTabView: View {
    @Environment(AuthManager.self) private var auth
    @State private var tab = Tab.home

    enum Tab: String, CaseIterable {
        case home = "Home", practice = "Practice", progress = "Progress", profile = "Profile"

        var icon: String {
            switch self {
            case .home: return "house"
            case .practice: return "scope"
            case .progress: return "chart.bar"
            case .profile: return "person"
            }
        }
    }

    var body: some View {
        Group {
            switch tab {
            case .home:
                NavigationStack { HomeView() }
            case .practice:
                ContentView() // existing practice + test links screen
            case .progress:
                NavigationStack { SpeakingProgressView(viewModel: SpeakingProgressViewModel()) }
            case .profile:
                NavigationStack {
                    ProfileView(viewModel: ProfileViewModel(profile: exampleUserProfile, streak: auth.currentUser?.streak ?? 0))
                }
            }
        }
        .safeAreaInset(edge: .bottom) { tabBar }
    }

    private var tabBar: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { item in
                Button { tab = item } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.title2)
                            .frame(height: 28)
                        Text(item.rawValue)
                            .font(.caption)
                    }
                    .foregroundStyle(tab == item ? HomeColor.olive : HomeColor.inactive)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(hex: 0xF4F2EC), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(HomeColor.border.opacity(0.6)))
        .padding(.horizontal, 14)
    }
}
