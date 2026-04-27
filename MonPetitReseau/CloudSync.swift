//
//  CloudSync.swift
//  MonPetitReseau
//
//  CloudKit-backed messaging — direct iPhone↔iPhone via Apple's public database.
//  All members of the same family (sharing the same `familyId`) read/write
//  messages from a common channel — no third-party server.
//

import Foundation
import CloudKit
import os.log

@MainActor
final class CloudSync {

    // MARK: - Configuration

    static let containerID = "iCloud.bob.oulhen-gmail.com.MonPetitReseau"
    static let recordType  = "Message"

    private let container: CKContainer
    private let database: CKDatabase
    private let log = Logger(subsystem: "MonPetitReseau", category: "CloudSync")

    /// Tracks the most recent message date we already imported per family.
    private var lastSyncDate: [UUID: Date] = [:]

    /// Records we recently pushed — used to dedupe the next fetch round-trip.
    private var pushedIDs: Set<String> = []

    // MARK: - State

    enum Status: Equatable {
        case idle
        case syncing
        case unavailable(String)
    }

    private(set) var status: Status = .idle

    // MARK: - Init

    init() {
        self.container = CKContainer(identifier: Self.containerID)
        self.database = container.publicCloudDatabase
    }

    // MARK: - Push

    /// Push one message to CloudKit. Safe to call repeatedly — failures are logged.
    func push(message: FamilyMessage, familyId: UUID) async {
        let recordID = CKRecord.ID(recordName: message.id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["familyId"] = familyId.uuidString as CKRecordValue
        record["authorId"] = message.authorId.uuidString as CKRecordValue
        record["text"] = message.text as CKRecordValue
        record["date"] = message.date as CKRecordValue

        do {
            _ = try await database.save(record)
            pushedIDs.insert(recordID.recordName)
            log.info("Pushed message \(message.id.uuidString)")
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Already exists — that's fine.
            log.debug("Message already on server: \(message.id.uuidString)")
        } catch {
            log.error("Push failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch

    /// Fetch all messages for the given family newer than the last sync.
    /// Returns the new messages (never previously seen).
    func fetchNewMessages(familyId: UUID,
                          knownIDs: Set<UUID>) async -> [FamilyMessage] {
        status = .syncing
        defer { status = .idle }

        let since = lastSyncDate[familyId] ?? Date(timeIntervalSince1970: 0)
        let predicate = NSPredicate(
            format: "familyId == %@ AND date > %@",
            familyId.uuidString,
            since as NSDate
        )
        let query = CKQuery(recordType: Self.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        do {
            let (matchResults, _) = try await database.records(
                matching: query,
                resultsLimit: 200
            )
            var newMessages: [FamilyMessage] = []
            var maxDate = since
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    guard let msg = decode(record) else { continue }
                    if msg.date > maxDate { maxDate = msg.date }
                    if knownIDs.contains(msg.id) { continue }
                    newMessages.append(msg)
                case .failure(let error):
                    log.error("Record fetch error: \(error.localizedDescription)")
                }
            }
            lastSyncDate[familyId] = maxDate
            return newMessages
        } catch let error as CKError where error.code == .notAuthenticated {
            status = .unavailable(String(localized: "cloud.error.signin"))
            return []
        } catch let error as CKError where error.code == .networkUnavailable
                                       || error.code == .networkFailure {
            status = .unavailable(String(localized: "cloud.error.offline"))
            return []
        } catch {
            log.error("Fetch failed: \(error.localizedDescription)")
            status = .unavailable(error.localizedDescription)
            return []
        }
    }

    // MARK: - Delete

    func delete(messageId: UUID) async {
        let recordID = CKRecord.ID(recordName: messageId.uuidString)
        do {
            _ = try await database.deleteRecord(withID: recordID)
        } catch {
            log.error("Delete failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Account check

    func accountAvailable() async -> Bool {
        do {
            let s = try await container.accountStatus()
            return s == .available
        } catch {
            return false
        }
    }

    // MARK: - Decoding

    private func decode(_ record: CKRecord) -> FamilyMessage? {
        guard
            let authorIDStr = record["authorId"] as? String,
            let authorID = UUID(uuidString: authorIDStr),
            let text = record["text"] as? String,
            let date = record["date"] as? Date,
            let id = UUID(uuidString: record.recordID.recordName)
        else { return nil }
        return FamilyMessage(id: id, authorId: authorID, text: text, date: date)
    }
}
