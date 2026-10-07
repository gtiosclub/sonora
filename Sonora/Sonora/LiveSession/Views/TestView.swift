//
//  TestView.swift
//  Sonora
//
//  Created by Shreeya Garg on 9/24/26.
//
import SwiftUI

struct TestView: View {
    var body: some View {
        VStack {
            Text("Testing View")
                .font(.title2.bold())
            Text("Add a button that calls your function so we can test it ")
            Button("Example", role: .destructive) {}
                .padding(.top, 8)
            NavigationLink("Debate Drill Test") { DebateDrillTestView() }
        }
        .padding()
    }
}
