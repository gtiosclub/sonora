//
//  AppLayout.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//



import SwiftUI

struct AppLayout<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            content
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
    }
}

// Reusable black button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.black)
                .cornerRadius(6)
        }
    }
}

// Reusable outlined box
struct OutlinedCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
}

