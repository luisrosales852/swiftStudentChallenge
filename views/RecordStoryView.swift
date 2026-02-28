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
    @State private var savedRecording: Recording?
    @State private var navigateToDetail = false
    @State private var showLanguageSelection = true
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.warmSand,
                    Color.softAmber.opacity(0.6),
                    Color.warmSand
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GeometryReader { geo in
                Circle()
                    .fill(Color.softTerracotta.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.3)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    
                    if isRecording {
                        Spacer()
                        Text("Recording your story...")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.warmBrown.opacity(0.7))
                        
                        SoundWaveView()
                            .padding(.horizontal, 20)
                        
                        Text(formatTime(recordingTime))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.warmBrown)
                            .padding(.vertical, 10)
                        
                        Button(action: toggleRecording) {
                            HStack(spacing: 15) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Stop Recording")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(18)
                        }
                        .glassEffect(.regular.tint(.deepTerracotta).interactive(), in: .rect(cornerRadius: 20))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                    } else {
                        HStack(spacing: 12) {
                            LanguageButton(
                                flag: "🇺🇸",
                                language: "English",
                                isSelected: languageChoice == "en-US",
                                action: { languageChoice = "en-US" }
                            )
                            
                            LanguageButton(
                                flag: "🇪🇸",
                                language: "Spanish",
                                isSelected: languageChoice == "es-ES",
                                action: { languageChoice = "es-ES" }
                            )
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        Button(action: toggleRecording) {
                            ZStack {
                                Circle()
                                    .fill(Color.softTerracotta.opacity(0.2))
                                    .frame(width: 200, height: 200)
                                    .blur(radius: 20)
                                
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.softTerracotta, .deepTerracotta],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 140, height: 140)
                                    
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: .softTerracotta.opacity(0.4), radius: 20, y: 10)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Text("Tap to record your story")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.warmBrown.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                    }
                    Spacer()
                }
                
                Spacer()
                
                if !isRecording {
                    VStack(spacing: 14) {
                        // Record button
                        Button(action: toggleRecording) {
                            HStack(spacing: 15) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Start Recording")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(18)
                        }
                        .glassEffect(.regular.tint(.softTerracotta).interactive(), in: .rect(cornerRadius: 20))
                        
                        if recordingTime > 0 {
                            Button(action: saveRecording) {
                                HStack(spacing: 15) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("Save Story")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(18)
                            }
                            .glassEffect(.regular.tint(.deepTerracotta).interactive(), in: .rect(cornerRadius: 20))
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    popToRoot()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.warmBrown)
                }
            }
        }
        .alert("Recording Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $navigateToDetail) {
            if let recording = savedRecording {
                RecordingDetailView(recording: recording, showPhotoPrompt: true)
            }
        }
        .confirmationDialog("What language will you be speaking?", isPresented: $showLanguageSelection, titleVisibility: .visible) {
            Button("🇺🇸 English") {
                languageChoice = "en-US"
            }
            Button("🇪🇸 Spanish") {
                languageChoice = "es-ES"
            }
        } message: {
            Text("This helps with accurate transcription")
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
            
            Task {
                await recording.startTranscription(modelContext: modelContext)
            }
            
            savedRecording = recording
            recordingTime = 0
            currentRecordingFileName = nil
            navigateToDetail = true
            
        } catch {
            errorMessage = "Failed to save recording: \(error.localizedDescription)"
            showingError = true
            return
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct LanguageButton: View {
    let flag: String
    let language: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(flag)
                Text(language)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .warmBrown)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .glassEffect(
            isSelected
                ? .regular.tint(.softTerracotta).interactive()
                : .regular.tint(.warmBrown.opacity(0.1)).interactive(),
            in: .capsule
        )
    }
}

#Preview {
    NavigationStack {
        RecordStoryView()
    }
}
