//
//  MonPetitReseauApp.swift
//  MonPetitReseau
//
//  Created by Robert Oulhen on 27/04/2026.
//

import SwiftUI
import UIKit
import UserNotifications

// MARK: - App delegate (push notifications)

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// The store is wired in by the SwiftUI App once it's available.
    @MainActor static weak var sharedStore: FamilyStore?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // CloudKit sent us a silent push : pull whatever changed.
        Task { @MainActor in
            let store = AppDelegate.sharedStore
            await store?.syncAll(notifyUser: true)
            completionHandler(.newData)
        }
    }

    // Show banners even when the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct MonPetitReseauApp: App {
    @State private var store = FamilyStore()
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // No-op : the store is created above as @State.
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .onOpenURL { store.importFromURL($0) }
                .task {
                    AppDelegate.sharedStore = store
                    await NotificationManager.requestAuthorizationIfNeeded()
                    await store.bootstrapCloud()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await store.syncAll(notifyUser: false) }
                    }
                }
        }
    }
}

