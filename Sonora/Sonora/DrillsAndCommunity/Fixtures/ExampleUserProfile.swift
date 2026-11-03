//
//  ExampleUserProfile.swift
//  Sonora
//
//  Created by Jocelyn Chen on 10/12/26.
//

//
//  ExampleUserProfile.swift
//  Sonora
//
//  Sample data for previews and testing.
//

import Foundation

let exampleUserProfile = UserProfile(
    id: "user1",
    fullName: "John Doe",
    username: "johndoe",
    email: "hello@gmail.com",
    phoneNumber: "111-111-1111",
    bio: "I love Webtoons",
    totalSessions: 24,
    totalSpeakingSeconds: 12_600,   // 3.5h
    masteredTopics: ["Conservacy", "Agriculture"],
    challengingTopics: ["AI and Technology", "GMOs"],
    modes: ["Debate", "Presentation"]
)
