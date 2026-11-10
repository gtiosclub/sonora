//
//  RealtimeKeyService.swift
//  Sonora
//
//  Created by Maxwell Man on 11/9/26.
//

// sends a POST to https://api.openai.com/v1/realtime/client_secrets
// includes the headers Authorization: Bearer (Secrets.openAIAPIKey) and Content-Type: application/json
// sends this body: {"session": {"type": "realtime", "model": "gpt-realtime-mini"}}
// decodes the JSON response and return its value field (a string starting with ek_)
// throws an error if the status code isn't 200

import Foundation

struct RealtimeKeyService {
    static func fetchEphemeralKey() async throws -> String {
        
        // Building the Request
        let url = URL(string: "https://api.openai.com/v1/realtime/client_secrets")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Setting the Headers for the Request
        request.setValue("Bearer \(Secrets.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // JSON body for the Request
        let body: [String: Any] = [
            "session": [
                "type": "realtime",
                "model": "gpt-realtime-mini"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Sending the request and checking status code
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Decoding the returned JSON and returning the ephemeral key
        struct ClientSecretResponse: Decodable {
            let value: String
        }

        let decoded = try JSONDecoder().decode(ClientSecretResponse.self, from: data)
        return decoded.value
    }
}

