//
//  DrillGenerator.swift
//  Sonora
//
//  Created by Eshaan Dixit on 10/1/26.
//

import Foundation

protocol DrillKind {
    var rawValue: String { get }
    var title: String { get }
    var icon: String { get }
    var instruction: String { get }
}

enum DrillTaskType: String, Codable, CaseIterable, DrillKind {
    case rebuttal
    case analyzeSession
    case newArgument
    case argueOtherSide
    case closingStatement
    case crossExamination

    var instruction: String {
        switch self {
        case .rebuttal: "Develop a rebuttal to the strongest argument the other side made."
        case .analyzeSession: "Analyze your strengths and weaknesses in this past debate."
        case .newArgument: "Develop a new argument for your side that wasn't used before."
        case .argueOtherSide: "Argue for the side you did not take in this debate."
        case .closingStatement: "Deliver a concise closing statement for your side."
        case .crossExamination: "Prepare pointed questions to challenge the other side."
        }
    }

    var title: String {
        switch self {
        case .rebuttal: "Rebuttal"
        case .analyzeSession: "Session review"
        case .newArgument: "New argument"
        case .argueOtherSide: "Argue the other side"
        case .closingStatement: "Closing statement"
        case .crossExamination: "Cross-examination"
        }
    }

    var icon: String {
        switch self {
        case .rebuttal: "arrow.uturn.backward"
        case .analyzeSession: "magnifyingglass"
        case .newArgument: "lightbulb"
        case .argueOtherSide: "arrow.left.arrow.right"
        case .closingStatement: "flag"
        case .crossExamination: "questionmark.bubble"
        }
    }
}

enum InterviewDrillType: String, Codable, CaseIterable, DrillKind {
    case starStructure
    case conciseAnswer
    case followUpQuestion
    case tellMeAboutYourself
    case weaknessQuestion
    case questionsForInterviewer

    var instruction: String {
        switch self {
        case .starStructure: "Restructure one of your answers using the STAR method: situation, task, action, result."
        case .conciseAnswer: "Answer the same question again in under 60 seconds."
        case .followUpQuestion: "Answer a tough follow-up question about your last response."
        case .tellMeAboutYourself: "Polish a short answer to 'tell me about yourself' that connects your experience to the role."
        case .weaknessQuestion: "Answer a weakness question with a real example and how you're improving."
        case .questionsForInterviewer: "Prepare thoughtful questions to ask your interviewer."
        }
    }

    var title: String {
        switch self {
        case .starStructure: "STAR answer"
        case .conciseAnswer: "60-second answer"
        case .followUpQuestion: "Follow-up question"
        case .tellMeAboutYourself: "Tell me about yourself"
        case .weaknessQuestion: "Weakness question"
        case .questionsForInterviewer: "Questions for them"
        }
    }

    var icon: String {
        switch self {
        case .starStructure: "star"
        case .conciseAnswer: "timer"
        case .followUpQuestion: "arrowshape.turn.up.right"
        case .tellMeAboutYourself: "person.crop.circle"
        case .weaknessQuestion: "arrow.up.right"
        case .questionsForInterviewer: "questionmark.circle"
        }
    }
}

enum PresentationDrillType: String, Codable, CaseIterable, DrillKind {
    case openingHook
    case transitions
    case pacing
    case vocalVariety
    case closingSummary
    case bodyLanguage

    var instruction: String {
        switch self {
        case .openingHook: "Write and deliver a stronger opening hook that grabs your audience."
        case .transitions: "Add clear transitions that connect each of your main points."
        case .pacing: "Deliver a section again at a steady pace, pausing deliberately after key points."
        case .vocalVariety: "Vary your tone and volume to emphasize your most important points."
        case .closingSummary: "Deliver a concise closing that sums up your main message."
        case .bodyLanguage: "Present a section again with steady eye contact and open posture."
        }
    }

    var title: String {
        switch self {
        case .openingHook: "Opening hook"
        case .transitions: "Transitions"
        case .pacing: "Pacing and pauses"
        case .vocalVariety: "Vocal variety"
        case .closingSummary: "Closing summary"
        case .bodyLanguage: "Eye contact and posture"
        }
    }

    var icon: String {
        switch self {
        case .openingHook: "sparkles"
        case .transitions: "arrow.right.circle"
        case .pacing: "metronome"
        case .vocalVariety: "waveform"
        case .closingSummary: "flag.checkered"
        case .bodyLanguage: "figure.stand"
        }
    }
}

