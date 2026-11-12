//
//  XPService.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 11/5/26.
//

import FirebaseFirestore

/// Where a user is on the XP ladder. Tiers have 10 levels each.
struct XPLevel: Equatable {
    var tier: Int           // starts at 1
    var level: Int          // 1...10 within the tier
    var xpIntoLevel: Int    // progress toward the next level
    var xpForLevel: Int     // size of the current level
}

enum XPService {
    // Scores are stored 0-100; the XP formulas use a 0-10 scale
    private static let scoreScale = 10.0

    // A "full session" for tier sizing: average score 70, no improvement -> 50 * 7 = 350 XP
    static let typicalSessionXP = 350

    // MARK: XP equations

    /// Drill (1 score): 12.5 * (10 + improvement on that skill)
    static func drillXP(improvement: Int) -> Int {
        let xp = 12.5 * (10 + Double(improvement) / scoreScale)
        return max(0, Int(xp.rounded()))
    }

    static func drillXP(for drill: Drill) -> Int {
        drillXP(improvement: drill.improvement)
    }

    /// Session (4 scores): 50 * (avg of scores + avg improvement over all 4 scores)
    /// Improvement = session score minus the user's current SkillProfile score for that skill.
    static func sessionXP(scores: SessionSkillScore, previous: SkillProfile) -> Int {
        let pairs = [
            (scores.content.score, previous.content.score),
            (scores.engagement.score, previous.engaging.score),
            (scores.clarity.score, previous.clarity.score),
            (scores.confidence.score, previous.confidence.score)
        ]
        let avgScore = Double(pairs.map(\.0).reduce(0, +)) / 4 / scoreScale
        let avgImprovement = Double(pairs.map { $0.0 - $0.1 }.reduce(0, +)) / 4 / scoreScale

        let xp = 50 * (avgScore + avgImprovement)
        return max(0, Int(xp.rounded()))
    }

    // MARK: Tiers and levels

    /// Full sessions needed to clear each tier: 5, then 7.5, then 9.5, then +2 per tier after that
    static func sessionsToClear(tier: Int) -> Double {
        switch tier {
        case 1: return 5
        case 2: return 7.5
        case 3: return 9.5
        default: return 9.5 + 2 * Double(tier - 3)
        }
    }

    static func xpToClear(tier: Int) -> Int {
        Int((sessionsToClear(tier: tier) * Double(typicalSessionXP)).rounded())
    }

    static func level(for totalXP: Int) -> XPLevel {
        var remaining = max(0, totalXP)
        var tier = 1
        while remaining >= xpToClear(tier: tier) {
            remaining -= xpToClear(tier: tier)
            tier += 1
        }

        // 10 equal levels per tier
        let levelSize = xpToClear(tier: tier) / 10
        let levelIndex = min(remaining / levelSize, 9)
        return XPLevel(
            tier: tier,
            level: levelIndex + 1,
            xpIntoLevel: remaining - levelIndex * levelSize,
            xpForLevel: levelSize
        )
    }

    // MARK: Firebase (stored as an "xp" field on Users/{uid})

    private static var users: CollectionReference {
        Firestore.firestore().collection("Users")
    }

    /// Adds XP to the user's running total
    static func awardXP(_ amount: Int, to userId: String) async throws {
        guard amount > 0 else { return }
        try await users.document(userId).updateData(["xp": FieldValue.increment(Int64(amount))])
    }

    /// The user's total XP (0 if they haven't earned any yet)
    static func fetchXP(for userId: String) async throws -> Int {
        let snapshot = try await users.document(userId).getDocument()
        return snapshot.get("xp") as? Int ?? 0
    }
}
