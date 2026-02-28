//
//  ContentView.swift
//  Swift Student Challenge Real
//
//  Created by LuisRosales on 04/01/26.
//

import SwiftUI
import SwiftData

enum AppRoute: Hashable {
    case chat
    case record
    case memories
}

struct PopToRootKey: EnvironmentKey {
    static let defaultValue: @MainActor () -> Void = {}
}

extension EnvironmentValues {
    var popToRoot: @MainActor () -> Void {
        get { self[PopToRootKey.self] }
        set { self[PopToRootKey.self] = newValue }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var navigationPath = NavigationPath()
    @State private var showOnboarding = true
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            MainScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .chat:
                        PromptChatView()
                    case .record:
                        RecordStoryView()
                    case .memories:
                        MemoriesView()
                    }
                }
                .navigationDestination(for: Recording.self) { recording in
                    RecordingDetailView(recording: recording)
                }
        }
        .environment(\.popToRoot) {
            navigationPath = NavigationPath()
        }
        .overlay {
            if showOnboarding {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    OnboardingPopup {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showOnboarding = false
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .onAppear {
            DemoDataManager.seedIfNeeded(modelContext: modelContext)
            startPendingTranscriptions()
        }
    }
    
    private func startPendingTranscriptions() {
        let context = modelContext
        Task {
            _ = await SpeechTranscriber.shared.requestPermission()
            try? await Task.sleep(for: .milliseconds(500))
            
            let descriptor = FetchDescriptor<Recording>()
            guard let recordings = try? context.fetch(descriptor) else { return }
            
            for recording in recordings where recording.transcriptionStatus == .pending {
                await recording.startTranscription(modelContext: context)
            }
        }
    }
}

#Preview {
    ContentView()
}
