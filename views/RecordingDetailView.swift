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
import PhotosUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

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
    
    // Photo picker state
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Warm gradient background
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
            
            // Subtle decorative shapes
            GeometryReader { geo in
                Circle()
                    .fill(Color.softTerracotta.opacity(0.12))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geo.size.width * 0.7, y: 50)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(recording.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.warmBrown)
                    
                    HStack(spacing: 16) {
                        Label(recording.formattedDuration, systemImage: "waveform")
                        Label(recording.formattedDate, systemImage: "calendar")
                    }
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.warmBrown.opacity(0.6))
                }
                .padding(.top, 20)
                
                // Audio player timeline
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Play/Pause button
                        Button(action: togglePlayback) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 54, height: 54)
                                
                                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Timeline slider and time labels
                        VStack(spacing: 4) {
                            Slider(
                                value: Binding(
                                    get: { isDraggingSlider ? sliderValue : playerManager.currentTime },
                                    set: { newValue in
                                        sliderValue = newValue
                                    }
                                ),
                                in: 0...max(playerManager.duration, 0.01),
                                onEditingChanged: { editing in
                                    if editing {
                                        // Started dragging
                                        wasPlayingBeforeDrag = playerManager.isPlaying
                                        sliderValue = playerManager.currentTime
                                        isDraggingSlider = true
                                        playerManager.pause()
                                    } else {
                                        // Finished dragging
                                        playerManager.seek(to: sliderValue)
                                        isDraggingSlider = false
                                        if wasPlayingBeforeDrag {
                                            playerManager.startPlayback()
                                        }
                                    }
                                }
                            )
                            .tint(.white)
                            
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
                .glassEffect(.regular.tint(.softTerracotta).interactive(), in: .rect(cornerRadius: 16))
                .padding(.horizontal, 20)
                
                // Transcript section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Transcript")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.warmBrown)
                        
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
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    .translationPresentation(isPresented: $showTranslation, text: recording.transcript)
                }
                
                // Photos section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Photos")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.warmBrown)
                        
                        Spacer()
                        Menu {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                            }
                            
                            PhotosPicker(selection: $selectedPhotoItems, matching: .images) {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add")
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                        .glassEffect(.regular.tint(.softTerracotta).interactive(), in: .capsule)
                    }
                    .padding(.horizontal, 20)
                    
                    // Photos grid
                    photosGrid
                        .padding(.horizontal, 20)
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
                    .foregroundColor(.warmBrown)
                }
            }
        }
        .onAppear {
            // Debug: Check if audio file exists
            if let url = recording.audioFileURL {
                let exists = FileManager.default.fileExists(atPath: url.path)
                print("DEBUG - Audio file: \(url.lastPathComponent), exists: \(exists)")
                print("DEBUG - Full path: \(url.path)")
            } else {
                print("DEBUG - No audio URL for recording: \(recording.title)")
            }
            
            // Retry transcription if it was pending
            if recording.transcriptionStatus == .pending {
                recording.startTranscription(modelContext: modelContext)
            }
        }
        .onDisappear {
            playerManager.stop()
        }
        .onChange(of: selectedPhotoItems) {
            Task {
                await loadSelectedPhotos()
            }
        }
        .onChange(of: capturedImage) {
            if let image = capturedImage {
                saveCapturedPhoto(image)
                capturedImage = nil
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage)
        }
    }
    
    @ViewBuilder
    private var transcriptionStatusBadge: some View {
        switch recording.transcriptionStatus {
        case .pending, .inProgress:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.softTerracotta)
                Text("Transcribing...")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(.warmBrown.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.6))
            .clipShape(Capsule())
            
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
            .glassEffect(.regular.tint(.softTerracotta), in: .capsule)
            
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
                    .tint(.softTerracotta)
                
                Text("Transcribing your recording...")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.warmBrown.opacity(0.7))
                
                Text("This may take a moment depending on the length of your recording.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.warmBrown.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            
        case .completed:
            if recording.transcript.isEmpty {
                Text("No speech detected in this recording.")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.warmBrown.opacity(0.6))
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text(recording.transcript)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(.warmBrown)
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
                    .glassEffect(.regular.tint(.softTerracotta).interactive(), in: .capsule)
                }
            }
            
        case .failed:
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.red.opacity(0.8))
                
                Text("Transcription Failed")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.warmBrown)
                
                Text(recording.transcript)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.warmBrown.opacity(0.6))
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
                .glassEffect(.regular.tint(.softTerracotta).interactive(), in: .capsule)
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
    
    @ViewBuilder
    private var photosGrid: some View {
        if recording.photoFileNames.isEmpty && !isLoadingPhotos {
            Text("No photos attached")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.warmBrown.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Show loading indicator if photos are being processed
                    if isLoadingPhotos {
                        ProgressView()
                            .tint(.softTerracotta)
                            .frame(width: 80, height: 80)
                    }
                    
                    // Show existing photos
                    ForEach(Array(recording.photoFileURLs.enumerated()), id: \.offset) { index, url in
                        PhotoThumbnail(
                            url: url,
                            onDelete: { recording.removePhoto(at: index) }
                        )
                    }
                }
            }
        }
    }
    
    /// Load selected photos, convert to JPEG, and save
    private func loadSelectedPhotos() async {
        guard !selectedPhotoItems.isEmpty else { return }
        
        isLoadingPhotos = true
        
        for item in selectedPhotoItems {
            // Load the image data from PhotosPickerItem
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                _ = recording.addPhoto(jpegData)
            }
        }
        
        // Clear selection after processing
        selectedPhotoItems.removeAll()
        isLoadingPhotos = false
    }
    
    /// Save a photo captured from the camera
    private func saveCapturedPhoto(_ image: UIImage) {
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            _ = recording.addPhoto(jpegData)
        }
    }
}

struct PhotoThumbnail: View {
    let url: URL
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Load image from file URL
            if let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // Placeholder if image fails to load
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.warmBrown.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.warmBrown.opacity(0.4))
                    }
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.softTerracotta))
            }
            .offset(x: 6, y: -6)
        }
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
