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
    var summary: String
    var languageIdentifier: String
    var title: String
    var date: Date
    var duration: TimeInterval
    var transcript: String
    var audioFileName: String
    var photoFileNames: [String]
    var transcriptionStatusRaw: String
    
    init(title: String, duration: TimeInterval, transcript: String = "", audioFileName: String, languageIdentifier: String = "en-US", summary: String = "", photoFileNames: [String] = []) {
        self.id = UUID()
        self.title = title
        self.date = Date()
        self.summary = summary
        self.duration = duration
        self.transcript = transcript
        self.audioFileName = audioFileName
        self.transcriptionStatusRaw = TranscriptionStatus.pending.rawValue
        self.languageIdentifier = languageIdentifier
        self.photoFileNames = photoFileNames
    }
    
    var transcriptionStatus: TranscriptionStatus {
        get { TranscriptionStatus(rawValue: transcriptionStatusRaw) ?? .pending }
        set { transcriptionStatusRaw = newValue.rawValue }
    }
    
    var photoFileURLs: [URL]{
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        return photoFileNames.map {documentsPath.appendingPathComponent($0)}
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
    
    var languageFlag: String {
        switch languageIdentifier {
        case "es-ES":
            return "🇪🇸"
        case "en-US":
            return "🇺🇸"
        default:
            return "🇺🇸"
        }
    }
    
    /// Returns the full URL to the audio file in the documents directory
    var audioFileURL: URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsPath?.appendingPathComponent(audioFileName)
    }
    
    static func saveImage(_ data: Data) -> String? {
        let fileName = "photo_\(UUID().uuidString).jpg"
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    /// Delete an image file from disk only
    private static func deleteImageFile(fileName: String) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let fileURL = documentsPath.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    /// Save image data and add to this recording's photoFileNames
    /// - Parameter data: The image data (JPEG) to save
    /// - Returns: true if successful, false otherwise
    func addPhoto(_ data: Data) -> Bool {
        guard let fileName = Self.saveImage(data) else { return false }
        photoFileNames.append(fileName)
        return true
    }
    
    /// Remove a photo at index: deletes file from disk AND removes from photoFileNames array
    func removePhoto(at index: Int) {
        guard index >= 0 && index < photoFileNames.count else { return }
        let fileName = photoFileNames[index]
        Self.deleteImageFile(fileName: fileName)
        photoFileNames.remove(at: index)
    }
    
    /// Delete all photos associated with this recording (call before deleting the recording)
    func deleteAllPhotos() {
        for fileName in photoFileNames {
            Self.deleteImageFile(fileName: fileName)
        }
        photoFileNames.removeAll()
    }
    @MainActor
    func startTranscription(modelContext: ModelContext) {
        guard transcriptionStatus == .pending else { return }
        
        transcriptionStatus = .inProgress
        
        // Capture values needed for background work
        let locale = Locale(identifier: languageIdentifier)
        let url = audioFileURL
        let recordingId = id
        let currentTitle = title
        
        Task {
            let result = await Self.performTranscription(url: url, recordingId: recordingId, locale: locale)
            
            
            // Update model on main actor
            switch result {
            case .success(let text):
                self.transcript = text
                self.transcriptionStatus = .completed
                let generatedTitle = await TitleGenerator.shared.generateTitleOrFallback(from: text, fallback: currentTitle)
                self.title = generatedTitle
                let generatedSummary = await SummaryGenerator.shared.generateSummaryOrFallback(from: text, fallback: "")
                self.summary = generatedSummary
            case .failure(let error):
                self.transcriptionStatus = .failed
                self.transcript = "Transcription failed: \(error.localizedDescription)"
            }
            try? modelContext.save()
        }
    }
    
    /// Performs transcription off the main actor
    private static nonisolated func performTranscription(url: URL?, recordingId: UUID, locale: Locale) async -> Result<String, Error> {
        guard let url = url else {
            print("Audio file not found for recording Hola \(recordingId)")
            return .failure(TranscriptionError.audioFileNotFound)
        }
        
        do {
            let transcribedText = try await SpeechTranscriber.shared.transcribe(audioFileURL: url, locale: locale)
            print("Transcription completed for recording \(recordingId)")
            return .success(transcribedText)
        } catch {
            print("Transcription failed for recording \(recordingId): \(error)")
            return .failure(error)
        }
    }
}

