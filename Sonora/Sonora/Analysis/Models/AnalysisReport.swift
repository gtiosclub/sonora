//
//  AnalysisReport.swift
//  Sonora
//
//  Created by Judy Hsu on 10/8/26.
//
import Foundation

struct AnalysisReport: Codable, Equatable {
    var scores: SessionScores
    var summary: String         // 3 sentences
    var metrics: [Metric]
    var findings: [Finding]     // sorted by start
}
