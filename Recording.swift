//
//  Recording.swift
//  Swift Student Challenge app
//
//  Created by Papasito on 18/12/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

enum TranscriptionStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}

@Model
final class Recording {
    var id: UUID
    var title: String
    var date: Date
    var duration: TimeInterval
    var transcript: String
    var audioFileName: String
    var transcriptionStatusRaw: String
    
    init(title: String, duration: TimeInterval, transcript: String = "", audioFileName: String) {
        self.id = UUID()
        self.title = title
        self.date = Date()
        self.duration = duration
        self.transcript = transcript
        self.audioFileName = audioFileName
        self.transcriptionStatusRaw = TranscriptionStatus.pending.rawValue
    }
    
    var transcriptionStatus: TranscriptionStatus {
        get { TranscriptionStatus(rawValue: transcriptionStatusRaw) ?? .pending }
        set { transcriptionStatusRaw = newValue.rawValue }
    }
    
    var isTranscribing: Bool {
        transcriptionStatus == .pending || transcriptionStatus == .inProgress
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Returns the full URL to the audio file in the documents directory
    var audioFileURL: URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsPath?.appendingPathComponent(audioFileName)
    }
    
    @MainActor
    func startTranscription(modelContext: ModelContext) {
        guard transcriptionStatus == .pending else { return }
        
        transcriptionStatus = .inProgress
        
        // Capture values needed for background work
        let url = audioFileURL
        let recordingId = id
        
        Task {
            let result = await Self.performTranscription(url: url, recordingId: recordingId)
            
            // Update model on main actor
            switch result {
            case .success(let text):
                self.transcript = text
                self.transcriptionStatus = .completed
            case .failure(let error):
                self.transcriptionStatus = .failed
                self.transcript = "Transcription failed: \(error.localizedDescription)"
            }
            try? modelContext.save()
        }
    }
    
    /// Performs transcription off the main actor
    private static nonisolated func performTranscription(url: URL?, recordingId: UUID) async -> Result<String, Error> {
        guard let url = url else {
            print("Audio file not found for recording Hola \(recordingId)")
            return .failure(TranscriptionError.audioFileNotFound)
        }
        
        do {
            let transcribedText = try await SpeechTranscriber.shared.transcribe(audioFileURL: url)
            print("Transcription completed for recording \(recordingId)")
            return .success(transcribedText)
        } catch {
            print("Transcription failed for recording \(recordingId): \(error)")
            return .failure(error)
        }
    }
}

