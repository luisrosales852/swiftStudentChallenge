//
//  MainScreen.swift
//  Swift Student Challenge app
//
//  Created by LuisRosales on 04/01/26.
//

import SwiftUI
import SwiftData

struct MainScreen: View {
    @Namespace private var glassNamespace
    @State private var navigateToRecordStory = false
    @Environment(\.modelContext) private var modelContext
    
    // Query saved recordings from SwiftData, sorted by date (newest first)
    @Query(sort: \Recording.date, order: .reverse) private var savedRecordings: [Recording]
    
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
                .fill(Color.purple.opacity(0.15))
                .blur(radius: 100)
                .frame(width: 300, height: 300)
                .offset(x: 100, y: 200)
            
            VStack(spacing: 20) {
                // Header with glass effect
                Text("Memory Trace")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Main action buttons with glass container
                GlassEffectContainer(spacing: 30) {
                    VStack(spacing: 20) {
                        NavigationButton(title: "Record Story", icon: "mic.circle.fill", color: .blue) {
                            navigateToRecordStory = true
                        }
                        
                        NavigationButton(title: "My Memories", icon: "photo.on.rectangle.angled", color: .purple) {
                            // Navigate to memories
                        }
                        
                        NavigationButton(title: "Pills Monitoring", icon: "pills.circle.fill", color: .green) {
                            // Navigate to pills monitoring
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Recent memories section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Memories")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    if savedRecordings.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "waveform.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("No recordings yet")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Tap \"Record Story\" to create your first memory")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(savedRecordings) { recording in
                                    NavigationLink(value: recording) {
                                        RecordingRow(recording: recording, onDelete: {
                                            deleteRecording(recording)
                                        })
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .navigationDestination(isPresented: $navigateToRecordStory) {
            RecordStoryView()
        }
        .navigationDestination(for: Recording.self) { recording in
            RecordingDetailView(recording: recording)
        }
    }
    
    private func deleteRecording(_ recording: Recording) {
        // Delete the audio file from disk
        AudioRecorderManager.deleteRecording(fileName: recording.audioFileName)
        // Delete from SwiftData
        modelContext.delete(recording)
    }
}

struct NavigationButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 50)
                
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(
                ZStack {
                    // Subtle color tint behind the glass
                    color.opacity(0.2)
                    
                    // Glass effect creates the modern liquid glass appearance
                    Color.clear
                }
            )
            .glassEffect(.regular.tint(color).interactive(), in: .rect(cornerRadius: 20))
        }
    }
}

struct RecordingRow: View {
    let recording: Recording
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recording.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(recording.formattedDate)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.white.opacity(0.6))
                
                Text(recording.formattedDuration)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Transcription status indicator
                transcriptionStatusView
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            
            // Show transcript preview only when completed
            if recording.transcriptionStatus == .completed && !recording.transcript.isEmpty {
                Text(recording.transcript)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            ZStack {
                // Subtle gradient for depth
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.04)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                Color.clear
            }
        )
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var transcriptionStatusView: some View {
        switch recording.transcriptionStatus {
        case .pending, .inProgress:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(.orange)
            }
            .padding(.trailing, 8)
            
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green.opacity(0.8))
                .font(.system(size: 14))
                .padding(.trailing, 8)
            
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red.opacity(0.8))
                .font(.system(size: 14))
                .padding(.trailing, 8)
        }
    }
}

#Preview {
    NavigationStack {
        MainScreen()
    }
}

