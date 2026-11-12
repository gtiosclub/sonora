//
//  HomeViewModel.swift
//  Sonora
//
//  Created by Sruthi Vangavolu on 11/12/26.
//

import FirebaseFirestore
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var progress: UserProgress?
    private(set) var skillProfile: SkillProfile?
    private(set) var recentSession: Session?

    func load(userId: String) async {
        async let progress = try? UserProgressService.fetch(for: userId)
        // Old SkillProfile docs may not decode; fall back to the sign-up defaults (same as UserProgressService)
        async let skillProfile = (try? SkillProfileService.fetch(for: userId)) ?? SkillProfile.makeNew(userId: userId)
        async let recentSession = try? Self.fetchRecentSession(userId: userId)
        (self.progress, self.skillProfile, self.recentSession) = await (progress, skillProfile, recentSession)
    }

    /// The two lowest-scoring skills, for the "Skills" card
    var weakestSkills: [(name: String, score: Int)] {
        guard let p = skillProfile else { return [] }
        let skills = [("Content", p.content.score), ("Clarity", p.clarity.score),
                      ("Confidence", p.confidence.score), ("Engagement", p.engaging.score)]
        return Array(skills.sorted { $0.1 < $1.1 }.prefix(2))
    }

    /// The user's latest completed session
    private static func fetchRecentSession(userId: String) async throws -> Session? {
        let snapshot = try await Firestore.firestore().collection("Sessions")
            .whereField("participants", arrayContains: userId)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Session.self) }
            .filter { $0.status == .completed }
            .max { ($0.startTime ?? $0.createdAt) < ($1.startTime ?? $1.createdAt) }
    }
}
