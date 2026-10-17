//
//  PairingSetupView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//



import SwiftUI

//Screen 1: Pairing Setup
struct PairingSetupView: View {
    @State private var practiceType = "Select"
    @State private var topic = ""
    @State private var sessionLength = 10

    let practiceTypes = [
        "Select",
        "Interview Practice",
        "Public Speaking",
        "Conversation Practice"
    ]

    let sessionLengths = [5, 10, 20, 30]

    var body: some View {
        NavigationStack {
            AppLayout {
                VStack(alignment: .leading, spacing: 20) {

                    Text("Live Video Pairing")
                        .font(.title2)
                        .bold()

                    // Practice type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRACTICE TYPE")
                            .font(.caption)

                        Picker("Practice Type", selection: $practiceType) {
                            ForEach(practiceTypes, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .tint(.black)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray)
                        )
                    }

                    // Topic
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TOPIC")
                            .font(.caption)

                        TextEditor(text: $topic)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray)
                            )
                    }

                    // Session length
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SESSION LENGTH")
                            .font(.caption)

                        HStack(spacing: 8) {
                            ForEach(sessionLengths, id: \.self) { length in
                                Button("\(length) mins") {
                                    sessionLength = length
                                }
                                .font(.caption)
                                .padding(10)
                                .foregroundColor(
                                    sessionLength == length ? .white : .black
                                )
                                .background(
                                    sessionLength == length ? Color.black : Color.white
                                )
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray)
                                )
                            }
                        }
                    }

                    Spacer()

                    NavigationLink {
                        WaitingView()
                    } label: {
                        Text("Find a match")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(6)
                    }
                }
            }
        }
    }
}

#Preview {
    PairingSetupView()
}
