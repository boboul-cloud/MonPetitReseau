//
//  CloudSync.swift
//  MonPetitReseau
//
//  CloudKit-backed family sync — direct iPhone↔iPhone via Apple's public database.
//  All members of the same family (sharing the same `familyId`) read/write
//  records from a common channel — no third-party server.
//
//  Record types (all in the public database, default zone):
//   - Message  (text wall)
//   - Event    (calendar)
//   - Todo     (shared tasks)
//   - Member   (family members)
//   - Photo    (shared photo album, image stored as CKAsset)
//

import Foundation
import CloudKit
import os.log

@MainActor
final class CloudSync {

    // MARK: - Configuration

    static let containerID = "iCloud.bob.oulhen-gmail.com.MonPetitReseau"

    enum RecordType: String {
        case message = "Message"
        case event   = "Event"
        case todo    = "Todo"
        case member  = "Member"
        case photo   = "Photo"
    }

    // MARK: - Properties

    private let container: CKContainer
    private let database: CKDatabase
    private let log = Logger(subsystem: "MonPetitReseau", category: "CloudSync")

    /// Tracks the most recent `modifiedAt` we already imported per (familyId, recordType).
    private var lastSyncDate: [String: Date] = [:]

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

    // MARK: - Public API : Messages

    func push(message m: FamilyMessage, familyId: UUID) async {
        let r = CKRecord(recordType: RecordType.message.rawValue, recordID: id(m.id))
        r["familyId"] = familyId.uuidString as CKRecordValue
        r["authorId"] = m.authorId.uuidString as CKRecordValue
        r["text"] = m.text as CKRecordValue
        r["date"] = m.date as CKRecordValue
        r["modifiedAt"] = Date() as CKRecordValue
        await save(r)
    }

    func fetchNewMessages(familyId: UUID, knownIDs: Set<UUID>) async -> [FamilyMessage] {
        let records = await fetchSince(.message, familyId: familyId)
        return records.compactMap(decodeMessage).filter { !knownIDs.contains($0.id) }
    }

    func deleteMessage(_ id: UUID) async { await delete(.message, id: id) }

    // MARK: - Public API : Events

    func push(event e: FamilyEvent, familyId: UUID) async {
        let r = CKRecord(recordType: RecordType.event.rawValue, recordID: id(e.id))
        r["familyId"] = familyId.uuidString as CKRecordValue
        r["title"] = e.title as CKRecordValue
        r["date"] = e.date as CKRecordValue
        r["location"] = e.location as CKRecordValue
        r["details"] = e.details as CKRecordValue
        r["createdBy"] = e.createdBy.uuidString as CKRecordValue
        r["modifiedAt"] = Date() as CKRecordValue
        await save(r, savePolicy: .changedKeys)
    }

    func fetchEvents(familyId: UUID) async -> [FamilyEvent] {
        await fetchSince(.event, familyId: familyId).compactMap(decodeEvent)
    }

    func deleteEvent(_ id: UUID) async { await delete(.event, id: id) }

    // MARK: - Public API : Todos

    func push(todo t: FamilyTodo, familyId: UUID) async {
        let r = CKRecord(recordType: RecordType.todo.rawValue, recordID: id(t.id))
        r["familyId"] = familyId.uuidString as CKRecordValue
        r["title"] = t.title as CKRecordValue
        r["isDone"] = (t.isDone ? 1 : 0) as CKRecordValue
        r["createdBy"] = t.createdBy.uuidString as CKRecordValue
        if let a = t.assignedTo { r["assignedTo"] = a.uuidString as CKRecordValue }
        r["date"] = t.date as CKRecordValue
        r["modifiedAt"] = Date() as CKRecordValue
        await save(r, savePolicy: .changedKeys)
    }

    func fetchTodos(familyId: UUID) async -> [FamilyTodo] {
        await fetchSince(.todo, familyId: familyId).compactMap(decodeTodo)
    }

    func deleteTodo(_ id: UUID) async { await delete(.todo, id: id) }

    // MARK: - Public API : Members

