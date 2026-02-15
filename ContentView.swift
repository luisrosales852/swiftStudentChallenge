

import SwiftUI

// Environment key for popping to root
struct PopToRootKey: EnvironmentKey {
    static let defaultValue: @Sendable () -> Void = {}
}

extension EnvironmentValues {
    var popToRoot: @Sendable () -> Void {
        get { self[PopToRootKey.self] }
        set { self[PopToRootKey.self] = newValue }
    }
}

struct ContentView: View {
    @State private var splashComplete = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        Group {
            if !splashComplete {
                // Show splash screen WITHOUT NavigationStack
                // User cannot navigate back to this screen
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 1)) {
                        splashComplete = true
                    }
                }
            } else {
                // Show main app with NavigationStack
                NavigationStack(path: $navigationPath) {
                    MainScreen()
                }
                .environment(\.popToRoot) {
                    navigationPath = NavigationPath()
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}

