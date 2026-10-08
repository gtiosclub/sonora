//
//  DebateDrillGenerator.swift
//  Sonora
//
//  Created by Eshaan Dixit on 10/1/26.
//

import Foundation
import FoundationModels


@Generable
enum DrillTaskType: String, Codable, CaseIterable {
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
}

struct DebateDrillPrompt {
    let drillContext: String
    let sessionId: String?
    let taskType: DrillTaskType
    let needsMoreSessions: Bool
}

@Generable
struct GeneratedDebateDrill {
    @Guide(description: "One short sentence, under 20 words, to the student about the debate that must name its subject in your own words (for example, \"your argument against X\" rather than quoting the prompt) and explain their main weakness from its summary, without mentioning any scores or numbers")
    var feedback: String
    @Guide(description: "The drill from the list that best targets that weakness")
    var taskType: DrillTaskType
    @Guide(description: "One short sentence suggesting that drill to the student, starting with a casual lead-in such as \"Try\" or \"You should try\", and staying close to the drill's description")
    var assignment: String
}

enum DebateDrillPromptText {
    static let instructions = """
        You are a professional debater coaching an apprentice. \
        Examine the debate provided, \
        Speaking to the student as "you" with normal capitalization, \
        explain their weaknesses using the provided summary and lowest scores, \
        in the context of their chosen prompt, and do NOT mention their scores \
        Assign the drill from the list that best targets their weaknesses, \
        and only assign drills from the list. Keep your whole statement concise, under 2 sentences.
        """

    static func request(debate: Session) -> String {
        var lines = ["Debate prompt: \(debate.prompt ?? "unknown")"]
        if let summary = debate.summary {
            lines.append("Summary: \(summary)")
        }
        if let scores = debate.scores, scores.count == 4 {
            lines.append("Scores: content \(scores[0]), clarity \(scores[1]), confidence \(scores[2]), engagement \(scores[3])")
        }
        lines.append("Drills:")
        lines += DrillTaskType.allCases.map { "- \($0.rawValue): \($0.instruction)" }
        return lines.joined(separator: "\n")
    }
}

protocol DrillContextWriter {
    func writeDrill(debate: Session) async throws -> GeneratedDebateDrill
}

enum DrillWriterError: Error {
    case modelUnavailable
    case noDebates
}

struct AppleDrillContextWriter: DrillContextWriter {
    func writeDrill(debate: Session) async throws -> GeneratedDebateDrill {
        guard SystemLanguageModel.default.isAvailable else { throw DrillWriterError.modelUnavailable }

        let model = LanguageModelSession(instructions: DebateDrillPromptText.instructions)
        let response = try await model.respond(
            to: DebateDrillPromptText.request(debate: debate),
            generating: GeneratedDebateDrill.self
        )
        return response.content
    }
}

struct TemplateDrillContextWriter: DrillContextWriter {
    func writeDrill(debate: Session) async throws -> GeneratedDebateDrill {
        Self.drill(debate: debate)
    }

    static func drill(debate: Session?) -> GeneratedDebateDrill {
        GeneratedDebateDrill(
            feedback: debate?.summary ?? "Complete a debate to get feedback on your weaknesses.",
            taskType: .analyzeSession,
            assignment: "Try this: \(DrillTaskType.analyzeSession.instruction)"
        )
    }
}

enum DebateDrillGenerator {
    static let requiredSessions = 5

    static func generate(lastDebates: [Session], previousDrills: [Drill], writer: (any DrillContextWriter)? = nil) async -> DebateDrillPrompt {
        let writer = writer ?? AppleDrillContextWriter()
        let debates = Array(lastDebates.filter { $0.mode == .debate }.prefix(requiredSessions))
        let debate = debates.randomElement()

        let result: GeneratedDebateDrill
        do {
            guard let debate else { throw DrillWriterError.noDebates }
            result = try await writer.writeDrill(debate: debate)
        } catch {
            print("Drill writer failed (\(error)), using template instead")
            result = TemplateDrillContextWriter.drill(debate: debate)
        }

        func tidy(_ sentence: String) -> String {
            var text = sentence.trimmingCharacters(in: .whitespaces)
            text = text.prefix(1).uppercased() + text.dropFirst()
            if let last = text.last, !".!?".contains(last) {
                text += "."
            }
            return text
        }

        return DebateDrillPrompt(
            drillContext: "\(tidy(result.feedback)) \(tidy(result.assignment))",
            sessionId: debate?.id,
            taskType: result.taskType,
            needsMoreSessions: debates.count < requiredSessions
        )
    }
}
