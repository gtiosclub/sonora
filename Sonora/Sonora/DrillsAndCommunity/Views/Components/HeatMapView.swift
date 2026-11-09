//
//  HeatMapView.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/1/26.
//

import SwiftUI

struct HeatMapView: View {
    @StateObject private var viewModel: HeatMapViewModel

    private let labelWidth: CGFloat = 80
    private let cellHeight: CGFloat = 36
    private let gap: CGFloat = 6
    private let cornerRadius: CGFloat = 6

    init(viewModel: HeatMapViewModel = HeatMapViewModel(sessionScores: exampleSessionScores)) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private func swiftUIColor(_ c: RGBColor) -> Color {
        Color(red: c.red, green: c.green, blue: c.blue)
    }

    var body: some View {
        let grid = viewModel.grid

        VStack(alignment: .leading, spacing: 12) {
            Picker("Metric", selection: $viewModel.metric) {
                ForEach(HeatMapMetric.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .top, spacing: 8) {
                // y-axis labels
                VStack(spacing: gap) {
                    ForEach(viewModel.skills, id: \.self) { skill in
                        Text(skill)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: labelWidth, height: cellHeight, alignment: .trailing)
                    }
                }

                // heatmap cells
                VStack(spacing: gap) {
                    ForEach(Array(grid.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: gap) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, color in
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(swiftUIColor(color))
                                    .frame(height: cellHeight)
                            }
                        }
                    }
                }
            }

            // x-axis labels
            HStack(spacing: gap) {
                ForEach(0..<viewModel.displayedSessions.count, id: \.self) { i in
                    Text("\(i + 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.leading, labelWidth + 8)

            Text("Sessions (oldest to newest)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            // legend
            HStack(spacing: 8) {
                Text(viewModel.legendLabels.low).font(.caption2).foregroundStyle(.secondary)
                LinearGradient(
                    colors: [swiftUIColor(viewModel.lowestColor), swiftUIColor(viewModel.highestColor)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 8)
                .clipShape(Capsule())
                Text(viewModel.legendLabels.high).font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.leading, labelWidth + 8)
        }
        .padding()
    }
}

#Preview {
    HeatMapView()
}
