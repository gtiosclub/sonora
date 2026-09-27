//
//  InterviewSessions.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 9/24/26.
//

import SwiftUI

@MainActor
enum InterviewSessions {
    static let interviewSession1 = Session {
        Session(id: "interview1",
                userId1: "user1",
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.ai,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 20,
                        hour: 17,
                        minute: 0
                    )
                )!,
                durationSeconds: 600)
    }
    
    static let interviewSession2 = Session {
        Session(id: "interview2",
                userId1: "user1",
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.ai,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 21,
                        hour: 18,
                        minute: 0
                    )
                )!,
                durationSeconds:700)
    }
    
    static let interviewSession3 = Session {
        Session(id: "interview3",
                userId1: "user1",
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.ai,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 22,
                        hour: 16,
                        minute: 0
                    )
                )!,
                durationSeconds: 500)
    }
    
    static let interviewSession4 = Session {
        Session(id: "interview4",
                userId1: "user1",
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.human,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 23,
                        hour: 20,
                        minute: 0
                    )
                )!,
                durationSeconds: 800)
    }
    
    static let interviewSession5 = Session {
        Session(id: "interview5",
                userId1: "user1",
                mode: Session.Mode.interview,
                opponentType: Session.OpponentType.human,
                startTime: Calendar(identifier: .gregorian).date(
                    from: DateComponents(
                        timeZone: .current,
                        year: 2026,
                        month: 8,
                        day: 24,
                        hour: 15,
                        minute: 0
                    )
                )!,
                durationSeconds: 900)
    }
}
