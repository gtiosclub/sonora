//
//  SessionScoreMapper.swift
//  Sonora
//
//  Created by Dev Patel on 11/2/26.
//

import Foundation

struct SessionScoreMapper {

    /// Converts scores to SessionSkillScore
    func make(from scores: SessionScores, sessionID: String, userID: String) -> SessionSkillScore {
        SessionSkillScore(
            id: sessionID,
            userId: userID,
            content: makeSkill(score: scores.content ?? 0),
            engagement: makeSkill(score: scores.engagement),
            clarity: makeSkill(score: scores.clarity),
            confidence: makeSkill(score: scores.confidence)
        )
    }

    /// Builds a Skill with a new id and empty summary
    private func makeSkill(score: Int) -> Skill {
        Skill(id: UUID().uuidString, score: score, summary: "")
    }
}
