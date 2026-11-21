//
//  DebateState.swift
//  Sonora
//
//  Created by Nidhi Nagumalla on 10/11/26.
//

import Foundation

struct DebateState{
    
    enum Phase: CaseIterable, Equatable {
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
    
    enum Status: Equatable{
        case notStarted
        case connecting
        case inProgress
        case judging
        case finished
        case error(String)
    }
    
    var topic: String
    var userSide: String
    var status: Status
    var phase: Phase
    var secondsRemaining: Int
    var isAISpeaking: Bool
    
    // Allows DebateState to progress and move to the next round
    mutating func advance() {
        let all = Phase.allCases
        guard let currentIndex = all.firstIndex(of: phase) else {
            return
        }
        let nextIndex = currentIndex + 1;
        
        if all.indices.contains(nextIndex) {
            phase = all[nextIndex]
            secondsRemaining = phase.durationSeconds
        } else {
            status = .judging
        }
    }
}

