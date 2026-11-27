//
//  FriendshipServicing.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/14/26.
//

import Foundation

enum FriendRelationship: Equatable {
    case none            // not friends, nothing pending
    case requestSent     // I sent them a request
    case requestReceived // they sent me a request
    case friends
}

struct FriendSummary: Identifiable, Hashable {
    let id: String          // userId
    let username: String
    let displayName: String

    var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? String(username.prefix(1)).uppercased() : letters.uppercased()
    }
}

protocol FriendshipServicing {
    // Other users
    func publicProfile(userId: String) async throws -> ProfileDisplayData
    func status(with userId: String) async throws -> FriendRelationship

    // Actions
    func sendRequest(to userId: String) async throws
    func cancelRequest(to userId: String) async throws
    func acceptRequest(from userId: String) async throws
    func declineRequest(from userId: String) async throws
    func removeFriend(_ userId: String) async throws

    // Lists
    func friends() async throws -> [FriendSummary]
    func incomingRequests() async throws -> [FriendSummary]
    func outgoingRequests() async throws -> [FriendSummary]
}

// MARK: - Mock (previews / offline dev)
//
// Stateful in-memory fake. Every user has their own profile, looked up by ID, and
// friends / incoming / outgoing are real state, so tapping Add friend, Accept, Cancel,
// Decline or Remove actually moves people between lists.
// Create ONE instance and share it (e.g. @State in ContentView), or state resets.

enum MockFriendshipError: LocalizedError {
    case userNotFound
    var errorDescription: String? { "That user couldn't be found." }
}

actor MockFriendshipService: FriendshipServicing {
    private struct MockUser {
        let username: String
        let profile: ProfileDisplayData
    }

    private let users: [String: MockUser]
    private var friendIds: Set<String>
    private var incomingIds: Set<String>   // they sent ME a request
    private var outgoingIds: Set<String>   // I sent THEM a request

    /// Defaults: Joe is a friend, Ada sent you a request, you requested Sam, Maya is a stranger.
    init(friends: Set<String> = ["1"], incoming: Set<String> = ["2"], outgoing: Set<String> = ["3"]) {
        users = Self.makeUsers()
        friendIds = friends
        incomingIds = incoming
        outgoingIds = outgoing
    }

    // MARK: Other users

    func publicProfile(userId: String) async throws -> ProfileDisplayData {
        guard let user = users[userId] else { throw MockFriendshipError.userNotFound }
        return user.profile
    }

    func status(with userId: String) async throws -> FriendRelationship {
        if friendIds.contains(userId) { return .friends }
        if incomingIds.contains(userId) { return .requestReceived }
        if outgoingIds.contains(userId) { return .requestSent }
        return .none
    }

    // MARK: Actions

    func sendRequest(to userId: String) async throws {
        guard users[userId] != nil else { throw MockFriendshipError.userNotFound }
        outgoingIds.insert(userId)
    }

    func cancelRequest(to userId: String) async throws {
        outgoingIds.remove(userId)
    }

    func acceptRequest(from userId: String) async throws {
        guard incomingIds.remove(userId) != nil else { return }
        friendIds.insert(userId)
    }

    func declineRequest(from userId: String) async throws {
        incomingIds.remove(userId)
    }

    func removeFriend(_ userId: String) async throws {
        friendIds.remove(userId)
    }

    // MARK: Lists

    func friends() async throws -> [FriendSummary] { summaries(for: friendIds) }
    func incomingRequests() async throws -> [FriendSummary] { summaries(for: incomingIds) }
    func outgoingRequests() async throws -> [FriendSummary] { summaries(for: outgoingIds) }

    private func summaries(for ids: Set<String>) -> [FriendSummary] {
        ids.compactMap { id in
            users[id].map {
                FriendSummary(id: id, username: $0.username, displayName: $0.profile.displayName)
            }
        }
        .sorted { $0.displayName < $1.displayName }
    }

    // MARK: Sample people

    private static func makeUsers() -> [String: MockUser] {
        func user(_ id: String, _ username: String, _ name: String, _ pronouns: String,
                  drills: String, sessions: String, friends: String, time: String, streak: String,
                  bio: String, mastered: [String], challenging: [String]) -> (String, MockUser) {
            let initials = FriendSummary(id: id, username: username, displayName: name).initials
            return (id, MockUser(username: username, profile: ProfileDisplayData(
                userId: id, displayName: name, pronouns: pronouns, initials: initials,
                drills: drills, sessions: sessions, friends: friends,
                speakingTime: time, streak: streak, bio: bio,
                mastered: mastered, challenging: challenging)))
        }

        return Dictionary(uniqueKeysWithValues: [
            user("1", "joeshmow", "Joe Shmow", "Ze/Zir",
                 drills: "12", sessions: "40", friends: "90", time: "3.5h", streak: "5 Days",
                 bio: "I eat a lot of food and I like to talk a lot. Please be friends with me.",
                 mastered: ["Fluency", "Clarity", "Engaging"], challenging: ["Confidence"]),
            user("2", "ada", "Ada Lovelace", "She/Her",
                 drills: "30", sessions: "58", friends: "12", time: "9.2h", streak: "21 Days",
                 bio: "Poetical science enthusiast. Practicing keynote talks about machines.",
                 mastered: ["Content", "Clarity"], challenging: ["Confidence", "Engaging"]),
            user("3", "sam_t", "Sam Torres", "He/Him",
                 drills: "4", sessions: "9", friends: "7", time: "45m", streak: "2 Days",
                 bio: "Prepping for my first conference talk. Be nice!",
                 mastered: ["Fluency"], challenging: ["Content"]),
            user("4", "maya_p", "Maya Patel", "She/Her",
                 drills: "18", sessions: "27", friends: "33", time: "5.1h", streak: "9 Days",
                 bio: "Debate club captain. Always up for a speaking buddy.",
                 mastered: ["Engaging", "Confidence"], challenging: ["Clarity"])
        ])
    }
}
