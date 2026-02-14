//
//  File.swift
//  Swift Student Challenge Real
//
//  Created by Luis on 14/02/26.
//

import SwiftUI
import FoundationModels



@Generable(description: "A summary title for the transcript keeping in mind its a memory")
struct GeneratedTitle {
    @Guide(description: "A short memorable title between 3-8 words")
    var summary : String
}

enum titleGenerationError: Error, LocalizedError {
    case modelUnavailable(reason: String)
    case emptyTranscript
    case generationFailed(underlying: Error)
    case guardrailTriggered
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason):
            return "Apple Intelligence unavailable: \(reason)"
        case .emptyTranscript:
            return "Cannot generate title from empty transcript"
        case .generationFailed(let error):
            return "Title generation failed: \(error.localizedDescription)"
        case .guardrailTriggered:
            return "Content could not be processed"
        }
    }
}

actor TitleGenerator{
    static let shared = TitleGenerator()
    private init(){}
    
    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }
    
    func generateTitle(from transcript: String) async throws -> String{
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw titleGenerationError.emptyTranscript
        }
        
        let session = LanguageModelSession(instructions: """
            You are a helpful  asistant that creates short, descriptive titles. You MUST respond in English regardless of the input language. Generate a concise title (3-8 words) that captures the main topic. Do not use question marks
            """)
        let prompt = "Create a short English title for this recording:\n\n\(trimmed)"
        do {
            let response = try await session.respond(
                to: prompt,
                generating: GeneratedTitle.self
            )
            return response.content.summary
            
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation:
                throw titleGenerationError.guardrailTriggered
            default:
                throw titleGenerationError.generationFailed(underlying: error)
                
            }
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
    
    private func unavailabilityReason() -> String {
        switch SystemLanguageModel.default.availability {
        case .available:
            return "Available"
        case .unavailable(.deviceNotEligible):
            return "Device does not support Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence not enabled"
        case .unavailable(.modelNotReady):
            return "Model still downloading"
        @unknown default:
            return "Unknown"
        }
    }
}




