//
//  SonoraApp.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/13/26.
//

import SwiftUI
import FirebaseCore

@main
struct SonoraApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
