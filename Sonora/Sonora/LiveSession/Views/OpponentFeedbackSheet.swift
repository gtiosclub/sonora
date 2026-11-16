import SwiftUI

struct OpponentFeedbackSheet: View {
    let sessionId: String
    let raterId: String
    let opponentName: String
    var onFinish: () -> Void

    @State private var rating = 0
    @State private var selectedTags: Set<String> = []
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let tagOptions = ["Good sport", "Challenging", "Respectful", "Strong arguments", "Would debate again"]

    var body: some View {
        NavigationStack {
            Form {
                Section("How was debating \(opponentName)?") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                                .onTapGesture { rating = star }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Section("Tags (optional)") {
                    ForEach(tagOptions, id: \.self) { tag in
                        Button {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        } label: {
                            HStack {
                                Text(tag)
                                Spacer()
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Comments (optional)") {
                    TextField("Anything else?", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Opponent Feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip", action: onFinish)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { Task { await submit() } }
                        .disabled(rating == 0 || isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            // Defined in OpponentFeedbackService.swift
            try await submitOpponentFeedback(
                userId: raterId,
                sessionID: sessionId,
                rating: rating,
                tags: Array(selectedTags).sorted(),
                comment: comment
            )
            onFinish()
        } catch {
            errorMessage = "Couldn't save feedback. Please try again."
        }
    }
}
