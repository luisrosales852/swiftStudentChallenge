//
//  PromptChatView.swift
//  Swift Student Challenge Real
//
//  Created by Luis on 14/02/26.
//

import SwiftUI
import SwiftData

struct PromptChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var recordings: [Recording]
    
    @State private var chat = PromptChat()
    @State private var userInput = ""
    
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
            
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chat.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            // Typing indicator when generating
                            if chat.isGenerating && chat.currentStreamingText.isEmpty {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: chat.messages.count) {
                        withAnimation {
                            proxy.scrollTo(chat.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: chat.currentStreamingText) {
                        withAnimation {
                            proxy.scrollTo(chat.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Ready to record button
                if !chat.isGenerating {
                    NavigationLink(value: AppRoute.record) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "mic.circle.fill")
                                    .font(.system(size: 24))
                            }
                            Text("Ready to Record")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .glassEffect(.regular.tint(.softTerracotta).interactive(), in: .rect(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                // Input area
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $userInput)
                        .textFieldStyle(.plain)
                        .foregroundColor(.warmBrown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.7))
                        }
                        .disabled(chat.isGenerating)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(userInput.isEmpty || chat.isGenerating ? .warmBrown.opacity(0.3) : .softTerracotta)
                    }
                    .disabled(userInput.isEmpty || chat.isGenerating)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    Rectangle()
                        .fill(Color.warmSand.opacity(0.9))
                        .shadow(color: .warmBrown.opacity(0.05), radius: 8, y: -4)
                }
            }
        }
        .navigationTitle("What's your story?")
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
            // Only start conversation if it's a fresh chat (no messages yet)
            if chat.messages.isEmpty {
                chat.prewarm(existingRecordings: recordings)
                startConversation()
            }
        }
        .onDisappear {
            // Reset when leaving the view so next visit starts fresh
            chat.reset()
        }
    }
    
    private func startConversation() {
        Task {
            await chat.startConversation(existingRecordings: recordings)
        }
    }
    
    private func sendMessage() {
        let message = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        userInput = ""
        
        Task {
            await chat.sendMessage(message)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            Text(message.text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(message.role == .user ? .white : .warmBrown)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    if message.role == .user {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [.softTerracotta, .deepTerracotta],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.8))
                    }
                }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}


struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.softTerracotta.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: animationPhase == index ? -4 : 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.8))
            }
            
            Spacer(minLength: 60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        PromptChatView()
    }
    .modelContainer(for: Recording.self, inMemory: true)
}
