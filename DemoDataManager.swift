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
        
        if let recording1 = createDemoRecording(
            bundleAudioName: "TiaReginaMemoria1",
            audioExtension: "m4a",
            bundlePhotoNames: ["tia1", "tia2", "tia3"],
            photoExtension: "jpeg",
            placeholderTitle: "Memoria de Tía Regina",
            language: "es-ES",
            documentsURL: documentsURL
        ) {
            recording1.date = Date().addingTimeInterval(-86400 * 2)
            modelContext.insert(recording1)
        }
        
        if let recording2 = createDemoRecording(
            bundleAudioName: "TiaReginaMemoria2",
            audioExtension: "m4a",
            bundlePhotoNames: ["pinatas", "playa1"],
            photoExtension: "jpeg",
            placeholderTitle: "Memoria de Tía Regina 2",
            language: "es-ES",
            documentsURL: documentsURL
        ) {
            recording2.date = Date().addingTimeInterval(-86400)
            modelContext.insert(recording2)
        }
        
        if let recording3 = createDemoRecording(
            bundleAudioName: "audioabuela1",
            audioExtension: "m4a",
            bundlePhotoNames: ["abuela2"],
            photoExtension: "jpeg",
            placeholderTitle: "Memoria de Abuelita",
            language: "es-ES",
            documentsURL: documentsURL
        ) {
            recording3.date = Date().addingTimeInterval(-86400 * 3)
            modelContext.insert(recording3)
        }
        
        if let recording4 = createDemoRecording(
            bundleAudioName: "audioabuela2",
            audioExtension: "m4a",
            bundlePhotoNames: ["abuela1"],
            photoExtension: "jpeg",
            placeholderTitle: "Memoria de Abuelita 2",
            language: "es-ES",
            documentsURL: documentsURL
        ) {
            recording4.date = Date().addingTimeInterval(-86400 * 4)
            modelContext.insert(recording4)
        }
        
        if let recording5 = createDemoRecording(
            bundleAudioName: "audioabuela3",
            audioExtension: "m4a",
            bundlePhotoNames: [],
            photoExtension: "jpeg",
            placeholderTitle: "Memoria de Abuelita 3",
            language: "es-ES",
            documentsURL: documentsURL
        ) {
            recording5.date = Date().addingTimeInterval(-86400 * 5)
            modelContext.insert(recording5)
        }
        
        if let recording6 = createDemoRecording(
            bundleAudioName: "audioabuela4",
            audioExtension: "m4a",
            bundlePhotoNames: [],
            photoExtension: "jpeg",
            placeholderTitle: "Memoria de Abuelita 4",
            language: "es-ES",
            documentsURL: documentsURL
        ) {
            recording6.date = Date().addingTimeInterval(-86400 * 6)
            modelContext.insert(recording6)
        }
        
        if let recording7 = createDemoRecording(
            bundleAudioName: "audioabuela5",
            audioExtension: "m4a",
            bundlePhotoNames: [],
            photoExtension: "jpeg",
            placeholderTitle: "Memoria de Abuelita 5",
            language: "es-ES",
            documentsURL: documentsURL
        ) {
            recording7.date = Date().addingTimeInterval(-86400 * 7)
            modelContext.insert(recording7)
        }
        
        do {
            try modelContext.save()
            print("Demo data seeded successfully")
        } catch {
            print("Failed to save demo data: \(error)")
        }
    }
    
    private static func createDemoRecording(
        bundleAudioName: String,
        audioExtension: String,
        bundlePhotoNames: [String],
        photoExtension: String,
        placeholderTitle: String,
        language: String,
        documentsURL: URL
    ) -> Recording? {
        
        guard let audioFileName = copyBundleFile(
            name: bundleAudioName,
            extension: audioExtension,
            to: documentsURL
        ) else {
            print("Failed to copy audio file: \(bundleAudioName).\(audioExtension)")
            return nil
        }
        
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
        
        let audioURL = documentsURL.appendingPathComponent(audioFileName)
        let duration = getAudioDuration(url: audioURL)
        
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
    
    private static func copyBundleFile(
        name: String,
        extension ext: String,
        to documentsURL: URL
    ) -> String? {
        let uniqueName = "\(name)_\(UUID().uuidString.prefix(8)).\(ext)"
        let destinationURL = documentsURL.appendingPathComponent(uniqueName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            if ext == "m4a" {
                guard let asset = NSDataAsset(name: name) else {
                    print("Audio asset not found: \(name)")
                    return nil
                }
                try asset.data.write(to: destinationURL)
                return uniqueName
            }
            
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
    
    private static func getAudioDuration(url: URL) -> TimeInterval {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            return audioPlayer.duration
        } catch {
            print("Failed to get audio duration: \(error)")
            return 0
        }
    }
    
    static func resetSeedFlag() {
        UserDefaults.standard.removeObject(forKey: hasSeededKey)
    }
}

