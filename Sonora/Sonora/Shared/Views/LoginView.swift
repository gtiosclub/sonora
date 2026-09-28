import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false
    @State private var errorMessage: String?
    @State private var isWorking = false

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && (!isSigningUp || !username.isEmpty) && !isWorking
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Sonora")
                .font(.largeTitle.bold())

            if isSigningUp {
                TextField("Username", text: $username)
                    .textContentType(.nickname)
                    .textFieldStyle(.roundedBorder)
            }

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textContentType(.username)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textContentType(isSigningUp ? .oneTimeCode : .password)
                .id(isSigningUp) // rebuild the field so iOS re-reads the content type when toggling
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await submit() }
            } label: {
                if isWorking {
                    ProgressView()
                } else {
                    Text(isSigningUp ? "Create account" : "Log in")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)

            Button(isSigningUp ? "Have an account? Log in" : "New here? Sign up") {
                isSigningUp.toggle()
                errorMessage = nil
            }
            .font(.footnote)
        }
        .padding()
    }

    private func submit() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            if isSigningUp {
                try await auth.signUp(username: username, email: trimmedEmail, password: password)
            } else {
                try await auth.signIn(email: trimmedEmail, password: password)
            }
            // No navigation code: AuthManager's listener updates state and RootView reacts.
        } catch {
            errorMessage = AuthManager.friendlyMessage(for: error)
        }
    }
}
