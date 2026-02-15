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

/// A single message in the chat
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var text: String
    
    enum Role {
        case user
        case assistant
    }
}

/// Manages a conversational session to help users discover what to record
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
        let instructions = buildInstructions(from: existingRecordings)
        session = LanguageModelSession(instructions: instructions)
        session?.prewarm()
    }
    
    /// Start the conversation with an initial greeting
    func startConversation(existingRecordings: [Recording]) async {
        // Create session if not prewarmed
        if session == nil {
            let instructions = buildInstructions(from: existingRecordings)
            session = LanguageModelSession(instructions: instructions)
        }
        
        // Send initial prompt to get the conversation started
        await sendMessage("Hello! I'd like to record a memory.")
    }
    
    /// Send a user message and stream the response
    func sendMessage(_ text: String) async {
        guard let session = session else { return }
        
        // Add user message
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        
        // Prepare assistant message placeholder
        let assistantMessage = ChatMessage(role: .assistant, text: "")
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1
        
        isGenerating = true
        currentStreamingText = ""
        
        do {
            // Stream the response token by token
            let stream = session.streamResponse(to: text)
            
            for try await snapshot in stream {
                currentStreamingText = snapshot.content
                messages[assistantIndex].text = snapshot.content
            }
        } catch {
            messages[assistantIndex].text = "Sorry, I couldn't respond. Please try again."
            print("Chat error: \(error)")
        }
        
        isGenerating = false
        currentStreamingText = ""
    }
    
    /// Reset the conversation
    func reset() {
        session = nil
        messages = []
        isGenerating = false
        currentStreamingText = ""
    }
    
    /// Build instructions that include context about existing recordings
    private func buildInstructions(from recordings: [Recording]) -> String {
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
        
        return """
            You are a warm, empathetic guide helping someone preserve their family memories.
            Your role is to help them discover what story they want to record next.
            
            Guidelines:
            - Be conversational and encouraging, like a friendly interviewer
            - Ask follow-up questions to help them find a specific memory
            - Suggest categories: Childhood, Family, Immigration, Career, Recipes, Traditions
            - When they seem ready, confirm the topic and encourage them to start recording
            - Keep responses concise (2-3 sentences max)
            - Respond in English
            \(context)
            """
    }
}

