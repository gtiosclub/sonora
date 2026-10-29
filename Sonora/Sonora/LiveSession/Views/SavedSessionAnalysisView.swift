//
//  SavedSessionAnalysisView.swift
//  Sonora
//
//  Created by Nidhi Nagumalla on 10/28/26.
//


import SwiftUI

struct SavedSessionAnalysisView: View {
    let session: Session

    @Environment(AuthManager.self) private var auth

    @State private var report: AnalysisReport?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading analysis...")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Unable to Load Analysis",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if let report {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Session Summary")
                            .font(.title2.bold())

                        Text(report.summary)

                        Text("Skill Scores")
                            .font(.title2.bold())

                        LabeledContent("Engagement", value: "\(report.scores.engagement)")
                        LabeledContent("Confidence", value: "\(report.scores.confidence)")
                        LabeledContent("Clarity", value: "\(report.scores.clarity)")
                        LabeledContent(
                            "Content",
                            value: report.scores.content.map(String.init) ?? "Not scored"
                        )

                        Text("Moments to Review")
                            .font(.title2.bold())

                        if report.findings.isEmpty {
                            Text("No timestamped feedback available.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(report.findings.indices, id: \.self) { index in
                                let finding = report.findings[index]

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("At \(Int(finding.start)) seconds")
                                        .font(.subheadline.bold())

                                    Text(finding.message)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "No Analysis Available",
                    systemImage: "chart.bar.xaxis",
                    description: Text("No saved feedback was found for this session.")
                )
            }
        }
        .navigationTitle("Session Analysis")
        .task {
            await loadFeedback()
        }
    }

    private func loadFeedback() async {
        guard let userID = auth.userID else {
            errorMessage = "You must be signed in to view feedback."
            isLoading = false
            return
        }

        do {
            report = try await SessionFeedbackService.fetchFeedback(
                sessionID: session.id,
                userID: userID
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
