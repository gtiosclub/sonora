//
//  DebateState.swift
//  Sonora
//
//  Created by Nidhi Nagumalla on 10/11/26.
//

import Foundation

struct DebateState{
    
    enum Phase {
        case userOpening
        case aiOpening
        case userRebuttal
        case aiRebuttal
        case userClosing
        case aiClosing
        
        var isUserTurn: Bool {
            switch self{
            case .userOpening, .userRebuttal, .userClosing:
                return true
            case .aiOpening, .aiRebuttal, .aiClosing:
                return false
            }
        }
        
        var durationSeconds: Int {
            switch self {
            case .userOpening, .aiOpening:
                return 120
            case .userRebuttal, .aiRebuttal:
                return 90
            case .userClosing, .aiClosing:
                return 60
            }
        }
        
        var displayName: String {
            switch self {
            case .userOpening:
                return "Your Opening"
            case .userRebuttal:
                return "Your Rebuttal"
            case .userClosing:
                return "Your Closing"
            case .aiOpening:
                return "AI Opening"
            case .aiRebuttal:
                return "AI Rebuttal"
            case .aiClosing:
                return "AI Closing"
            }
        }
    }
    
    enum Status{
        case notStarted
        case connecting
        case inProgress
        case judging
        case finished
        case error(String)
    }
    
    let topic: String
    let userSide: String
    let status: Status
    let phase: Phase
    let secondsRemaining: Int
    let isAISpeaking: Bool
}

