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
    
    private let totalPages = 4
    
    var body: some View {
        VStack(spacing: 20) {
            // Page content
            TabView(selection: $currentPage) {
                AboutMePage()
                    .tag(0)
                
                AboutAlzheimersPage()
                    .tag(1)
                
                GrandmaStoryPage()
                    .tag(2)
                
                AboutAppPage()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            .frame(height: 400)
            
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.softTerracotta : Color.warmBrown.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(duration: 0.3), value: currentPage)
                }
            }
            
            HStack {
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
                        .foregroundStyle(Color.warmBrown)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .glassEffect(.regular.tint(.softTerracotta.opacity(0.2)).interactive(), in: .capsule)
                } else {
                    Color.clear
                        .frame(width: 90, height: 40)
                }
                
                Spacer()
                
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
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .glassEffect(.regular.tint(.softTerracotta).interactive(), in: .capsule)
            }
        }
        .padding(24)
        .frame(maxWidth: 400, maxHeight: 520)
        .background(
            LinearGradient(
                colors: [Color.warmSand, Color.softAmber.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .warmBrown.opacity(0.2), radius: 20, y: 10)
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
            Image("LuisPhoto")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)

            Spacer()
                .frame(height: 20)

            VStack(spacing: 10) {
                Text("Hi, I'm Luis")
                    .font(.title2.bold())
                    .foregroundColor(.warmBrown)
                    .multilineTextAlignment(.center)
                
                Text("I'm a 4th Semester CS student at Tec de Monterrey in Monterrey, Nuevo León. Part of the competitive robotics team RoBorregos in the HRI team, and passionate about Hackathons and SwiftUI.")
                    .font(.subheadline)
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
}


struct AboutAlzheimersPage: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.deepTerracotta.opacity(0.2), Color.softTerracotta.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.deepTerracotta, .softTerracotta],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 10) {
                Text("Understanding Alzheimer's")
                    .font(.title2.bold())
                    .foregroundColor(.warmBrown)
                    .multilineTextAlignment(.center)
                
                Text("Alzheimer's disease affects over 55 million people worldwide. It gradually erases memories, making it harder for loved ones to recall their own life stories. It took my grandmother 4 years ago and is now affecting my aunt. I used this app to capture her memories.")
                    .font(.subheadline)
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
}


struct GrandmaStoryPage: View {
    var body: some View {
        VStack(spacing: 20) {
            // Grandma photo
            Image("abuela3")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(spacing: 12) {
                Text("Why I Built This")
                    .font(.title2.bold())
                    .foregroundColor(.warmBrown)
                    .multilineTextAlignment(.center)
                
                Text("When I was little, I slept in my grandma's bed with her because I was afraid of the dark. She made me feel safe. Alzheimer's took her when I was 15, and I was never able to fully hear—or even have the courage to ask for—her stories. I was too young.")
                    .font(.subheadline)
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Text("This is why I made this app: so now that I'm grown up, I can capture the memories of my aunt, who is suffering a similar illness and losing her memories.")
                    .font(.subheadline)
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
}


struct AboutAppPage: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.softTerracotta.opacity(0.2), Color.softAmber.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.softTerracotta, .deepTerracotta],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 10) {
                Text("Memory Trace")
                    .font(.title2.bold())
                    .foregroundColor(.warmBrown)
                    .multilineTextAlignment(.center)
                
                Text("Capture the voices and stories of your loved ones before they fade. Record conversations, get instant transcriptions, and translate between Spanish and English.")
                    .font(.subheadline)
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Feature highlights
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "mic.fill", text: "Record family stories")
                FeatureRow(icon: "text.quote", text: "Automatic transcription")
                FeatureRow(icon: "globe", text: "Spanish & English support")
            }
            .padding(.top, 4)
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
                .foregroundStyle(Color.softTerracotta)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.warmBrown.opacity(0.8))
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.warmSand, Color.softAmber.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        OnboardingPopup {
            print("Onboarding complete")
        }
    }
}

