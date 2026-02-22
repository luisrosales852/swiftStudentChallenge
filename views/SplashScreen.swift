//
//  SplashScreenView.swift
//  Swift Student Challenge app
//
//  Created by Papasito on 04/01/26.
//

import SwiftUI

struct OnboardingPopup: View {
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    private let totalPages = 3
    
    var body: some View {
        VStack(spacing: 20) {
            // Page content
            TabView(selection: $currentPage) {
                AboutMePage()
                    .tag(0)
                
                AboutAlzheimersPage()
                    .tag(1)
                
                AboutAppPage()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            .frame(height: 400)
            
            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(duration: 0.3), value: currentPage)
                }
            }
            
            // Navigation buttons
            HStack {
                // Back button - only visible after first page
                if currentPage > 0 {
                    Button(action: {
                        withAnimation {
                            currentPage -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .glassEffect()
                } else {
                    Color.clear
                        .frame(width: 90, height: 40)
                }
                
                Spacer()
                
                // Next or Get Started button
                Button(action: {
                    if currentPage < totalPages - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    HStack {
                        Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                        if currentPage < totalPages - 1 {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .glassEffect()
            }
        }
        .padding(24)
        .frame(maxWidth: 380)
        .glassEffect()
    }
}

// MARK: - Page 1: About Me

struct AboutMePage: View {
    var body: some View {
        VStack(spacing: 20) {
            // Photo placeholder
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                
                // TODO: Replace with actual image:
                // Image("your_photo")
                //     .resizable()
                //     .scaledToFill()
                //     .frame(width: 120, height: 120)
                //     .clipShape(Circle())
            }
            
            VStack(spacing: 8) {
                Text("Hi, I'm [Your Name]")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text("[Your bio goes here - a brief introduction about yourself and why you created this app.]")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Page 2: About Alzheimer's

struct AboutAlzheimersPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            VStack(spacing: 8) {
                Text("Understanding Alzheimer's")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text("[Description about Alzheimer's disease - what it is, how it affects memory, and why preserving family stories matters.]")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Page 3: About the App

struct AboutAppPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Memory Trace")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text("[Description of what your app does - recording stories, transcribing, and preserving memories.]")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Feature highlights
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "mic.fill", text: "Record family stories")
                FeatureRow(icon: "text.quote", text: "Automatic transcription")
                FeatureRow(icon: "globe", text: "Spanish & English support")
            }
        }
        .padding(.horizontal)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        OnboardingPopup {
            print("Onboarding complete")
        }
    }
}
