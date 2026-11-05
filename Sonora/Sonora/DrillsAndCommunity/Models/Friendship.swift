//
//  Friendship.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/27/26.
//

import Foundation
import FirebaseFirestore

enum FriendshipStatus: String, Codable {
    case pending, accepted, blocked
}

struct Friendship: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let requesterId: String
    let receiverId: String
    let participants: [String]
    var status: FriendshipStatus
    var blockedBy: String?
    var createdAt: Date?
    var updatedAt: Date?

    /// The other person in the friendship, from the current user's point of view.
    func otherUserId(for currentUserId: String) -> String? {
        participants.first { $0 != currentUserId }
    }

    /// True when the current user has an incoming request they can accept.
    func isIncomingRequest(for currentUserId: String) -> Bool {
        status == .pending && receiverId == currentUserId
    }
}