    func push(member m: FamilyMember, familyId: UUID) async {
        let r = CKRecord(recordType: RecordType.member.rawValue, recordID: id(m.id))
        r["familyId"] = familyId.uuidString as CKRecordValue
        r["firstName"] = m.firstName as CKRecordValue
        r["lastName"] = m.lastName as CKRecordValue
        r["emoji"] = m.emoji as CKRecordValue
        if let bd = m.birthDate { r["birthDate"] = bd as CKRecordValue }
        r["phone"] = m.phone as CKRecordValue
        r["email"] = m.email as CKRecordValue
        r["city"] = m.city as CKRecordValue
        r["role"] = m.role as CKRecordValue
        r["bio"] = m.bio as CKRecordValue
        if let v = m.motherId { r["motherId"] = v.uuidString as CKRecordValue }
        if let v = m.fatherId { r["fatherId"] = v.uuidString as CKRecordValue }
        if let v = m.partnerId { r["partnerId"] = v.uuidString as CKRecordValue }
        r["modifiedAt"] = Date() as CKRecordValue
        await save(r, savePolicy: .changedKeys)
    }

    func fetchMembers(familyId: UUID) async -> [FamilyMember] {
        await fetchSince(.member, familyId: familyId).compactMap(decodeMember)
    }

    func deleteMember(_ id: UUID) async { await delete(.member, id: id) }

    // MARK: - Public API : Photos

    func push(photo p: FamilyPhoto, familyId: UUID) async {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(p.id.uuidString).jpg")
        do {
            try p.imageData.write(to: tmp, options: .atomic)
        } catch {
            log.error("Photo temp write failed: \(error.localizedDescription)")
            return
        }

        let r = CKRecord(recordType: RecordType.photo.rawValue, recordID: id(p.id))
        r["familyId"] = familyId.uuidString as CKRecordValue
        r["authorId"] = p.authorId.uuidString as CKRecordValue
        r["caption"] = p.caption as CKRecordValue
        r["date"] = p.date as CKRecordValue
        r["modifiedAt"] = Date() as CKRecordValue
        r["image"] = CKAsset(fileURL: tmp)

        await save(r, savePolicy: .changedKeys)
        try? FileManager.default.removeItem(at: tmp)
    }

    func fetchPhotos(familyId: UUID, knownIDs: Set<UUID>) async -> [FamilyPhoto] {
        await fetchSince(.photo, familyId: familyId)
            .compactMap(decodePhoto)
            .filter { !knownIDs.contains($0.id) }
    }

    func deletePhoto(_ id: UUID) async { await delete(.photo, id: id) }

    // MARK: - Account

    func accountAvailable() async -> Bool {
        do { return try await container.accountStatus() == .available }
        catch { return false }
    }

    // MARK: - Generic helpers

