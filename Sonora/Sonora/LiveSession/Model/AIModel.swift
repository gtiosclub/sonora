//
//  AIModel.swift
//  Sonora
//

import Foundation
import RealtimeAPI

@MainActor @Observable
final class AIOpponentViewModel {
    let conversation = Conversation()     // holds the live session + transcript
    var errorMessage: String?             // surfaces any failure to the UI

    // Starts a live debate: fetch a key, connect, then configure the AI's
    // persona, voice, topic, and which side it argues.
    func start(persona: Persona, topic: DebateTopic, aiSide: String) async {
        do {
            
            let key = try await RealtimeKeyService.fetchEphemeralKey()

            
            try await conversation.connect(ephemeralKey: key, model: .gptRealtimeMini)

            
            try conversation.updateSession { session in
               
                session.instructions = persona.debateInstructions(topic: topic, aiSide: aiSide)
                
                session.audio.output.voice = .init(rawValue: persona.voice) ?? .sage
            }
        } catch {
          
            errorMessage = error.localizedDescription
        }
    }

   
    func stop() {
        conversation.disconnect()
    }
}
