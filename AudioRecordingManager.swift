//
//  AudioRecordingManager.swift
//  Swift Student Challenge Real
//
//  Created by LuisRosales on 04/01/26.
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
    
    func requestPermission() async -> Bool {
        return await AVAudioApplication.requestRecordPermission()
    }
    
    func startRecording() async throws {
        let authorized = await requestPermission()
        guard authorized else {
            throw RecordingError.permissionDenied
        }
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        
        let fileName = "recording_\(UUID().uuidString).m4a"
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw RecordingError.fileSystemError
        }
        let audioURL = documentsPath.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
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
    
    func stopRecording() -> (url: URL, fileName: String)? {
        guard isRecording, let recorder = audioRecorder else { return nil }
        
        recorder.stop()
        isRecording = false
        
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
    
    func cancelRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        isRecording = false
        audioRecorder = nil
        currentRecordingURL = nil
        currentRecordingFileName = nil
    }
    
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