    private func id(_ uuid: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: uuid.uuidString)
    }

    private func save(_ record: CKRecord,
                      savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged) async {
        do {
            // Modify operation lets us pick a save policy. The high-level
            // `database.save()` always uses `.ifServerRecordUnchanged`, which
            // would fail every edit of an already-existing record.
            let op = CKModifyRecordsOperation(recordsToSave: [record])
            op.savePolicy = savePolicy
            op.qualityOfService = .userInitiated
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                op.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success: cont.resume()
                    case .failure(let e): cont.resume(throwing: e)
                    }
                }
                database.add(op)
            }
        } catch let error as CKError where error.code == .serverRecordChanged {
            log.debug("Record already up-to-date: \(record.recordID.recordName)")
        } catch {
            log.error("Save failed (\(record.recordType)): \(error.localizedDescription)")
        }
    }

    private func delete(_ type: RecordType, id: UUID) async {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        do {
            _ = try await database.deleteRecord(withID: recordID)
        } catch {
            log.error("Delete failed (\(type.rawValue)): \(error.localizedDescription)")
        }
    }

    /// Fetch all records of a given type for `familyId` modified since the last fetch.
    private func fetchSince(_ type: RecordType, familyId: UUID) async -> [CKRecord] {
        status = .syncing
        defer { status = .idle }

        let key = "\(familyId.uuidString)|\(type.rawValue)"
        let since = lastSyncDate[key] ?? Date(timeIntervalSince1970: 0)

        let predicate = NSPredicate(
            format: "familyId == %@ AND modifiedAt > %@",
            familyId.uuidString,
            since as NSDate
        )
        let query = CKQuery(recordType: type.rawValue, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: true)]

        do {
            let (matchResults, _) = try await database.records(
                matching: query,
                resultsLimit: 400
            )
            var records: [CKRecord] = []
            var maxDate = since
            for (_, result) in matchResults {
                if case .success(let rec) = result {
                    records.append(rec)
                    if let m = rec["modifiedAt"] as? Date, m > maxDate { maxDate = m }
                }
            }
            lastSyncDate[key] = maxDate
            return records
        } catch let error as CKError where error.code == .notAuthenticated {
            status = .unavailable(String(localized: "cloud.error.signin"))
            return []
        } catch let error as CKError where error.code == .networkUnavailable
                                       || error.code == .networkFailure {
            status = .unavailable(String(localized: "cloud.error.offline"))
            return []
        } catch let error as CKError where error.code == .unknownItem
                                       || error.code == .invalidArguments {
            // Record type / index not yet created server-side — silent first-run.
            log.debug("Schema not ready for \(type.rawValue): \(error.localizedDescription)")
            return []
        } catch {
            log.error("Fetch \(type.rawValue) failed: \(error.localizedDescription)")
            status = .unavailable(error.localizedDescription)
            return []
        }
    }

    // MARK: - Decoders

    private func decodeMessage(_ r: CKRecord) -> FamilyMessage? {
        guard
            let id = UUID(uuidString: r.recordID.recordName),
            let authorIDStr = r["authorId"] as? String,
            let authorID = UUID(uuidString: authorIDStr),
            let text = r["text"] as? String,
            let date = r["date"] as? Date
        else { return nil }
        return FamilyMessage(id: id, authorId: authorID, text: text, date: date)
    }

    private func decodeEvent(_ r: CKRecord) -> FamilyEvent? {
        guard
            let id = UUID(uuidString: r.recordID.recordName),
            let title = r["title"] as? String,
            let date = r["date"] as? Date,
            let location = r["location"] as? String,
            let details = r["details"] as? String,
            let createdByStr = r["createdBy"] as? String,
            let createdBy = UUID(uuidString: createdByStr)
        else { return nil }
        return FamilyEvent(id: id, title: title, date: date, location: location,
                           details: details, createdBy: createdBy)
    }

    private func decodeTodo(_ r: CKRecord) -> FamilyTodo? {
        guard
            let id = UUID(uuidString: r.recordID.recordName),
            let title = r["title"] as? String,
            let createdByStr = r["createdBy"] as? String,
            let createdBy = UUID(uuidString: createdByStr),
            let date = r["date"] as? Date
        else { return nil }
        let isDone = (r["isDone"] as? Int64 ?? 0) != 0
        let assignedTo: UUID? = (r["assignedTo"] as? String).flatMap(UUID.init(uuidString:))
        return FamilyTodo(id: id, title: title, isDone: isDone,
                          createdBy: createdBy, assignedTo: assignedTo, date: date)
    }

    private func decodeMember(_ r: CKRecord) -> FamilyMember? {
        guard
            let id = UUID(uuidString: r.recordID.recordName),
            let first = r["firstName"] as? String,
            let last = r["lastName"] as? String,
            let emoji = r["emoji"] as? String,
            let phone = r["phone"] as? String,
            let email = r["email"] as? String,
            let city = r["city"] as? String,
            let role = r["role"] as? String,
            let bio = r["bio"] as? String
        else { return nil }
        let mom: UUID? = (r["motherId"] as? String).flatMap(UUID.init(uuidString:))
        let dad: UUID? = (r["fatherId"] as? String).flatMap(UUID.init(uuidString:))
        let part: UUID? = (r["partnerId"] as? String).flatMap(UUID.init(uuidString:))
        return FamilyMember(id: id, firstName: first, lastName: last, emoji: emoji,
                            birthDate: r["birthDate"] as? Date,
                            phone: phone, email: email, city: city,
                            role: role, bio: bio,
                            motherId: mom, fatherId: dad, partnerId: part)
    }

    private func decodePhoto(_ r: CKRecord) -> FamilyPhoto? {
        guard
            let id = UUID(uuidString: r.recordID.recordName),
            let authorIDStr = r["authorId"] as? String,
            let authorID = UUID(uuidString: authorIDStr),
            let caption = r["caption"] as? String,
            let date = r["date"] as? Date,
            let asset = r["image"] as? CKAsset,
            let url = asset.fileURL,
            let data = try? Data(contentsOf: url)
        else { return nil }
        return FamilyPhoto(id: id, authorId: authorID, caption: caption,
                           date: date, imageData: data)
    }
}
