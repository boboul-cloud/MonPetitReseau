//
//  NotificationManager.swift
//  MonPetitReseau
//
//  Local notifications surfaced when CloudKit subscriptions deliver a silent
//  push. We craft user-facing alerts ourselves so the message text and author
//  appear directly on the lock screen.
//

import Foundation
import UserNotifications
import UIKit

@MainActor
enum NotificationManager {

    /// Ask the user for permission to display alerts and badges.
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        }
        // Always re-register for remote pushes (token may rotate).
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Post a local notification for a freshly-arrived record.
    static func notify(title: String, body: String, deepLink: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let deepLink {
            content.userInfo = ["deepLink": deepLink]
        }
        let req = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil      // deliver now
        )
        UNUserNotificationCenter.current().add(req)
    }

    /// Compose a notification text from a delta of new records.
    static func announce(newMessages: [FamilyMessage],
                         newEvents: [FamilyEvent],
                         newTodos: [FamilyTodo],
                         newPhotos: [FamilyPhoto],
                         memberName: (UUID) -> String) {
        // One notification per message so the lock screen shows real content.
        for m in newMessages {
            notify(
                title: memberName(m.authorId),
                body: m.text,
                deepLink: "messages"
            )
        }

        if !newEvents.isEmpty {
            let title = String(localized: "notif.event.title")
            let body: String
            if newEvents.count == 1, let e = newEvents.first {
                body = String(format: String(localized: "notif.event.one"),
                              memberName(e.createdBy), e.title)
            } else {
                body = String(format: String(localized: "notif.event.many"),
                              newEvents.count)
            }
            notify(title: title, body: body, deepLink: "events")
        }

        if !newTodos.isEmpty {
            let title = String(localized: "notif.todo.title")
            let body: String
            if newTodos.count == 1, let t = newTodos.first {
                body = String(format: String(localized: "notif.todo.one"),
                              memberName(t.createdBy), t.title)
            } else {
                body = String(format: String(localized: "notif.todo.many"),
                              newTodos.count)
            }
            notify(title: title, body: body, deepLink: "todos")
        }

        if !newPhotos.isEmpty {
            let title = String(localized: "notif.photo.title")
            let body: String
            if newPhotos.count == 1, let p = newPhotos.first {
                body = String(format: String(localized: "notif.photo.one"),
                              memberName(p.authorId))
            } else {
                body = String(format: String(localized: "notif.photo.many"),
                              newPhotos.count)
            }
            notify(title: title, body: body, deepLink: "photos")
        }
    }

    /// Update the app icon badge with the total unread count.
    static func setBadge(_ count: Int) {
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(count)
        }
    }
}
