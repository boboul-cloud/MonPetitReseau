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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .onOpenURL { store.importFromURL($0) }
        }
    }
}