struct DrillPrompt {
    let drillContext: String
    let sessionId: String?
    let drill: any DrillKind
    let needsMoreSessions: Bool
}

struct WrittenDrill {
    let feedback: String
    let drill: any DrillKind
    let assignment: String
}

enum DrillPromptText {
    static func instructions(for mode: Session.Mode) -> String {
        switch mode {
        case .debate:
            """
            You are a professional debater coaching an apprentice. \
            Examine the debate provided, \
            Speaking to the student as "you" with normal capitalization, \
            explain their weaknesses using the provided summary and lowest scores, \
            in the context of their chosen prompt, and do NOT mention their scores \
            Assign the drill from the list that best targets their weaknesses, \
            and only assign drills from the list. Keep your whole statement concise, under 2 sentences.
            """
        case .interview:
            """
            You are an experienced interview coach helping a candidate prepare. \
            Examine the interview answer provided. \
            Speaking to the candidate as "you" with normal capitalization, \
            explain their weaknesses using the provided summary and lowest scores, \
            in the context of the interview question, and do NOT mention their scores. \
            Assign the drill from the list that best targets their weaknesses, \
            and only assign drills from the list. Keep your whole statement concise, under 2 sentences.
            """
        case .speech:
            """
            You are an experienced public speaking coach helping a presenter improve. \
            Examine the presentation provided. \
            Speaking to the presenter as "you" with normal capitalization, \
            explain their weaknesses using the provided summary and lowest scores, \
            in the context of their presentation topic, and do NOT mention their scores. \
            Assign the drill from the list that best targets their weaknesses, \
            and only assign drills from the list. Keep your whole statement concise, under 2 sentences.
            """
        }
    }

    static func request(for session: Session) -> String {
        var lines = ["\(session.mode.promptLabel): \(session.prompt ?? "unknown")"]
        if let summary = session.summary {
            lines.append("Summary: \(summary)")
        }
        if let skills = session.sessionSkillScore {
            lines.append("Scores: content \(skills.content.score), clarity \(skills.clarity.score), confidence \(skills.confidence.score), engagement \(skills.engagement.score)")
        }
        lines.append("Drills:")
        lines += session.mode.drillOptions.map { "- \($0.rawValue): \($0.instruction)" }
        return lines.joined(separator: "\n")
    }
}

extension Session.Mode {
    /// What the model writes in `feedback`. Sent as the JSON schema field description.
    var feedbackGuide: String {
        switch self {
        case .debate:
            "One short sentence, under 20 words, to the student about the debate that must name its subject in your own words (for example, \"your argument against X\" rather than quoting the prompt) and explain their main weakness from its summary, without mentioning any scores or numbers"
        case .interview:
            "One short sentence, under 20 words, to the candidate about their interview answer that must name what the question was about in your own words (for example, \"your answer about leading a team\" rather than quoting the question) and explain their main weakness from its summary, without mentioning any scores or numbers"
        case .speech:
            "One short sentence, under 20 words, to the speaker about their presentation that must name its topic in your own words (for example, \"your talk on X\" rather than quoting the title) and explain their main weakness from its summary, without mentioning any scores or numbers"
        }
    }

    /// What the model writes in `assignment`.
    var assignmentGuide: String {
        let person = switch self {
        case .debate: "student"
        case .interview: "candidate"
        case .speech: "speaker"
        }
        return "One short sentence suggesting that drill to the \(person), starting with a casual lead-in such as \"Try\" or \"You should try\", and staying close to the drill's description. Describe what to do in plain words; never write the drill's camelCase id"
    }

    var promptLabel: String {
        switch self {
        case .debate: "Debate prompt"
        case .interview: "Interview question"
        case .speech: "Presentation topic"
        }
    }

    var drillOptions: [any DrillKind] {
        switch self {
        case .debate: DrillTaskType.allCases
        case .interview: InterviewDrillType.allCases
        case .speech: PresentationDrillType.allCases
        }
    }

    var fallbackDrill: any DrillKind {
        switch self {
        case .debate: DrillTaskType.analyzeSession
        case .interview: InterviewDrillType.starStructure
        case .speech: PresentationDrillType.pacing
        }
    }
}

protocol DrillContextWriter {
    func writeDrill(for session: Session) async throws -> WrittenDrill
}

enum DrillWriterError: Error {
    case missingAPIKey
    case badResponse(status: Int, body: String)
    case refused(String)
    case unknownDrill(String)
    case noSessions
}

