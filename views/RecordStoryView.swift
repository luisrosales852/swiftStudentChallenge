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
    
    private var audioRecorder = AudioRecorderManager.shared
    
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var currentRecordingFileName: String?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Ambient light effects
            Circle()
                .fill(Color.blue.opacity(0.15))
                .blur(radius: 100)
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.red.opacity(0.15))
                .blur(radius: 100)
                .frame(width: 300, height: 300)
                .offset(x: 100, y: 200)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Recording indicator
                VStack(spacing: 20) {
                    if isRecording {
                        // Recording status message
                        Text("Recording your story...")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Sound waves visualization
                        SoundWaveView()
                            .padding(.horizontal, 20)
                        
                        // Time elapsed
                        Text(formatTime(recordingTime))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                        
                        // 4. Stop recording button
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
                            .background(
                                ZStack {
                                    Color.red.opacity(0.3)
                                    Color.clear
                                }
                            )
                            .glassEffect(.regular.tint(.red).interactive(), in: .rect(cornerRadius: 20))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                    } else {
                        // Pulsing microphone icon (when not recording)
                        ZStack {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(
                            ZStack {
                                Color.white.opacity(0.05)
                                Color.clear
                            }
                        )
                        .glassEffect(.regular.interactive(), in: .circle)
                        
                        // Instructions
                        Text("Tap to record your story")
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
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
                            .background(
                                ZStack {
                                    Color.blue.opacity(0.3)
                                    Color.clear
                                }
                            )
                            .glassEffect(.regular.tint(.blue).interactive(), in: .rect(cornerRadius: 20))
                        }
                        
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
                                .background(
                                    ZStack {
                                        Color.green.opacity(0.3)
                                        Color.clear
                                    }
                                )
                                .glassEffect(.regular.tint(.green).interactive(), in: .rect(cornerRadius: 20))
                            }
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
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
                    recordingTime += 1
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
            audioFileName: fileName
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
        
        // Reset and go back
        recordingTime = 0
        currentRecordingFileName = nil
        dismiss()
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
