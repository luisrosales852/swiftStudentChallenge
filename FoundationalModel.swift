//
//  FoundationalModel.swift
//  Swift Student Challenge Real
//
//  Created by Luis on 14/02/26.
//

import SwiftUI
import FoundationModels


@Generable(description: "A title for a memory recording")
struct GeneratedTitle {
    @Guide(description: "A short memorable title between 3-8 words")
    var title: String
}

actor TitleGenerator {
    static let shared = TitleGenerator()
    private init() {}
    
    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }
    
    func generateTitle(from transcript: String) async throws -> String {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Voice Recording" }
        
        let instructions = """
            You create short, descriptive titles for family memory recordings.
            Respond in English regardless of input language.
            No quotation marks.
            """
        
        let prompt = "Create a title (3-8 words) for this recording:\n\n\(trimmed)"
        
        // Try structured generation first
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt, generating: GeneratedTitle.self)
            return response.content.title
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            // Fallback to permissive mode for sensitive content
            let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
            let session = LanguageModelSession(model: model, instructions: instructions)
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func generateTitleOrFallback(from transcript: String, fallback: String) async -> String {
        do {
            return try await generateTitle(from: transcript)
        } catch {
            print("Title generation failed: \(error)")
            return fallback
        }
    }
}

@Generable(description: "A summary of a memory recording")
struct GeneratedSummary {
    @Guide(description: "A 1-2 sentence summary of the memory")
    var summary: String
}

actor SummaryGenerator {
    static let shared = SummaryGenerator()
    private init() {}
    
    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }
    
    func generateSummary(from transcript: String) async throws -> String {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        let instructions = """
            You create brief summaries of family memory recordings.
            Respond in English regardless of input language.
            Focus on who, what, and why this memory matters.
            """
        
        let prompt = "Summarize this memory in 1-2 sentences:\n\n\(trimmed)"
        
        // Try structured generation first
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt, generating: GeneratedSummary.self)
            return response.content.summary
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            // Fallback to permissive mode for sensitive content
            let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
            let session = LanguageModelSession(model: model, instructions: instructions)
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func generateSummaryOrFallback(from transcript: String, fallback: String) async -> String {
        do {
            return try await generateSummary(from: transcript)
        } catch {
            print("Summary generation failed: \(error)")
            return fallback
        }
    }
}
