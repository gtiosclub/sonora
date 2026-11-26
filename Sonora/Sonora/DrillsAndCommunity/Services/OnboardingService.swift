//
//  OnboardingService.swift
//  Sonora
//
//  Created by Jocelyn Chen on 11/26/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class OnboardingService {
    // ⚠️ Keep in sync with UserSearchService / FirestoreProfileRepository.
    private static let usersCollection = "users"
    // One tiny document per username, so two people can't claim the same one.
    private static let usernamesCollection = "usernames"

    private lazy var db = Firestore.firestore()

    var currentUserId: String? { Auth.auth().currentUser?.uid }

    /// True once the user has a profile document. Use this to decide whether
    /// a signed-in user still needs to see onboarding.
    func hasProfile(uid: String) async -> Bool {
        let snapshot = try? await db.collection(Self.usersCollection).document(uid).getDocument()
        return snapshot?.exists ?? false
    }

    /// Creates the Firebase Auth account (email + password) and returns its UID.
    func createAuthUser(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    /// Saves the profile and reserves the username in one atomic step.
    func saveProfile(uid: String,
                     username: String,
                     displayName: String,
                     email: String,
                     phone: String?) async throws {
        let userRef = db.collection(Self.usersCollection).document(uid)
        let reservationRef = db.collection(Self.usernamesCollection).document(username)

        // Field names match what UserSearchService and UserProfile read.
        let userData: [String: Any] = [
            "id": uid,
            "username": username,
            "fullName": displayName,
            "email": email,
            "phoneNumber": phone ?? "",
            "bio": "",
            "isPrivate": false,
            "totalSessions": 0,
            "totalDrills": 0,
            "totalSpeakingSeconds": 0,
            "masteredTopics": [String](),
            "challengingTopics": [String](),
            "modes": [String](),
            "createdAt": FieldValue.serverTimestamp()
        ]

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let reservation = try transaction.getDocument(reservationRef)
                // Taken by someone else? (Taken by me from an earlier attempt is fine.)
                if reservation.exists, (reservation.data()?["uid"] as? String) != uid {
                    errorPointer?.pointee = NSError(
                        domain: "Onboarding", code: 409,
                        userInfo: [NSLocalizedDescriptionKey: "That username is taken. Try another one."]
                    )
                    return nil
                }
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            transaction.setData(["uid": uid], forDocument: reservationRef)
            transaction.setData(userData, forDocument: userRef, merge: true)
            return nil
        }
    }
}
