//
//  SpeakingProgressView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/14/26.
//

//  VIEW: layout only. Pushed from ProfileView via "View My Progress".
//  Hosts the heatmap plus the latest session's skill bars.

import SwiftUI

struct SpeakingProgressView: View {
    @StateObject private var viewModel: SpeakingProgressViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SpeakingProgressViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(title: viewModel.title,
                             subtitle: viewModel.subtitle,
                             onBack: { dismiss() })

                heatMapCard
                skillsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .fontDesign(.rounded)
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .navigationBar)
    }

    private var heatMapCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SKILL HEATMAP")
                .font(.footnote.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
                .padding(.top, 16)
                .padding(.horizontal, 16)

            HeatMapView(viewModel: viewModel.heatMapViewModel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemBackground)))
    }

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Latest session")
                .font(.title3.weight(.bold))

            ProfileCard {
                if viewModel.hasSessions {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.latestSkills.enumerated()), id: \.element.id) { index, skill in
                            if index > 0 { Divider() }
                            SkillProgressRow(skill: skill)
                        }
                    }
                } else {
                    Text("Complete a session to see your progress here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    SpeakingProgressView(viewModel: SpeakingProgressViewModel())
}
