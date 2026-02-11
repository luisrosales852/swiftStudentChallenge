

import SwiftUI

struct ContentView: View {
    @State private var splashComplete = false
    
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
                NavigationStack {
                    MainScreen()
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}

