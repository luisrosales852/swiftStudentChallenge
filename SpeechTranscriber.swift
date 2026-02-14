//
//  SpeechTranscriber.swift
//  Swift Student Challenge Real
//
//  Created by Luis on 10/02/26.
//


import Foundation
import Speech

actor SpeechTranscriber {
    static let shared = SpeechTranscriber()
    
    private init() {}
    
    /// Request speech recognition permission
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func transcribe(audioFileURL url: URL, locale: Locale) async throws -> String {
        // Check permission
        let authorized = await requestPermission()
        guard authorized else {
            throw TranscriptionError.permissionDenied
        }
        
        // Create speech recognizer
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            throw TranscriptionError.recognizerUnavailable
        }
        
        guard recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }
        
        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
    
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            recognizer.recognitionTask(with: request) { result, error in
                guard !hasResumed else { return }
                
                if let error = error {
                    hasResumed = true
                    continuation.resume(throwing: TranscriptionError.transcriptionFailed(error.localizedDescription))
                    return
                }
                
                guard let result = result else {
                    hasResumed = true
                    continuation.resume(throwing: TranscriptionError.noResult)
                    return
                }
                
                if result.isFinal {
                    hasResumed = true
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}

enum TranscriptionError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case transcriptionFailed(String)
    case noResult
    case audioFileNotFound
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission was denied. Please enable it in Settings."
        case .recognizerUnavailable:
            return "Speech recognition is not available on this device."
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .noResult:
            return "No transcription result was returned."
        case .audioFileNotFound:
            return "Audio file not found."
        }
    }
}
