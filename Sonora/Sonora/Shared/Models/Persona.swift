//
//  Persona.swift
//  Sonora
//

import Foundation

// A persona defines who the realtime voice agent is what it sounds like
// and how it behaves. It's sent to OpenAI when the voice session starts.
struct Persona: Codable, Identifiable {
    var id: String
    var name: String         
    var summary: String
    var voice: String
    var instructions: String
    var openingLine: String
}

