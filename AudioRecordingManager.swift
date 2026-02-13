//
//  AudioRecorderManager.swift
//  Swift Student Challenge app
//
//  Created by LuisRosales on 06/02/26.
//

import Foundation
import AVFoundation

@MainActor
@Observable
final class AudioRecorderManager {
    static let shared = AudioRecorderManager()
    
    private var audioRecorder: AVAudioRecorder?
    private(set) var isRecording = false
    private(set) var currentRecordingURL: URL?
    private(set) var currentRecordingFileName: String?
    
    private init() {}
    
    /// Request microphone permission
    func requestPermission() async -> Bool {
        return await AVAudioApplication.requestRecordPermission()
    }
    
    func startRecording() async throws {
        // Request permission first
        let authorized = await requestPermission()
        guard authorized else {
            throw RecordingError.permissionDenied
        }
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        
        // Create unique filename
        let fileName = "recording_\(UUID().uuidString).m4a"
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw RecordingError.fileSystemError
        }
        let audioURL = documentsPath.appendingPathComponent(fileName)
        
        // Recording settings for high quality audio
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.prepareToRecord()
        let started = audioRecorder?.record() ?? false
        
        guard started else {
            throw RecordingError.recordingFailed
        }
        
        isRecording = true
        currentRecordingURL = audioURL
        currentRecordingFileName = fileName
    }
    
    /// Stop the current recording
    func stopRecording() -> (url: URL, fileName: String)? {
        guard isRecording, let recorder = audioRecorder else { return nil }
        
        recorder.stop()
        isRecording = false
        
        
        //Could be made simpler
        let result: (url: URL, fileName: String)?
        if let url = currentRecordingURL, let fileName = currentRecordingFileName {
            result = (url: url, fileName: fileName)
        } else {
            result = nil
        }
        
        audioRecorder = nil
        currentRecordingURL = nil
        currentRecordingFileName = nil
        
        return result
    }
    
    /// Cancel and delete the current recording
    func cancelRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        
        // Delete the file
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        isRecording = false
        audioRecorder = nil
        currentRecordingURL = nil
        currentRecordingFileName = nil
    }
    
    /// Delete a recording file
    static func deleteRecording(fileName: String) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let fileURL = documentsPath.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

enum RecordingError: LocalizedError {
    case permissionDenied
    case fileSystemError
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission was denied. Please enable it in Settings."
        case .fileSystemError:
            return "Could not access the file system to save the recording."
        case .recordingFailed:
            return "Failed to start recording."
        }
    }
}
