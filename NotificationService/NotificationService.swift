// NotificationService.swift
// Notification Service Extension : intercepte chaque push CloudKit avant
// affichage et préfixe le corps avec le nom de l'expéditeur, qu'on récupère
// dans le fichier `members.json` partagé via App Group.
//
// Important : ce code tourne dans un *autre processus* (l'extension), donc
// il ne partage rien avec l'app principale en mémoire — uniquement via
// le conteneur App Group.

import UserNotifications

final class NotificationService: UNNotificationServiceExtension {

    private static let appGroup = "group.bob.oulhen-gmail.com.MonPetitReseau"
    private static let membersFile = "members.json"

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttempt: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttempt = request.content.mutableCopy() as? UNMutableNotificationContent

        guard let bestAttempt else {
            contentHandler(request.content)
            return
        }

        // Extract record fields embedded by CloudKit (alertLocalizationArgs / desiredKeys).
        // Payload shape : userInfo["ck"]["qry"]["af"] = ["text": ..., "authorId": ...]
        let userInfo = request.content.userInfo
        guard
            let ck = userInfo["ck"] as? [String: Any],
            let qry = ck["qry"] as? [String: Any],
            let fields = qry["af"] as? [String: Any]
        else {
            contentHandler(bestAttempt)
            return
        }

        // Look up the author's display name in the shared members file.
        let authorName = fields["authorId"]
            .flatMap { $0 as? String }
            .flatMap { lookupName(for: $0) }

        // Compose new body : "Name : original body" (or just original if unknown).
        if let authorName, !authorName.isEmpty {
            bestAttempt.title = authorName
        }

        contentHandler(bestAttempt)
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttempt {
            contentHandler(bestAttempt)
        }
    }

    // MARK: - Helpers

    private func lookupName(for authorId: String) -> String? {
        guard
            let url = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup)?
                .appendingPathComponent(Self.membersFile),
            let data = try? Data(contentsOf: url),
            let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return nil
        }
        return dict[authorId]
    }
}
