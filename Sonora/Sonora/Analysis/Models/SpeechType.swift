//
//  SpeechType.swift
//  Sonora
//

import Foundation

/// The kind of session being scored. Drives the rubric's category weights and
/// the "good" pace band (debate speakers are allowed to go faster).
enum SpeechType: String, Codable, CaseIterable {
    case presentation
    case debate
    case interview

    /// Category weights (sum to 1) used for the overall score.
    var weights: CategoryWeights {
        switch self {
        case .presentation: CategoryWeights(clarity: 0.25, confidence: 0.25, engagement: 0.25, content: 0.25)
        case .debate:       CategoryWeights(clarity: 0.20, confidence: 0.20, engagement: 0.15, content: 0.45)
        case .interview:    CategoryWeights(clarity: 0.25, confidence: 0.30, engagement: 0.15, content: 0.30)
        }
    }

    /// The pace band (words per minute) that scores as "good". Debate is wider.
    var goodPace: ClosedRange<Double> {
        switch self {
        case .debate: 160...200
        default:      130...160
        }
    }
}

struct CategoryWeights {
    let clarity: Double
    let confidence: Double
    let engagement: Double
    let content: Double
}
