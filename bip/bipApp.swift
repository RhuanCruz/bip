//
//  bipApp.swift
//  bip
//
//  Created by Rhuan Victor Timoteo da Cruz on 23/04/26.
//

import SwiftUI
import SwiftData

@main
struct bipApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
            Recurrence.self,
            Reminder.self,
            Category.self,
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
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
