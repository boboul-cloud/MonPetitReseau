//
//  FamilyStore.swift
//  MonPetitReseau
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class FamilyStore {

    var familyName: String
    var familyId: UUID
    var members: [FamilyMember]
    var messages: [FamilyMessage]
    var events: [FamilyEvent]
    var todos: [FamilyTodo]
    var photos: [FamilyPhoto]
    var currentUserId: UUID?

    /// CloudKit sync layer (lazy: only used when actively messaging).
    let cloud = CloudSync()
    /// Surface-level status for the UI.
    var cloudStatus: CloudSync.Status = .idle

    private static let key = "MonPetitReseau.state.v2"
    private static let defaults = UserDefaults.standard

    // MARK: - Init

    init() {
        if let raw = Self.defaults.data(forKey: Self.key),
           let snap = try? JSONDecoder.iso.decode(Snapshot.self, from: raw) {
            self.familyName = snap.familyName
            self.familyId = snap.familyId
            self.members = snap.members
            self.messages = snap.messages
            self.events = snap.events
            self.todos = snap.todos
            self.photos = snap.photos
            self.currentUserId = snap.currentUserId
        } else if let raw = Self.defaults.data(forKey: "MonPetitReseau.state.v1"),
                  let snap = try? JSONDecoder.iso.decode(LegacySnapshot.self, from: raw) {
            // Migrate v1 → v2 (assign a fresh familyId).
            self.familyName = snap.familyName
            self.familyId = UUID()
            self.members = snap.members
            self.messages = snap.messages
            self.events = snap.events
            self.todos = snap.todos
            self.photos = snap.photos
            self.currentUserId = snap.currentUserId
        } else {
            self.familyName = ""
            self.familyId = UUID()
            self.members = []
            self.messages = []
            self.events = []
            self.todos = []
            self.photos = []
            self.currentUserId = nil
        }
    }

    // MARK: - Persistence

    func save() {
        let snap = Snapshot(
            familyName: familyName,
            familyId: familyId,
            members: members,
            messages: messages,
            events: events,
            todos: todos,
            photos: photos,
            currentUserId: currentUserId
        )
        if let data = try? JSONEncoder.iso.encode(snap) {
            Self.defaults.set(data, forKey: Self.key)
        }
        writeMembersForExtension()
    }

    /// Mirror the (memberId → fullName) lookup table into the App Group container
    /// so the Notification Service Extension can resolve the sender's name even
    /// when the main app is not running.
    private func writeMembersForExtension() {
        guard
            let container = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier:
                    "group.bob.oulhen-gmail.com.MonPetitReseau")
        else { return }
        let dict = Dictionary(uniqueKeysWithValues:
            members.map { ($0.id.uuidString, $0.fullName) })
        let url = container.appendingPathComponent("members.json")
        if let data = try? JSONEncoder().encode(dict) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private struct Snapshot: Codable {
        var familyName: String
        var familyId: UUID
        var members: [FamilyMember]
        var messages: [FamilyMessage]
        var events: [FamilyEvent]
        var todos: [FamilyTodo]
        var photos: [FamilyPhoto]
        var currentUserId: UUID?
    }

    /// Old persistence format (kept only for one-shot migration).
    private struct LegacySnapshot: Codable {
        var familyName: String
        var members: [FamilyMember]
        var messages: [FamilyMessage]
        var events: [FamilyEvent]
        var todos: [FamilyTodo]
        var photos: [FamilyPhoto]
        var currentUserId: UUID?
    }

    // MARK: - Members

    func addMember(_ m: FamilyMember) {
        members.append(m)
        if currentUserId == nil { currentUserId = m.id }
        save()
        let fid = familyId
        Task { await cloud.push(member: m, familyId: fid) }
    }

    func updateMember(_ m: FamilyMember) {
        guard let i = members.firstIndex(where: { $0.id == m.id }) else { return }
        members[i] = m
        save()
        let fid = familyId
        Task { await cloud.push(member: m, familyId: fid) }
    }

    func deleteMember(_ id: UUID) {
        members.removeAll { $0.id == id }
        messages.removeAll { $0.authorId == id }
        if currentUserId == id { currentUserId = members.first?.id }
        save()
        Task { await cloud.deleteMember(id) }
    }

    func member(_ id: UUID?) -> FamilyMember? {
        guard let id else { return nil }
        return members.first { $0.id == id }
    }

    // MARK: - Messages

    func postMessage(_ text: String) {
        guard let uid = currentUserId else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let msg = FamilyMessage(authorId: uid, text: trimmed)
        messages.append(msg)
        save()
        // Push to CloudKit so other family members receive it.
        let fid = familyId
        Task { await cloud.push(message: msg, familyId: fid) }
    }

    func deleteMessage(_ id: UUID) {
        messages.removeAll { $0.id == id }
        save()
        Task { await cloud.deleteMessage(id) }
    }

    // MARK: - Cloud sync

    /// Pull any new messages from CloudKit into the local store.
    func syncMessages() async {
        let known = Set(messages.map(\.id))
        let fetched = await cloud.fetchNewMessages(familyId: familyId, knownIDs: known)
        cloudStatus = cloud.status
        guard !fetched.isEmpty else { return }
        messages.append(contentsOf: fetched)
        messages.sort { $0.date < $1.date }
        save()
    }

    /// Pull every kind of record (messages, events, todos, members, photos)
    /// modified since the last sync. Last-write-wins for items that already exist.
    /// - Parameter notifyUser: when true, posts local notifications for the new
    ///   records (used for background pushes). False on foreground refresh to
    ///   avoid spamming the user with already-seen content.
    func syncAll(notifyUser: Bool = false) async {
        async let newMessages = cloud.fetchNewMessages(familyId: familyId,
                                                       knownIDs: Set(messages.map(\.id)))
        async let updatedEvents = cloud.fetchEvents(familyId: familyId)
        async let updatedTodos = cloud.fetchTodos(familyId: familyId)
        async let updatedMembers = cloud.fetchMembers(familyId: familyId)
        async let newPhotos = cloud.fetchPhotos(familyId: familyId,
                                                knownIDs: Set(photos.map(\.id)))

        let (msg, evt, td, mem, ph) = await (newMessages, updatedEvents,
                                              updatedTodos, updatedMembers, newPhotos)
        cloudStatus = cloud.status
        var changed = false

        if !msg.isEmpty {
            messages.append(contentsOf: msg)
            messages.sort { $0.date < $1.date }
            changed = true
        }
        if !evt.isEmpty {
            var map: [UUID: FamilyEvent] = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
            for e in evt { map[e.id] = e }
            events = Array(map.values)
            changed = true
        }
        if !td.isEmpty {
            var map: [UUID: FamilyTodo] = Dictionary(uniqueKeysWithValues: todos.map { ($0.id, $0) })
            for t in td { map[t.id] = t }
            todos = Array(map.values)
            changed = true
        }
        if !mem.isEmpty {
            var map: [UUID: FamilyMember] = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
            for m in mem { map[m.id] = m }
            members = Array(map.values).sorted { $0.fullName < $1.fullName }
            changed = true
        }
        if !ph.isEmpty {
            // Newest first to match the existing photo wall sort.
            photos.insert(contentsOf: ph.sorted { $0.date > $1.date }, at: 0)
            changed = true
        }
        if changed { save() }

        // Note : we used to compose local notifications here, but CloudKit
        // subscriptions now deliver alert pushes directly (with the record
        // text in the body), so doing it again would duplicate every banner.
        _ = notifyUser
    }

    /// One-shot setup the first time the app comes online: register CloudKit
    /// push subscriptions, then do an initial sync.
    func bootstrapCloud() async {
        await cloud.registerSubscriptions(familyId: familyId)
        await syncAll(notifyUser: false)
    }

    // MARK: - Events

    func addEvent(_ e: FamilyEvent) {
        events.append(e); save()
        let fid = familyId
        Task { await cloud.push(event: e, familyId: fid) }
    }
    func updateEvent(_ e: FamilyEvent) {
        guard let i = events.firstIndex(where: { $0.id == e.id }) else { return }
        events[i] = e; save()
        let fid = familyId
        Task { await cloud.push(event: e, familyId: fid) }
    }
    func deleteEvent(_ id: UUID) {
        events.removeAll { $0.id == id }; save()
        Task { await cloud.deleteEvent(id) }
    }

    var upcomingEvents: [FamilyEvent] {
        events.sorted { $0.date < $1.date }
    }

    var upcomingBirthdays: [(member: FamilyMember, next: Date)] {
        let cal = Calendar.current
        let now = Date()
        return members.compactMap { m in
            guard let bd = m.birthDate else { return nil }
            let comps = cal.dateComponents([.month, .day], from: bd)
            var next = cal.nextDate(after: now, matching: comps, matchingPolicy: .nextTime) ?? now
            if cal.isDateInToday(now) {
                let today = cal.dateComponents([.month, .day], from: now)
                if today == comps { next = now }
            }
            return (m, next)
        }
        .sorted { $0.next < $1.next }
    }

    // MARK: - Todos

    func addTodo(_ t: FamilyTodo) {
        todos.append(t); save()
        let fid = familyId
        Task { await cloud.push(todo: t, familyId: fid) }
    }
    func toggleTodo(_ id: UUID) {
        guard let i = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[i].isDone.toggle()
        let updated = todos[i]
        save()
        let fid = familyId
        Task { await cloud.push(todo: updated, familyId: fid) }
    }
    func deleteTodo(_ id: UUID) {
        todos.removeAll { $0.id == id }; save()
        Task { await cloud.deleteTodo(id) }
    }

    // MARK: - Photos

    func addPhoto(_ p: FamilyPhoto) {
        photos.insert(p, at: 0); save()
        let fid = familyId
        Task { await cloud.push(photo: p, familyId: fid) }
    }
    func deletePhoto(_ id: UUID) {
        photos.removeAll { $0.id == id }; save()
        Task { await cloud.deletePhoto(id) }
    }

    // MARK: - Share / merge

    func makeWire() -> FamilyWire {
        FamilyWire(
            familyId: familyId,
            members: members,
            messages: messages,
            events: events,
            todos: todos,
            familyName: familyName
        )
    }

    /// Merge another wire payload : last-write-wins for same id (members/events/todos),
    /// union for messages (deduplicated by id).
    func merge(_ wire: FamilyWire) {
        if familyName.isEmpty { familyName = wire.familyName }
        // Adopt the shared family channel id when joining via URL.
        if let incoming = wire.familyId {
            familyId = incoming
        }

        var memberMap: [UUID: FamilyMember] = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
        for m in wire.members { memberMap[m.id] = m }
        members = Array(memberMap.values).sorted { $0.fullName < $1.fullName }

        var msgIds = Set(messages.map(\.id))
        for m in wire.messages where !msgIds.contains(m.id) {
            messages.append(m); msgIds.insert(m.id)
        }
        messages.sort { $0.date < $1.date }

        var eventMap: [UUID: FamilyEvent] = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
        for e in wire.events { eventMap[e.id] = e }
        events = Array(eventMap.values)

        var todoMap: [UUID: FamilyTodo] = Dictionary(uniqueKeysWithValues: todos.map { ($0.id, $0) })
        for t in wire.todos { todoMap[t.id] = t }
        todos = Array(todoMap.values)

        if currentUserId == nil { currentUserId = members.first?.id }
        save()
    }

    // MARK: - URLs

    static let webBase = "https://boboul-cloud.github.io/MonPetitReseau/"

    func shareURL() -> URL? {
        guard let token = URLCodec.encode(makeWire()) else { return nil }
        var s = "\(Self.webBase)#d=\(token)"
        if let me = currentUserId { s += "&me=\(me.uuidString)" }
        return URL(string: s)
    }

    /// Try to load a wire from a deep link / pasted URL.
    @discardableResult
    func importFromURL(_ url: URL) -> Bool {
        let raw = url.fragment ?? url.query ?? ""
        var token: String?
        for part in raw.split(separator: "&") {
            let kv = part.split(separator: "=", maxSplits: 1).map(String.init)
            if kv.count == 2, kv[0] == "d" { token = kv[1] }
        }
        guard let t = token, let wire = URLCodec.decode(t) else { return false }
        merge(wire)
        return true
    }

    // MARK: - Sample data

    func loadSampleIfEmpty() {
        guard members.isEmpty else { return }
        familyName = String(localized: "sample.family.name")
        let mom = FamilyMember(firstName: "Marie", lastName: "Dupont", emoji: "👩",
                               birthDate: cal(1962, 5, 12), phone: "", email: "", city: "Paris",
                               role: String(localized: "role.mother"), bio: "")
        let dad = FamilyMember(firstName: "Pierre", lastName: "Dupont", emoji: "👨",
                               birthDate: cal(1960, 9, 3), phone: "", email: "", city: "Paris",
                               role: String(localized: "role.father"), bio: "")
        let me  = FamilyMember(firstName: "Robert", lastName: "Dupont", emoji: "🧔",
                               birthDate: cal(1985, 2, 18), phone: "", email: "", city: "Lyon",
                               role: String(localized: "role.self"), bio: "")
        members = [mom, dad, me]
        currentUserId = me.id
        messages = [
            FamilyMessage(authorId: me.id,  text: String(localized: "sample.msg1")),
            FamilyMessage(authorId: mom.id, text: String(localized: "sample.msg2"))
        ]
        save()
    }

    private func cal(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d)) ?? Date()
    }
}

// MARK: - JSON helpers

extension JSONEncoder {
    static var iso: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }
}

extension JSONDecoder {
    static var iso: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }
}
