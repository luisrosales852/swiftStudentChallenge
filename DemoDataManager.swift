//
//  DemoDataManager.swift
//  Swift Student Challenge Real
//
//  Handles seeding demo recordings on first launch
//

import Foundation
import SwiftData
import AVFoundation
import UIKit

struct DemoDataManager {
    
    private static let hasSeededKey = "hasSeededDemoData"
    
    static func seedIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: hasSeededKey) else {
            return
        }
        
        seedDemoRecordings(modelContext: modelContext)
        
        UserDefaults.standard.set(true, forKey: hasSeededKey)
    }
    
    private static func seedDemoRecordings(modelContext: ModelContext) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Demo Recording 1: TiaReginaMemoria1 with tia1, tia2, tia3
        if let recording1 = createDemoRecording(
            bundleAudioName: "TiaReginaMemoria1",
            audioExtension: "m4a",
            bundlePhotoNames: ["tia1", "tia2", "tia3"],
            photoExtension: "jpeg",
            placeholderTitle: "Memoria de Tía Regina",
            language: "es-ES",
            documentsURL: documentsURL
        ) {
            // Offset the date so it appears older
            recording1.date = Date().addingTimeInterval(-86400 * 2) // 2 days ago
            modelContext.insert(recording1)
        }
        
        // Demo Recording 2: TiaReginaMemoria2 with pinatas, playa1
        if let recording2 = createDemoRecording(
            bundleAudioName: "TiaReginaMemoria2",
            audioExtension: "m4a",
            bundlePhotoNames: ["pinatas", "playa1"],
            photoExtension: "jpeg",
            placeholderTitle: "Memoria de Tía Regina 2",
            language: "es-ES",
            documentsURL: documentsURL
        ) {
            // Offset the date so it appears older but more recent than recording 1
            recording2.date = Date().addingTimeInterval(-86400) // 1 day ago
            modelContext.insert(recording2)
        }
        
        // Save the context
        do {
            try modelContext.save()
            print("Demo data seeded successfully")
        } catch {
            print("Failed to save demo data: \(error)")
        }
    }
    
    /// Creates a single demo recording by copying files from bundle to documents
    private static func createDemoRecording(
        bundleAudioName: String,
        audioExtension: String,
        bundlePhotoNames: [String],
        photoExtension: String,
        placeholderTitle: String,
        language: String,
        documentsURL: URL
    ) -> Recording? {
        
        // Copy audio file from bundle to documents
        guard let audioFileName = copyBundleFile(
            name: bundleAudioName,
            extension: audioExtension,
            to: documentsURL
        ) else {
            print("Failed to copy audio file: \(bundleAudioName).\(audioExtension)")
            return nil
        }
        
        // Copy photo files from bundle to documents
        var photoFileNames: [String] = []
        for photoName in bundlePhotoNames {
            if let photoFileName = copyBundleFile(
                name: photoName,
                extension: photoExtension,
                to: documentsURL
            ) {
                photoFileNames.append(photoFileName)
            } else {
                print("Failed to copy photo file: \(photoName).\(photoExtension)")
            }
        }
        
        // Get audio duration
        let audioURL = documentsURL.appendingPathComponent(audioFileName)
        let duration = getAudioDuration(url: audioURL)
        
        // Create the recording with pending transcription status
        let recording = Recording(
            title: placeholderTitle,
            duration: duration,
            transcript: "",
            audioFileName: audioFileName,
            languageIdentifier: language,
            summary: "",
            photoFileNames: photoFileNames
        )
        
        return recording
    }
    
    /// Copies a file from the asset catalog to the documents directory
    /// - Returns: The new filename in documents, or nil if failed
    private static func copyBundleFile(
        name: String,
        extension ext: String,
        to documentsURL: URL
    ) -> String? {
        // Create unique filename to avoid conflicts
        let uniqueName = "\(name)_\(UUID().uuidString.prefix(8)).\(ext)"
        let destinationURL = documentsURL.appendingPathComponent(uniqueName)
        
        do {
            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Handle audio files (Data Sets in asset catalog)
            if ext == "m4a" {
                guard let asset = NSDataAsset(name: name) else {
                    print("Audio asset not found: \(name)")
                    return nil
                }
                try asset.data.write(to: destinationURL)
                return uniqueName
            }
            
            // Handle image files (Image Sets in asset catalog)
            if ext == "jpeg" || ext == "jpg" || ext == "png" {
                guard let image = UIImage(named: name),
                      let imageData = image.jpegData(compressionQuality: 0.9) else {
                    print("Image asset not found: \(name)")
                    return nil
                }
                try imageData.write(to: destinationURL)
                return uniqueName
            }
            
            print("Unsupported file extension: \(ext)")
            return nil
        } catch {
            print("Failed to copy asset \(name).\(ext): \(error)")
            return nil
        }
    }
    
    /// Gets the duration of an audio file
    private static func getAudioDuration(url: URL) -> TimeInterval {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            return audioPlayer.duration
        } catch {
            print("Failed to get audio duration: \(error)")
            return 0
        }
    }
    
    /// Resets the seeded flag (useful for testing)
    static func resetSeedFlag() {
        UserDefaults.standard.removeObject(forKey: hasSeededKey)
    }
}

