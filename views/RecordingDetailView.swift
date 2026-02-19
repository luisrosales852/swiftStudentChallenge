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

@Observable
final class AudioPlayerManager: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var currentURL: URL?
    
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    
    func play(url: URL) {
        if let _ = player, currentURL == url {
            startPlayback()
            return
        }
        
        // Otherwise load a new file
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            currentURL = url
            duration = player?.duration ?? 0
            currentTime = 0
            
            startPlayback()
        } catch {
            print("Playback failed: \(error)")
        }
    }
    
    func startPlayback() {
        player?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        player?.stop()
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        let clampedTime = max(0, min(time, duration))
        player?.currentTime = clampedTime
        currentTime = clampedTime
    }
        
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
}

struct RecordingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var recording: Recording
    
    @State private var playerManager = AudioPlayerManager()
    @State private var showTranslation = false
    @State private var isDraggingSlider = false
    @State private var sliderValue: TimeInterval = 0
    @State private var wasPlayingBeforeDrag = false
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
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
                
                // Audio player timeline
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Play/Pause button
                        Button(action: togglePlayback) {
                            Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        
                        // Timeline slider and time labels
                        VStack(spacing: 4) {
                            Slider(
                                value: Binding(
                                    get: { isDraggingSlider ? sliderValue : playerManager.currentTime },
                                    set: { newValue in
                                        sliderValue = newValue
                                        if isDraggingSlider {
                                            playerManager.seek(to: newValue)
                                        }
                                    }
                                ),
                                in: 0...max(playerManager.duration, 0.01)
                            )
                            .tint(.white)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if !isDraggingSlider {
                                            isDraggingSlider = true
                                            wasPlayingBeforeDrag = playerManager.isPlaying
                                            sliderValue = playerManager.currentTime
                                            playerManager.pause()
                                        }
                                    }
                                    .onEnded { _ in
                                        playerManager.seek(to: sliderValue)
                                        isDraggingSlider = false
                                        if wasPlayingBeforeDrag{
                                            playerManager.startPlayback()
                                        }
                                    }
                            )
                            
                            // Time labels
                            HStack {
                                Text(formatTime(isDraggingSlider ? sliderValue : playerManager.currentTime))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Text(formatTime(playerManager.duration))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
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
            playerManager.stop()
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
        if playerManager.isPlaying {
            playerManager.pause()
        } else {
            guard let url = recording.audioFileURL else {
                print("No audio file URL")
                return
            }
            playerManager.play(url: url)
        }
    }
    
    private func retryTranscription() {
        recording.transcriptionStatus = .pending
        recording.transcript = ""
        recording.startTranscription(modelContext: modelContext)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
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
