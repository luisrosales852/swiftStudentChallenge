//
//  ContentView.swift
//  Swift Student Challenge Real
//
//  Created by LuisRosales on 04/01/26.
//

import SwiftUI

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
        }
    }
}

#Preview {
    ContentView()
}
