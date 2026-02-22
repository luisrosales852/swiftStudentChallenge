//
//  SplashScreenView.swift
//  Swift Student Challenge app
//
//  Created by Papasito on 04/01/26.
//

import SwiftUI

struct OnboardingPopup: View {
    @State private var currentPage = 0
    @State private var appeared = false
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
        .frame(maxWidth: 400, maxHeight: 520)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                appeared = true
            }
        }
    }
}


struct AboutMePage: View {
    var body: some View {
        VStack(spacing: 28) {
            // Photo
            Image("LuisPhoto")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)

            Spacer()
                .frame(height: 20)

            VStack(spacing: 8) {
                Text("Hi, I'm Luis")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text("Im a 4th Semester CS student at @Tec de Monterrey in Monterrey Nuevo Leon, Part of the competitive robotics team @RoBorregos in the HRI team at Home competition and interested in Hackathons and Swift UI")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
}


struct AboutAlzheimersPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            VStack(spacing: 8) {
                Text("Understanding Alzheimer's (Brief Description)")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text("Alzheimer's disease affects over 55 million people worldwide. It gradually erases memories, making it harder for loved ones to recall their own life stories. By the time symptoms appear, years of precious memories may already be fading. It took my grandmother from my dads side 4 years ago and its now affecting my aunt. I used this app to capture her memories")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
}


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
                
                Text("Memory Trace helps you capture the voices and stories of your loved ones before they fade. Record conversations, get instant transcriptions, and translate between Spanish and English—preserving memories across generations and languages.")
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

