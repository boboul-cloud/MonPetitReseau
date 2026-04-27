//
//  MonPetitReseauApp.swift
//  MonPetitReseau
//
//  Created by Robert Oulhen on 27/04/2026.
//

import SwiftUI

@main
struct MonPetitReseauApp: App {
    @State private var store = FamilyStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .onOpenURL { store.importFromURL($0) }
                .task { await store.syncAll() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await store.syncAll() }
                    }
                }
        }
    }
}
