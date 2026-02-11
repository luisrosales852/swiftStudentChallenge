//
//  Swift_Student_Challenge_App.swift
//  Swift Student Challenge Real
//
//  Created by Luis on 10/02/26.
//

import SwiftUI
import SwiftData

@main
struct Swift_Student_Challenge_App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Recording.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