/// Writes the drill with OpenAI's Chat Completions API using Structured Outputs:
/// the JSON schema limits `drill` to the mode's drill list, so the model can't
/// invent a drill or return malformed JSON.
struct OpenAIDrillContextWriter: DrillContextWriter {
    /// Change this one line to switch models. It must support Structured Outputs.
    static let model = "gpt-4.1-mini"

    func writeDrill(for session: Session) async throws -> WrittenDrill {
        let apiKey = Secrets.openAIAPIKey
        guard !apiKey.isEmpty else { throw DrillWriterError.missingAPIKey }

        let mode = session.mode
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "feedback": ["type": "string", "description": mode.feedbackGuide],
                "drill": [
                    "type": "string",
                    "enum": mode.drillOptions.map(\.rawValue),
                    "description": "The drill from the list that best targets that weakness",
                ],
                "assignment": ["type": "string", "description": mode.assignmentGuide],
            ],
            "required": ["feedback", "drill", "assignment"],
            "additionalProperties": false,
        ]
        let body: [String: Any] = [
            "model": Self.model,
            "messages": [
                ["role": "system", "content": DrillPromptText.instructions(for: mode)],
                ["role": "user", "content": DrillPromptText.request(for: session)],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": ["name": "drill", "strict": true, "schema": schema],
            ],
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 200 else {
            throw DrillWriterError.badResponse(status: status, body: String(decoding: data.prefix(500), as: UTF8.self))
        }

        struct Completion: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String?
                    let refusal: String?
                }
                let message: Message
            }
            let choices: [Choice]
        }
        struct Output: Decodable {
            let feedback: String
            let drill: String
            let assignment: String
        }

        let message = try JSONDecoder().decode(Completion.self, from: data).choices.first?.message
        if let refusal = message?.refusal { throw DrillWriterError.refused(refusal) }
        let output = try JSONDecoder().decode(Output.self, from: Data((message?.content ?? "").utf8))
        guard let drill = mode.drillOptions.first(where: { $0.rawValue == output.drill }) else {
            throw DrillWriterError.unknownDrill(output.drill)
        }
        return WrittenDrill(feedback: output.feedback, drill: drill, assignment: output.assignment)
    }
}

struct TemplateDrillContextWriter: DrillContextWriter {
    func writeDrill(for session: Session) async throws -> WrittenDrill {
        Self.drill(for: session, mode: session.mode)
    }

    static func drill(for session: Session?, mode: Session.Mode) -> WrittenDrill {
        let drill = mode.fallbackDrill
        return WrittenDrill(
            feedback: session?.summary ?? "Complete a session to get feedback on your weaknesses.",
            drill: drill,
            assignment: "Try this: \(drill.instruction)"
        )
    }
}

enum DrillGenerator {
    static let requiredSessions = 5

    static func generate(lastSessions: [Session], mode: Session.Mode, previousDrills: [Drill], writer: (any DrillContextWriter)? = nil) async -> DrillPrompt {
        let sessions = Array(lastSessions.filter { $0.mode == mode }.prefix(requiredSessions))
        guard let session = sessions.randomElement() else {
            return makePrompt(from: TemplateDrillContextWriter.drill(for: nil, mode: mode), sessionId: nil, needsMoreSessions: true)
        }
        return await generate(for: session, writer: writer, needsMoreSessions: sessions.count < requiredSessions)
    }

    static func generate(for session: Session, writer: (any DrillContextWriter)? = nil, needsMoreSessions: Bool = false) async -> DrillPrompt {
        let writer = writer ?? OpenAIDrillContextWriter()

        let result: WrittenDrill
        do {
            result = try await writer.writeDrill(for: session)
        } catch {
            print("Drill writer failed (\(error)), using template instead")
            result = TemplateDrillContextWriter.drill(for: session, mode: session.mode)
        }

        return makePrompt(from: result, sessionId: session.id, needsMoreSessions: needsMoreSessions)
    }

    private static func makePrompt(from result: WrittenDrill, sessionId: String?, needsMoreSessions: Bool) -> DrillPrompt {
        func tidy(_ sentence: String) -> String {
            var text = sentence.trimmingCharacters(in: .whitespaces)
            text = text.prefix(1).uppercased() + text.dropFirst()
            if let last = text.last, !".!?".contains(last) {
                text += "."
            }
            return text
        }

        return DrillPrompt(
            drillContext: "\(tidy(result.feedback)) \(tidy(result.assignment))",
            sessionId: sessionId,
            drill: result.drill,
            needsMoreSessions: needsMoreSessions
        )
    }
}
