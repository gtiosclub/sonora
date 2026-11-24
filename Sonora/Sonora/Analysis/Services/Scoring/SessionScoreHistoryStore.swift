import FirebaseFirestore

struct SessionScoreHistoryStore {
    func history(forUserID userID: String) async throws -> [SessionSkillScore] {
        let snapshot = try await Firestore.firestore()
            .collection("Sessions")
            .whereField("participants", arrayContains: userID)
            .whereField("status", isEqualTo: Session.Status.completed.rawValue)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? decodeSession($0) }
            .sorted { $0.createdAt < $1.createdAt }
            .compactMap { $0.sessionSkillScore }
    }
}

#if DEBUG
import SwiftUI

struct SessionScoreHistoryDebugView: View {
    let userID: String
    @State private var scores: [SessionSkillScore] = []

    var body: some View {
        List(scores) { Text(String(describing: $0)).font(.caption.monospaced()) }
            .task {
                scores = (try? await SessionScoreHistoryStore().history(forUserID: userID)) ?? []
                scores.forEach { print($0) }
            }
    }
}
#endif
