//
//  WaitingView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//


import SwiftUI

//Screen 2: Waiting 
struct WaitingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppLayout {
            VStack(spacing: 20) {

                Text("Searching...")
                    .font(.title2)
                    .bold()

                // Placeholder for searching animation
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))

                    ProgressView()
                        .scaleEffect(1.5)
                }
                .frame(height: 230)

                Text("Estimated wait time: 2 mins")
                    .font(.caption)
                    .foregroundColor(.gray)

                OutlinedCard {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")

                        Text("Tip: Speak slightly slower than you think you need to!")
                            .font(.caption)
                    }
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray)
                        )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        WaitingView()
    }
}


