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
        
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt, generating: GeneratedTitle.self)
            return response.content.title
        } catch LanguageModelSession.GenerationError.guardrailViolation {
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
        
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt, generating: GeneratedSummary.self)
            return response.content.summary
        } catch LanguageModelSession.GenerationError.guardrailViolation {
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

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var text: String
    
    enum Role {
        case user
        case assistant
    }
}

@MainActor
@Observable
class PromptChat {
    private var session: LanguageModelSession?
    private(set) var messages: [ChatMessage] = []
    private(set) var isGenerating = false
    private(set) var currentStreamingText = ""
    
    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }
    
    func prewarm(existingRecordings: [Recording]) {
        let instructions = buildInstructions(from: existingRecordings, category: nil)
        let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
        session = LanguageModelSession(model: model, instructions: instructions)
        session?.prewarm()
    }
    
    func startConversation(existingRecordings: [Recording], category: StoryCategory? = nil) async {
        let instructions = buildInstructions(from: existingRecordings, category: category)
        let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
        session = LanguageModelSession(model: model, instructions: instructions)
        
        let openingPrompt: String
        if let category = category {
            openingPrompt = "I want to share a memory about \(category.rawValue.lowercased())."
        } else {
            openingPrompt = "Hello! I'd like to record a memory."
        }
        
        await sendMessage(openingPrompt)
    }
    
    func sendMessage(_ text: String) async {
        guard let session = session else { return }
        
        if messages.count > 8 {
            messages = Array(messages.suffix(8))
        }
        
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        
        let assistantMessage = ChatMessage(role: .assistant, text: "")
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1
        
        isGenerating = true
        currentStreamingText = ""
        
        do {
            let stream = session.streamResponse(to: text)
            
            for try await snapshot in stream {
                guard assistantIndex < messages.count else { break }
                currentStreamingText = snapshot.content
                messages[assistantIndex].text = snapshot.content
            }
        } catch {
            if assistantIndex < messages.count {
                messages[assistantIndex].text = "Sorry, I couldn't respond. Please try again."
            }
            print("Chat error: \(error)")
        }
        
        isGenerating = false
        currentStreamingText = ""
    }
    
    func reset() {
        session = nil
        messages = []
        isGenerating = false
        currentStreamingText = ""
    }
    
    private func buildInstructions(from recordings: [Recording], category: StoryCategory?) -> String {
        var context = ""
        
        if !recordings.isEmpty {
            let recordingSummaries = recordings.prefix(10).map { recording in
                "- \(recording.title): \(recording.summary)"
            }.joined(separator: "\n")
            
            context = """
            
            The user has already recorded these memories:
            \(recordingSummaries)
            
            Use this context to suggest topics they haven't explored yet, or to go deeper into themes they've already touched on.
            """
        }
        
        let categoryGuidance: String
        if let category = category {
            categoryGuidance = """
            
            The user wants to share a \(category.rawValue) memory. \(categoryPromptGuidance(for: category))
            Start by asking a thoughtful, specific question about this topic.
            """
        } else {
            categoryGuidance = """
            
            Help them explore different categories: Childhood, Family, Immigration, Career, Recipes, Traditions.
            """
        }
        
        return """
            You are a warm, empathetic guide helping someone preserve their family memories.
            Your role is to help them discover what story they want to record next.
            
            Guidelines:
            - Be conversational and encouraging, like a friendly interviewer
            - Ask follow-up questions to help them find a specific memory
            - When they seem ready, confirm the topic and encourage them to start recording
            - Keep responses concise (2-3 sentences max)
            - Respond in English
            \(categoryGuidance)
            \(context)
            """
    }
    
    private func categoryPromptGuidance(for category: StoryCategory) -> String {
        switch category {
        case .childhood:
            return "Ask about early memories, favorite games, school days, or places they grew up."
        case .family:
            return "Ask about family members, relationships, gatherings, or family dynamics."
        case .immigration:
            return "Ask about journeys, leaving home, arriving somewhere new, or cultural transitions."
        case .career:
            return "Ask about first jobs, mentors, career-defining moments, or lessons learned."
        case .recipes:
            return "Ask about family recipes, cooking traditions, special meals, or food memories."
        case .traditions:
            return "Ask about holidays, celebrations, rituals, or customs passed down through generations."
        }
    }
}
