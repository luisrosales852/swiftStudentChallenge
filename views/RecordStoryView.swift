//
//  RecordStoryView.swift
//  Swift Student Challenge app
//
//  Created by LuisRosales on 04/01/26.
//

import SwiftUI
import SwiftData


struct RecordStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.popToRoot) private var popToRoot
    
    private var audioRecorder = AudioRecorderManager.shared
    
    
    
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var currentRecordingFileName: String?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var languageChoice: String = "en-US"
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
  
                // Recording indicator
                VStack(spacing: 20) {
                    
                    if isRecording {
                        Spacer()
                        // Recording status message
                        Text("Recording your story...")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                        
                        // Sound waves visualization
                        SoundWaveView()
                            .padding(.horizontal, 20)
                        
                        // Time elapsed
                        Text(formatTime(recordingTime))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.vertical, 10)
                        
                        // Stop recording button
                        Button(action: toggleRecording) {
                            HStack(spacing: 15) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                
                                Text("Stop Recording")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                        }
                        .glassEffect(.regular.tint(.black).interactive(), in: .rect(cornerRadius: 20))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                    } else {
                        HStack(spacing: 12) {
                            Button {
                                languageChoice = "en-US"
                            } label: {
                                HStack(spacing: 8) {
                                    Text("🇺🇸")
                                    Text("English")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(languageChoice == "en-US" ? .white : .black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .glassEffect(
                                languageChoice == "en-US"
                                    ? .regular.tint(.black).interactive()
                                    : .regular.interactive(),
                                in: .capsule
                            )
                            
                            Button {
                                languageChoice = "es-ES"
                            } label: {
                                HStack(spacing: 8) {
                                    Text("🇪🇸")
                                    Text("Spanish")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(languageChoice == "es-ES" ? .white : .black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .glassEffect(
                                languageChoice == "es-ES"
                                    ? .regular.tint(.black).interactive()
                                    : .regular.interactive(),
                                in: .capsule
                            )
                        }
                        .padding(.top, 20)
                        Spacer()
                        // Microphone icon
                        ZStack {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .glassEffect(.regular.tint(.black).interactive(), in: .circle)
                        
                        // Instructions
                        Text("Tap to record your story")
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                }
                
                Spacer()
                
                // Control buttons (only shown when NOT recording)
                if !isRecording {
                    VStack(spacing: 15) {
                        // Record button
                        Button(action: toggleRecording) {
                            HStack(spacing: 15) {
                                Image(systemName: "mic.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                
                                Text("Start Recording")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                        }
                        .glassEffect(.regular.tint(.black).interactive(), in: .rect(cornerRadius: 20))
                        
                        // Save button (only shown when has recorded)
                        if recordingTime > 0 {
                            Button(action: saveRecording) {
                                HStack(spacing: 15) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                    
                                    Text("Save Story")
                                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(20)
                            }
                            .glassEffect(.regular.tint(.black).interactive(), in: .rect(cornerRadius: 20))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Record Story")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Recording Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        Task {
            do {
                try await audioRecorder.startRecording()
                currentRecordingFileName = audioRecorder.currentRecordingFileName
                isRecording = true
                recordingTime = 0
                
                // Start timer for recording duration
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    MainActor.assumeIsolated{
                        recordingTime += 1
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        
        _ = audioRecorder.stopRecording()
        isRecording = false
    }
    
    private func saveRecording() {
        guard let fileName = currentRecordingFileName else {
            errorMessage = "No recording to save"
            showingError = true
            return
        }
        
        // Create a new Recording and save to SwiftData
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let title = "Story - \(dateFormatter.string(from: Date()))"
        
        let recording = Recording(
            title: title,
            duration: recordingTime,
            transcript: "",
            audioFileName: fileName,
            languageIdentifier: languageChoice,
        )
        
        modelContext.insert(recording)
        
        do {
            try modelContext.save()
            print("Recording saved: \(title) (\(recordingTime) seconds)")
            
            // Start async transcription in background
            recording.startTranscription(modelContext: modelContext)
            
        } catch {
            errorMessage = "Failed to save recording: \(error.localizedDescription)"
            showingError = true
            return
        }
        
        // Reset and go back to main screen
        recordingTime = 0
        currentRecordingFileName = nil
        popToRoot()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        RecordStoryView()
    }
}
