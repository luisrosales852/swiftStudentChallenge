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
    @State private var selectedCategory: StoryCategory? = nil
    
    private var hasSelectedCategory: Bool {
        selectedCategory != nil
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
            
            VStack(spacing: 0) {
                if hasSelectedCategory {
                    // Chat messages (shown after category selection)
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
                } else {
                    // Category picker (shown before chat starts)
                    categoryPickerView
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
            if chat.messages.isEmpty {
                chat.prewarm(existingRecordings: recordings)
            }
        }
        .onDisappear {
            // Reset when leaving the view so next visit starts fresh
            chat.reset()
            selectedCategory = nil
        }
    }
    
    
    private var categoryPickerView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("What would you like to share?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.warmBrown)
                    
                    Text("Pick a category to get started")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.warmBrown.opacity(0.7))
                }
                .padding(.top, 40)
                
                // Category grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(StoryCategory.allCases, id: \.self) { category in
                        CategoryButton(category: category) {
                            selectCategory(category)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Skip button
                Button {
                    skipCategorySelection()
                } label: {
                    Text("Skip — I'll explore on my own")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.warmBrown.opacity(0.6))
                        .padding(.vertical, 12)
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
    }
    
    private func selectCategory(_ category: StoryCategory) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedCategory = category
        }
        // Start conversation with category context
        chat.prewarm(existingRecordings: recordings)
        Task {
            await chat.startConversation(existingRecordings: recordings, category: category)
        }
    }
    
    private func skipCategorySelection() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedCategory = .childhood // Use a default, but conversation will be freeform
        }
        // Start freeform conversation
        chat.prewarm(existingRecordings: recordings)
        Task {
            await chat.startConversation(existingRecordings: recordings, category: nil)
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

struct CategoryButton: View {
    let category: StoryCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.warmBrown)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        PromptChatView()
    }
    .modelContainer(for: Recording.self, inMemory: true)
}
