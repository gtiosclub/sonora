import FirebaseAuth
import FirebaseFirestore
import Observation

/// Single source of truth for auth state. Injected at the app root.
/// - `userID`: Firebase uid. Available immediately when the saved session is restored.
/// - `currentUser`: Sonora's `User` doc from Firestore. Loads a moment later, so it can be nil briefly.
@MainActor
@Observable
final class AuthManager {
    private(set) var userID: String?
    private(set) var currentUser: User?
    /// True until Firebase reports the first auth state (avoids flashing the login screen).
    private(set) var isLoading = true

    var isSignedIn: Bool { userID != nil }

    @ObservationIgnored private var handle: AuthStateDidChangeListenerHandle?
    @ObservationIgnored private var isSigningUp = false

    init() {
        // Fires immediately with the persisted user (if any), then on every sign in/out.
        // This is what keeps users logged in across launches.
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            let uid = firebaseUser?.uid
            Task { @MainActor in
                guard let self else { return }
                self.userID = uid
                self.isLoading = false
                if let uid {
                    // During sign up, signUp() writes and sets the user itself.
                    if !self.isSigningUp { await self.loadUser(userID: uid) }
                } else {
                    self.currentUser = nil
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(username: String, email: String, password: String) async throws {
        isSigningUp = true
        defer { isSigningUp = false }

        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid

        let newUser = User.makeNew(userId: uid, username: username, email: email)
        let newSkillProfile = SkillProfile.makeNew(userId: uid)
        let newPreferenceProfile = PreferenceProfile(id: uid, userId: uid, goodTopics: [], badTopics: [], modes: [])

        let db = Firestore.firestore()
        let batch = db.batch()
        try batch.setData(from: newUser, forDocument: db.collection("Users").document(uid))
        try batch.setData(from: newSkillProfile, forDocument: db.collection("SkillProfile").document(uid))
        try batch.setData(from: newPreferenceProfile, forDocument: db.collection("PreferencesProfile").document(uid))
        try await batch.commit()

        currentUser = newUser
    }

    func signOut() throws {
        try Auth.auth().signOut() // listener clears userID + currentUser
    }

    private func loadUser(userID: String) async {
        do {
            guard var user = try await UserService.fetch(userID: userID) else { return }
            guard self.userID == userID else { return } // signed out while loading
            user.lastLogin = Date()
            currentUser = user
            try await UserService.updateLastLogin(userID: userID, date: user.lastLogin)
        } catch {
            print("Failed to load user: \(error.localizedDescription)")
        }
    }

    /// Turns Firebase errors into something showable.
    static func friendlyMessage(for error: Error) -> String {
        switch (error as NSError).code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "That email address isn't valid."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "An account with that email already exists."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak. Use at least 6 characters."
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.userNotFound.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            return "Incorrect email or password."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Check your connection."
        default:
            let nsError = error as NSError
            print("Auth/Firestore error, domain: \(nsError.domain), code: \(nsError.code), \(nsError.localizedDescription)")
            return "Something went wrong (\(nsError.domain) \(nsError.code)). Please try again."
        }
    }
}
