//
//  snake_a_doodleApp.swift
//  snake-a-doodle
//

import SwiftUI
import SwiftData

@main
struct snake_a_doodleApp: App {
    @StateObject private var storeManager = StoreManager()
    @StateObject private var authManager = AuthManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([HighScore.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
                .environmentObject(authManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
