//
//  RootView.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/24/26.
//

import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        if auth.isSignedIn {
            MainTabView()

        } else if auth.isLoading {
            ProgressView()
                .preferredColorScheme(.light)
        } else {
            LoginView()
        }
    }
}


