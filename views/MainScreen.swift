//
//  MainScreen.swift
//  Swift Student Challenge app
//
//  Created by LuisRosales on 04/01/26.
//

import SwiftUI
import SwiftData

// MARK: - Color Theme
extension Color {
    // Warm earthy palette
    static let warmSand = Color(red: 0.96, green: 0.93, blue: 0.88)
    static let softTerracotta = Color(red: 0.87, green: 0.58, blue: 0.47)
    static let deepTerracotta = Color(red: 0.76, green: 0.42, blue: 0.32)
    static let warmBrown = Color(red: 0.45, green: 0.32, blue: 0.25)
    static let softAmber = Color(red: 0.95, green: 0.85, blue: 0.70)
}

struct MainScreen: View {
    @Namespace private var glassNamespace
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    
    // Query saved recordings from SwiftData, sorted by date (newest first)
    @Query(sort: \Recording.date, order: .reverse) private var savedRecordings: [Recording]
    
    private var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            return savedRecordings
        }
        let lowercased = searchText.lowercased()
        return savedRecordings.filter { recording in
            recording.title.lowercased().contains(lowercased) ||
            recording.transcript.lowercased().contains(lowercased) ||
            recording.summary.lowercased().contains(lowercased)
        }
    }
    
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
                    .fill(Color.softTerracotta.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: geo.size.width * 0.6, y: -50)
                
                Circle()
                    .fill(Color.deepTerracotta.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: -50, y: geo.size.height * 0.7)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("Memory Trace")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.warmBrown)
                    
                    Text("Preserve what matters")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.warmBrown.opacity(0.6))
                }
                .padding(.top, 16)
                
                // Main action buttons
                VStack(spacing: 14) {
                    NavigationLink(value: AppRoute.record) {
                        ActionCardLabel(
                            title: "Record Story",
                            subtitle: "Capture a new memory",
                            icon: "mic.fill",
                            accentColor: .softTerracotta
                        )
                    }
                    .glassEffect(.regular.tint(.softTerracotta.opacity(0.3)).interactive(), in: .rect(cornerRadius: 20))
                    
                    HStack(spacing: 14) {
                        ActionCardSmall(
                            title: "Memories",
                            icon: "photo.stack.fill",
                            accentColor: .deepTerracotta
                        ) {
                            // Navigate to memories
                        }
                        
                        NavigationLink(value: AppRoute.chat) {
                            ActionCardSmallLabel(
                                title: "Chat",
                                icon: "bubble.left.and.bubble.right.fill",
                                accentColor: .warmBrown
                            )
                        }
                        .glassEffect(.regular.tint(Color.warmBrown.opacity(0.15)).interactive(), in: .rect(cornerRadius: 18))
                    }
                }
                .padding(.horizontal, 20)
                
                // Recent memories section
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Recent")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.warmBrown)
                        
                        Spacer()
                        
                        if !savedRecordings.isEmpty {
                            Text("\(savedRecordings.count) stories")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.warmBrown.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.warmBrown.opacity(0.5))
                        
                        TextField("Search memories...", text: $searchText)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.warmBrown)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.warmBrown.opacity(0.4))
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    
                    if savedRecordings.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "waveform.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.softTerracotta.opacity(0.6))
                            
                            Text("No recordings yet")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.warmBrown.opacity(0.7))
                            
                            Text("Tap \"Record Story\" to capture\nyour first memory")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.warmBrown.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    }
                    else if filteredRecordings.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.softTerracotta.opacity(0.6))
                            
                            Text("No memories found")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.warmBrown.opacity(0.7))
                            
                            Text("No results for \"\(searchText)\"")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.warmBrown.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    }
                    else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredRecordings) { recording in
                                    NavigationLink(value: recording) {
                                        RecordingRow(recording: recording, onDelete: {
                                            deleteRecording(recording)
                                        })
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func deleteRecording(_ recording: Recording) {
        AudioRecorderManager.deleteRecording(fileName: recording.audioFileName)
        modelContext.delete(recording)
    }
}

// MARK: - Action Card (Large)

struct ActionCardLabel: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.warmBrown.opacity(0.4))
        }
        .padding(18)
    }
}

struct ActionCardSmall: View {
    let title: String
    let icon: String
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .glassEffect(.regular.tint(accentColor.opacity(0.15)).interactive(), in: .rect(cornerRadius: 18))
    }
}

// Label version of ActionCardSmall for use inside NavigationLink
struct ActionCardSmallLabel: View {
    let title: String
    let icon: String
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

struct RecordingRow: View {
    let recording: Recording
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(recording.languageFlag)
                    .font(.system(size: 18))
                
                Text(recording.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.warmBrown)
                    .lineLimit(1)
                
                Spacer()
                
                Text(recording.formattedDate)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.warmBrown.opacity(0.5))
            }
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                    Text(recording.formattedDuration)
                        .font(.system(size: 14, design: .rounded))
                }
                .foregroundColor(.softTerracotta)
                
                Spacer()
                
                transcriptionStatusView
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.6))
                }
            }
            
            // Transcript preview
            if recording.transcriptionStatus == .completed && !recording.transcript.isEmpty {
                Text(recording.transcript)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.warmBrown.opacity(0.5))
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var transcriptionStatusView: some View {
        switch recording.transcriptionStatus {
        case .pending, .inProgress:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(.softTerracotta)
            }
            .padding(.trailing, 8)
            
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green.opacity(0.7))
                .font(.system(size: 14))
                .padding(.trailing, 8)
            
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red.opacity(0.7))
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
