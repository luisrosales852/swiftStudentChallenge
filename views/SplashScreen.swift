//
//  SplashScreenView.swift
//  Swift Student Challenge app
//
//  Created by Papasito on 04/01/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var textOpacity = 0.0
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Fading in text
            VStack(spacing: 10) {
                Text("Memory Trace")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                
                Text("Alzheimer Helper")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            // Fade in animation
            withAnimation(.bouncy) {
                textOpacity = 1.0
            }
            
            // Navigate after 4 seconds using modern Swift Concurrency
            Task {
                try? await Task.sleep(for: .seconds(2))
                onComplete()
            }
        }
    }
}

#Preview {
    SplashScreenView {
        print("Splash complete")
    }
}

