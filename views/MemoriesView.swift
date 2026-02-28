//
//  MemoriesView.swift
//  Swift Student Challenge Real
//
//  Created by Luis on 24/02/26.
//

import SwiftUI
import SwiftData

struct PhotoItem: Identifiable {
    let recording: Recording
    let photoURL: URL
    let isFirstInRecording: Bool
    
    /// Stable ID derived from recording and photo URL
    var id: String {
        "\(recording.id.uuidString)-\(photoURL.lastPathComponent)"
    }
}

struct MemoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recording.date, order: .reverse) private var recordings: [Recording]
    
    @State private var currentIndex: Int = 0
    @State private var navigateToRecording: Recording?
    
    private var photoItems: [PhotoItem] {
        var items: [PhotoItem] = []
        for recording in recordings {
            let urls = recording.photoFileURLs
            for (index, url) in urls.enumerated() {
                let item = PhotoItem(
                    recording: recording,
                    photoURL: url,
                    isFirstInRecording: index == 0
                )
                items.append(item)
            }
        }
        return items
    }
    
    private var currentRecording: Recording? {
        guard currentIndex >= 0 && currentIndex < photoItems.count else { return nil }
        return photoItems[currentIndex].recording
    }
    
    private var showSeparator: Bool {
        guard currentIndex >= 0 && currentIndex < photoItems.count else { return false }
        return photoItems[currentIndex].isFirstInRecording && currentIndex > 0
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if photoItems.isEmpty {
                emptyStateView
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(photoItems.enumerated()), id: \.element.id) { index, item in
                        PhotoPageView(
                            item: item,
                            showSeparator: item.isFirstInRecording && index > 0,
                            onTap: {
                                navigateToRecording = item.recording
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .ignoresSafeArea()
                
                headerOverlay
            }
            
            closeButton
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $navigateToRecording) { recording in
            RecordingDetailView(recording: recording)
        }
    }
        
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No Photos Yet")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Add photos to your recordings\nto see them here")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    private var headerOverlay: some View {
        VStack {
            if let recording = currentRecording {
                Button {
                    navigateToRecording = recording
                } label: {
                    VStack(spacing: 4) {
                        Text(recording.title)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(recording.formattedDate)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.top, 60)
            }
            
            Spacer()
            
            Text("\(currentIndex + 1) of \(photoItems.count)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 100)
        }
    }
    
    private var closeButton: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.leading, 20)
                .padding(.top, 60)
                
                Spacer()
            }
            Spacer()
        }
    }
}

struct PhotoPageView: View {
    let item: PhotoItem
    let showSeparator: Bool
    let onTap: () -> Void
    
    @State private var currentZoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0
    
    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 4.0
    
    var body: some View {
        ZStack {
            if showSeparator {
                HStack {
                    Rectangle()
                        .fill(Color.softTerracotta)
                        .frame(width: 4)
                        .padding(.vertical, 100)
                    Spacer()
                }
            }
            
            if let uiImage = UIImage(contentsOfFile: item.photoURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(currentZoom)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let newZoom = lastZoom * value.magnification
                                currentZoom = min(max(newZoom, minZoom), maxZoom)
                            }
                            .onEnded { _ in
                                lastZoom = currentZoom
                                
                                if currentZoom < 1.1 {
                                    withAnimation(.spring(duration: 0.3)) {
                                        currentZoom = 1.0
                                        lastZoom = 1.0
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(duration: 0.3)) {
                            if currentZoom > 1.0 {
                                currentZoom = 1.0
                                lastZoom = 1.0
                            } else {
                                currentZoom = 2.5
                                lastZoom = 2.5
                            }
                        }
                    }
                    .onTapGesture(count: 1) {
                        if currentZoom == 1.0 {
                            onTap()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Unable to load photo")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}


