//
//  Friendship.swift
//  Sonora
//
//  Created by Yada Phongadulyasook on 10/22/26.
//

import Foundation

struct Friendship: Identifiable, Codable {
    let id: String
    let user1ID: String
    let user2ID: String
    let requestedByID: String
    let createdAt: Date
    var status: FriendshipStatus
}

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case blocked
}


func createFriendRequest(
    id: String,
    user1ID: String,
    user2ID: String
) -> Friendship? {
    guard user1ID != user2ID else {
        return nil
    }

    let isOrdered = user1ID < user2ID

    return Friendship(
        id: id,
        user1ID: isOrdered ? user1ID : user2ID,
        user2ID: isOrdered ? user2ID : user1ID,
        requestedByID: user1ID,
        createdAt: Date(),
        status: .pending
    )
}
