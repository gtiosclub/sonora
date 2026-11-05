//
//  WaitingView.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/10/26.
//


import SwiftUI
import FirebaseFirestore

//Screen 2: Waiting 
struct WaitingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @State private var sessionListener: ListenerRegistration?
    @State private var listenerError: String?
    @State private var routedSessionId: String?
    @State private var routedSession: Session?
    
    let matchingStartedAt: Date
    let onSessionUpdate: (Session) -> Void
    
    init(
        matchingStartedAt: Date = Date(),
        onSessionUpdate: @escaping (Session) -> Void = { _ in }
    ) {
        self.matchingStartedAt = matchingStartedAt
        self.onSessionUpdate = onSessionUpdate
    }
    
    var body: some View {
        AppLayout {
            VStack(spacing: 20) {
                
                Text("Searching...")
                    .font(.title2)
                    .bold()
                
                // Placeholder for searching animation
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                    
                    ProgressView()
                        .scaleEffect(1.5)
                }
                .frame(height: 230)
                
                Text("Estimated wait time: 2 mins")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let listenerError {
                    Text(listenerError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                OutlinedCard {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")
                        
                        Text("Tip: Speak slightly slower than you think you need to!")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Button {
                    Task {
                        do {
                            try await cancelWaitingRequest(
                                userId: auth.currentUser?.id ?? ""
                            )
                        } catch {
                            print("Failed to cancel waiting request: \(error)")
                        }
                    }
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray)
                        )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: startListeningForSession)
        .onDisappear(perform: stopListening)
        
    }
    private func stopListening() {
        sessionListener?.remove()
        sessionListener = nil
    }
    
    private func startListeningForSession() {
        guard sessionListener == nil, let userId = auth.userID else {
            print("waiting: no listener, userID nil")
            return
        }
        print("waiting: listening as", userId)
        
        sessionListener = listenForUserSessions(userId: userId, since: matchingStartedAt) { result in
            Task { @MainActor in
                switch result {
                case .success(let sessions):
                    print("waiting: got", sessions.map { "\($0.id) \($0.status)" })
                    
                    guard let session = sessions
                        .filter({ $0.status == .pending || $0.status == .active })
                        .max(by: { $0.createdAt < $1.createdAt }),
                          session.id != routedSessionId else { return }
                    
                    routedSessionId = session.id
                    stopListening()
                    onSessionUpdate(session)   // router does the navigation
                case .failure(let error):
                    listenerError = "Couldn't listen for a match: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WaitingView()
    }
}


