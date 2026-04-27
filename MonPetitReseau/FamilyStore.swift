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
    var members: [FamilyMember]
    var messages: [FamilyMessage]
    var events: [FamilyEvent]
    var todos: [FamilyTodo]
    var photos: [FamilyPhoto]
    var currentUserId: UUID?

    private static let key = "MonPetitReseau.state.v1"
    private static let defaults = UserDefaults.standard

    // MARK: - Init

    init() {
        if let raw = Self.defaults.data(forKey: Self.key),
           let snap = try? JSONDecoder.iso.decode(Snapshot.self, from: raw) {
            self.familyName = snap.familyName
            self.members = snap.members
            self.messages = snap.messages
            self.events = snap.events
            self.todos = snap.todos
            self.photos = snap.photos
            self.currentUserId = snap.currentUserId
        } else {
            self.familyName = ""
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
    }

    private struct Snapshot: Codable {
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
    }

    func updateMember(_ m: FamilyMember) {
        guard let i = members.firstIndex(where: { $0.id == m.id }) else { return }
        members[i] = m
        save()
    }

    func deleteMember(_ id: UUID) {
        members.removeAll { $0.id == id }
        messages.removeAll { $0.authorId == id }
        if currentUserId == id { currentUserId = members.first?.id }
        save()
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
        messages.append(FamilyMessage(authorId: uid, text: trimmed))
        save()
    }

    func deleteMessage(_ id: UUID) {
        messages.removeAll { $0.id == id }
        save()
    }

    // MARK: - Events

    func addEvent(_ e: FamilyEvent) { events.append(e); save() }
    func updateEvent(_ e: FamilyEvent) {
        guard let i = events.firstIndex(where: { $0.id == e.id }) else { return }
        events[i] = e; save()
    }
    func deleteEvent(_ id: UUID) {
        events.removeAll { $0.id == id }; save()
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

    func addTodo(_ t: FamilyTodo) { todos.append(t); save() }
    func toggleTodo(_ id: UUID) {
        guard let i = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[i].isDone.toggle(); save()
    }
    func deleteTodo(_ id: UUID) {
        todos.removeAll { $0.id == id }; save()
    }

    // MARK: - Photos

    func addPhoto(_ p: FamilyPhoto) { photos.insert(p, at: 0); save() }
    func deletePhoto(_ id: UUID) {
        photos.removeAll { $0.id == id }; save()
    }

    // MARK: - Share / merge

    func makeWire() -> FamilyWire {
        FamilyWire(
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
