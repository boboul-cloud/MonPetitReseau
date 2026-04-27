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

        // --- DIAGNOSTIC : tag visible pour vérifier que l'extension tourne. ---
        // On retire ce tag dès que tout marche.
        bestAttempt.title = "[ext]"

        let userInfo = request.content.userInfo

        // CloudKit query notification payload : userInfo["ck"]["qry"]["af"]
        guard
            let ck = userInfo["ck"] as? [String: Any],
            let qry = ck["qry"] as? [String: Any]
        else {
            bestAttempt.title = "[ext: pas de ck.qry]"
            contentHandler(bestAttempt)
            return
        }

        guard let fields = qry["af"] as? [String: Any] else {
            bestAttempt.title = "[ext: pas de af, qry=\(Array(qry.keys))]"
            contentHandler(bestAttempt)
            return
        }

        // Champ authorId (messages/photos) ou createdBy (events/todos).
        let rawAuthor = fields["authorId"] ?? fields["createdBy"]

        // Les champs CKRecord arrivent parfois bruts ("UUID-string"),
        // parfois enveloppés dans {"value": "...", "type": "STRING"}.
        let authorId: String? = {
            if let s = rawAuthor as? String { return s }
            if let dict = rawAuthor as? [String: Any], let s = dict["value"] as? String { return s }
            return nil
        }()

        guard let authorId, !authorId.isEmpty else {
            bestAttempt.title = "[ext: pas d'auteur, fields=\(Array(fields.keys))]"
            contentHandler(bestAttempt)
            return
        }

        if let name = lookupName(for: authorId), !name.isEmpty {
            bestAttempt.title = name
        } else {
            bestAttempt.title = "[ext: inconnu \(authorId.prefix(8))]"
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
