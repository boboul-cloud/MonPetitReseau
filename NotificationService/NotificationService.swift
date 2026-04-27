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

        // --- DIAGNOSTIC : titres "[ext: ...]" actifs uniquement quand quelque
        // chose tourne mal. Le cas nominal écrit le nom de l'expéditeur. ---

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

        // Helper : champs CloudKit parfois bruts, parfois {"value": ...}.
        func stringField(_ key: String) -> String? {
            let raw = fields[key]
            if let s = raw as? String { return s }
            if let dict = raw as? [String: Any], let s = dict["value"] as? String { return s }
            return nil
        }

        // Compose le corps depuis le contenu réel du record (text ou title)
        // pour remplacer le "%1$@" non substitué par iOS.
        let bodyText = stringField("text") ?? stringField("title")
        if let bodyText, !bodyText.isEmpty {
            // Conserve un éventuel emoji préfixe (📅 / ✅ / 📷) déjà dans alertBody.
            let original = bestAttempt.body
            if let emoji = original.first, !emoji.isLetter, !emoji.isNumber, emoji != "%" {
                bestAttempt.body = "\(emoji) \(bodyText)"
            } else {
                bestAttempt.body = bodyText
            }
        }

        // Champ authorId (messages/photos) ou createdBy (events/todos).
        let authorId = stringField("authorId") ?? stringField("createdBy")

        guard let authorId, !authorId.isEmpty else {
            bestAttempt.title = "[ext: pas d'auteur, fields=\(Array(fields.keys))]"
            contentHandler(bestAttempt)
            return
        }

        if let name = lookupName(for: authorId), !name.isEmpty {
            bestAttempt.title = name
        }
        // Si on n'a pas trouvé le nom, on laisse le titre par défaut
        // d'iOS (généralement le nom de l'app).

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
