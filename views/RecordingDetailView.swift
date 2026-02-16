//
//  RecordingDetailView.swift
//  Swift Student Challenge app
//
//  Created by LuisRosales on 06/02/26.
//

import SwiftUI
import SwiftData
import AVFoundation
import Translation

struct RecordingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var recording: Recording
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var showTranslation = false
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Recording info header
                VStack(spacing: 8) {
                    Text(recording.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 16) {
                        Label(recording.formattedDuration, systemImage: "waveform")
                        Label(recording.formattedDate, systemImage: "calendar")
                    }
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
                }
                .padding(.top, 20)
                
                // Play button
                Button(action: togglePlayback) {
                    HStack(spacing: 12) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                        
                        Text(isPlaying ? "Pause" : "Play Recording")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                }
                .glassEffect(.regular.tint(.black).interactive(), in: .rect(cornerRadius: 16))
                .padding(.horizontal, 20)
                
                // Transcript section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Transcript")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        transcriptionStatusBadge
                    }
                    .padding(.horizontal, 20)
                    
                    // Transcript content
                    ScrollView {
                        transcriptContent
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    .translationPresentation(isPresented: $showTranslation, text: recording.transcript)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Recording")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .onAppear {
            // Retry transcription if it was pending
            if recording.transcriptionStatus == .pending {
                recording.startTranscription(modelContext: modelContext)
            }
        }
        .onDisappear {
            audioPlayer?.stop()
        }
    }
    
    @ViewBuilder
    private var transcriptionStatusBadge: some View {
        switch recording.transcriptionStatus {
        case .pending, .inProgress:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.black)
                Text("Transcribing...")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(.black.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular.interactive(), in: .capsule)
            
        case .completed:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                Text("Ready")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular.tint(.black), in: .capsule)
            
        case .failed:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                Text("Failed")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular.tint(.red), in: .capsule)
        }
    }
    
    @ViewBuilder
    private var transcriptContent: some View {
        switch recording.transcriptionStatus {
        case .pending, .inProgress:
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.black)
                
                Text("Transcribing your recording...")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.black.opacity(0.7))
                
                Text("This may take a moment depending on the length of your recording.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.black.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            
        case .completed:
            if recording.transcript.isEmpty {
                Text("No speech detected in this recording.")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text(recording.transcript)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(.black)
                        .lineSpacing(6)
                    
                    Button(action: { showTranslation = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "translate")
                            Text("Translate")
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .glassEffect(.regular.tint(.black).interactive(), in: .capsule)
                }
            }
            
        case .failed:
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.red.opacity(0.8))
                
                Text("Transcription Failed")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                
                Text(recording.transcript)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Button(action: retryTranscription) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .glassEffect(.regular.tint(.black).interactive(), in: .capsule)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            playRecording()
        }
    }
    
    private func playRecording() {
        guard let url = recording.audioFileURL else {
            print("No audio file URL")
            return
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Audio file does not exist at: \(url.path)")
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play recording: \(error)")
        }
    }
    
    private func retryTranscription() {
        recording.transcriptionStatus = .pending
        recording.transcript = ""
        recording.startTranscription(modelContext: modelContext)
    }
}

#Preview {
    NavigationStack {
        RecordingDetailView(recording: Recording(
            title: "Test Story",
            duration: 125,
            transcript: "This is a sample transcript of a recording.",
            audioFileName: "test.m4a"
        ))
    }
}
