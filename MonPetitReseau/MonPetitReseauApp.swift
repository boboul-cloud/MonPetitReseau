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

    /// The app store is wired in by the SwiftUI App once it's available.
    @MainActor static weak var sharedAppStore: AppStore?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // CloudKit silent push : pull whatever changed across every group.
        Task { @MainActor in
            await AppDelegate.sharedAppStore?.syncAll(notifyUser: true)
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
    @State private var appStore = AppStore()
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appStore)
                .environment(appStore.active)
                .id(appStore.active.familyId) // re-mount tabs when switching groups
                .onOpenURL { _ = appStore.importFromURL($0) }
                .task {
                    AppDelegate.sharedAppStore = appStore
                    await NotificationManager.requestAuthorizationIfNeeded()
                    await appStore.bootstrapAllGroups()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await appStore.syncAll(notifyUser: false) }
                    }
                }
        }
    }
}
