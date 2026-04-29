//
//  FamilyStore.swift
//  MonPetitReseau
//
//  Two top-level @Observable classes :
//   - FamilyStore : the data of ONE group (members, messages, …).
//   - AppStore    : the collection of groups, with a selected one.
//

import Foundation
import SwiftUI

// MARK: - FamilyStore (one independent group)

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
    var circles: [ShareCircle]

    /// Member id of the group creator (the one who initially created it).
    /// Migrated/legacy groups have nil → treated as "no owner" (everyone can edit).
    var createdBy: UUID?
    /// Members the creator has granted edit permission to (in addition to themselves).
    var editorIds: [UUID]

    /// CloudKit sync layer (lazy: only used when actively messaging).
    let cloud = CloudSync()
    /// Surface-level status for the UI.
    var cloudStatus: CloudSync.Status = .idle

    /// Closure invoked after every save, so AppStore can aggregate cross-group
    /// state (e.g. members.json for the notification service extension).
    var onSave: (() -> Void)?

    // MARK: - Init

    /// Empty new group with a fresh familyId.
    init(newGroupNamed name: String) {
        self.familyName = name
        self.familyId = UUID()
        self.members = []
        self.messages = []
        self.events = []
        self.todos = []
        self.photos = []
        self.currentUserId = nil
        self.circles = []
        self.createdBy = nil
        self.editorIds = []
    }

    /// Restore from a persisted snapshot.
    init(snapshot s: Snapshot) {
        self.familyName = s.familyName
        self.familyId = s.familyId
        self.members = s.members
        self.messages = s.messages
        self.events = s.events
        self.todos = s.todos
        self.photos = s.photos
        self.currentUserId = s.currentUserId
        self.circles = s.circles ?? []
        self.createdBy = s.createdBy
        self.editorIds = s.editorIds ?? []
    }

    // MARK: - Persistence

    var persistKey: String { "MonPetitReseau.group.\(familyId.uuidString)" }

    func save() {
        let snap = Snapshot(
            familyName: familyName,
            familyId: familyId,
            members: members,
            messages: messages,
            events: events,
            todos: todos,
            photos: photos,
            currentUserId: currentUserId,
            circles: circles,
            createdBy: createdBy,
            editorIds: editorIds
        )
        if let data = try? JSONEncoder.iso.encode(snap) {
            UserDefaults.standard.set(data, forKey: persistKey)
        }
        onSave?()
    }

    struct Snapshot: Codable {
        var familyName: String
        var familyId: UUID
        var members: [FamilyMember]
        var messages: [FamilyMessage]
        var events: [FamilyEvent]
        var todos: [FamilyTodo]
        var photos: [FamilyPhoto]
        var currentUserId: UUID?
        var circles: [ShareCircle]?
        var createdBy: UUID?
        var editorIds: [UUID]?
    }

    // MARK: - Members

    func addMember(_ m: FamilyMember) {
        members.append(m)
        if currentUserId == nil { currentUserId = m.id }
        // The very first member added to a brand-new group becomes its creator.
        let becameOwner = (createdBy == nil && members.count == 1)
        if becameOwner {
            createdBy = m.id
            // Mark THIS device as the origin device for that group.
            // Stored only locally (UserDefaults) and never shared via the link,
            // so other devices cannot impersonate the creator.
            UserDefaults.standard.set(true, forKey: ownerDeviceKey)
        }
        save()
        let fid = familyId
        if becameOwner {
            pushOwnerMember(m)
        } else {
            Task { await cloud.push(member: m, familyId: fid) }
        }
    }

    func updateMember(_ m: FamilyMember) {
        guard let i = members.firstIndex(where: { $0.id == m.id }) else { return }
        members[i] = m
        save()
        let fid = familyId
        if createdBy == m.id {
            pushOwnerMember(m)
        } else {
            Task { await cloud.push(member: m, familyId: fid) }
        }
    }

    func deleteMember(_ id: UUID) {
        members.removeAll { $0.id == id }
        messages.removeAll { $0.authorId == id }
        if currentUserId == id { currentUserId = members.first?.id }
        // Drop the deleted member from any circle.
        for i in circles.indices {
            circles[i].memberIds.removeAll { $0 == id }
        }
        editorIds.removeAll { $0 == id }
        if createdBy == id { createdBy = members.first?.id }
        save()
        Task { await cloud.deleteMember(id) }
    }

    func member(_ id: UUID?) -> FamilyMember? {
        guard let id else { return nil }
        return members.first { $0.id == id }
    }

    // MARK: - Permissions

    /// UserDefaults key used to remember that THIS device is the origin
    /// device for the group (i.e. the one that created it).
    /// This flag is never serialized in shares, so other devices cannot
    /// claim ownership.
    private var ownerDeviceKey: String {
        "MonPetitReseau.ownerDevice.\(familyId.uuidString)"
    }

    /// True only on the device where the group was originally created.
    /// Backwards compatibility: groups created before this flag existed have
    /// no entry in UserDefaults. In that case, assume the device whose
    /// `currentUserId` matches `createdBy` is the origin device, and persist
    /// that assumption so it is stable across launches.
    var isOwnerDevice: Bool {
        if let v = UserDefaults.standard.object(forKey: ownerDeviceKey) as? Bool {
            return v
        }
        let inferred = (currentUserId != nil && currentUserId == createdBy)
        UserDefaults.standard.set(inferred, forKey: ownerDeviceKey)
        return inferred
    }

    /// Mark / unmark this device as origin (used by manual recovery flows).
    func setOwnerDevice(_ flag: Bool) {
        UserDefaults.standard.set(flag, forKey: ownerDeviceKey)
    }

    /// Whether `userId` is allowed to add/edit/delete content in this group.
    /// Legacy/unowned groups (`createdBy == nil`) grant edit access to everyone
    /// for backwards compatibility.
    /// Only the origin device can act as the creator: another device that
    /// imported the group cannot grant itself owner rights by selecting the
    /// creator in the "I am…" picker.
    func canEdit(_ userId: UUID?) -> Bool {
        guard let owner = createdBy else { return true }
        guard let uid = userId else { return false }
        if uid == owner { return isOwnerDevice }
        return editorIds.contains(uid)
    }

    /// Convenience for the local user.
    var canEditByCurrentUser: Bool { canEdit(currentUserId) }

    /// True when the local user is the creator of this group AND we are on
    /// the original device. Used to gate the permissions UI.
    var isOwnerCurrentUser: Bool {
        guard let owner = createdBy, let uid = currentUserId else { return false }
        return owner == uid && isOwnerDevice
    }

    func setEditor(_ id: UUID, allowed: Bool) {
        if allowed {
            if !editorIds.contains(id) { editorIds.append(id) }
        } else {
            editorIds.removeAll { $0 == id }
        }
        save()
        // The creator's Member record carries the group's `editorIds` and a
        // `groupCreator` flag, so other devices learn about permission changes
        // when they next sync members. Re-push the owner's member to update it.
        if let owner = createdBy, let m = member(owner) {
            pushOwnerMember(m)
        }
    }

    /// Push a member who is the group creator, embedding permission metadata.
    private func pushOwnerMember(_ m: FamilyMember) {
        let fid = familyId
        let editors = editorIds
        Task { await cloud.pushOwner(member: m, familyId: fid, editorIds: editors) }
    }

    // MARK: - Circles (named subsets of members)

    func addCircle(_ c: ShareCircle) {
        circles.append(c); save()
    }
    func updateCircle(_ c: ShareCircle) {
        guard let i = circles.firstIndex(where: { $0.id == c.id }) else { return }
        circles[i] = c; save()
    }
    func deleteCircle(_ id: UUID) {
        circles.removeAll { $0.id == id }; save()
    }

    // MARK: - Messages

    func postMessage(_ text: String, audienceIds: [UUID]? = nil) {
        guard let uid = currentUserId else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let msg = FamilyMessage(authorId: uid, text: trimmed,
                                audienceIds: normalize(audienceIds, author: uid))
        messages.append(msg)
        save()
        let fid = familyId
        Task { await cloud.push(message: msg, familyId: fid) }
    }

    func deleteMessage(_ id: UUID) {
        messages.removeAll { $0.id == id }
        save()
        Task { await cloud.deleteMessage(id) }
    }

    /// Items visible to the current user (or to a specific user).
    func visibleMessages(for userId: UUID? = nil) -> [FamilyMessage] {
        let uid = userId ?? currentUserId
        return messages.filter { $0.isVisible(to: uid) }
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
    func syncAll(notifyUser: Bool = false) async {
        async let newMessages = cloud.fetchNewMessages(familyId: familyId,
                                                       knownIDs: Set(messages.map(\.id)))
        async let updatedEvents = cloud.fetchEvents(familyId: familyId)
        async let updatedTodos = cloud.fetchTodos(familyId: familyId)
        async let updatedMembers = cloud.fetchMembersWithMeta(familyId: familyId)
        async let newPhotos = cloud.fetchPhotos(familyId: familyId,
                                                knownIDs: Set(photos.map(\.id)))

        let (msg, evt, td, memMeta, ph) = await (newMessages, updatedEvents,
                                                  updatedTodos, updatedMembers, newPhotos)
        let mem = memMeta.members
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
        // Adopt the group creator + editors from CloudKit when discovered.
        if let creator = memMeta.creatorId {
            if createdBy != creator { createdBy = creator; changed = true }
            if let inc = memMeta.editorIds, inc != editorIds {
                editorIds = inc; changed = true
            }
        }
        if !ph.isEmpty {
            photos.insert(contentsOf: ph.sorted { $0.date > $1.date }, at: 0)
            changed = true
        }
        if changed { save() }
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
        var ev = e
        ev.audienceIds = normalize(ev.audienceIds, author: ev.createdBy)
        events.append(ev); save()
        let fid = familyId
        Task { await cloud.push(event: ev, familyId: fid) }
    }
    func updateEvent(_ e: FamilyEvent) {
        guard let i = events.firstIndex(where: { $0.id == e.id }) else { return }
        var ev = e
        ev.audienceIds = normalize(ev.audienceIds, author: ev.createdBy)
        events[i] = ev; save()
        let fid = familyId
        Task { await cloud.push(event: ev, familyId: fid) }
    }
    func deleteEvent(_ id: UUID) {
        events.removeAll { $0.id == id }; save()
        Task { await cloud.deleteEvent(id) }
    }

    var upcomingEvents: [FamilyEvent] {
        visibleEvents().sorted { $0.date < $1.date }
    }

    func visibleEvents(for userId: UUID? = nil) -> [FamilyEvent] {
        let uid = userId ?? currentUserId
        return events.filter { $0.isVisible(to: uid) }
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
        var td = t
        td.audienceIds = normalize(td.audienceIds, author: td.createdBy)
        todos.append(td); save()
        let fid = familyId
        Task { await cloud.push(todo: td, familyId: fid) }
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

    func visibleTodos(for userId: UUID? = nil) -> [FamilyTodo] {
        let uid = userId ?? currentUserId
        return todos.filter { $0.isVisible(to: uid) }
    }

    // MARK: - Photos

    func addPhoto(_ p: FamilyPhoto) {
        var ph = p
        ph.audienceIds = normalize(ph.audienceIds, author: ph.authorId)
        photos.insert(ph, at: 0); save()
        let fid = familyId
        Task { await cloud.push(photo: ph, familyId: fid) }
    }
    func deletePhoto(_ id: UUID) {
        photos.removeAll { $0.id == id }; save()
        Task { await cloud.deletePhoto(id) }
    }

    func visiblePhotos(for userId: UUID? = nil) -> [FamilyPhoto] {
        let uid = userId ?? currentUserId
        return photos.filter { $0.isVisible(to: uid) }
    }

    // MARK: - Audience helpers

    /// Normalize an audience selection :
    ///   - nil or empty → nil (everyone in the group)
    ///   - non-empty    → ensure the author is included so they always see their own item
    private func normalize(_ ids: [UUID]?, author: UUID) -> [UUID]? {
        guard let ids, !ids.isEmpty else { return nil }
        var s = Set(ids); s.insert(author)
        return Array(s)
    }

    /// Resolve a name for an audience set : circle name if it matches one, else "n personnes".
    func audienceLabel(for ids: [UUID]?) -> String? {
        guard let ids, !ids.isEmpty else { return nil }
        let s = Set(ids)
        if let c = circles.first(where: { Set($0.memberIds) == s }) { return c.name }
        let names = ids.compactMap { member($0)?.firstName }.prefix(3).joined(separator: ", ")
        let extra = ids.count - 3
        return extra > 0 ? "\(names) +\(extra)" : names
    }

    // MARK: - Share / merge

    func makeWire() -> FamilyWire {
        // Drop avatar bytes from the share payload — they are JPEG (already
        // compressed, so zlib can't shrink them) and inflated by ~33% via
        // JSON base64 encoding, which can quickly push the URL past the
        // SMS/iMessage practical length limit. Photos still travel between
        // iPhones over CloudKit ; the web companion falls back to emojis.
        let lightMembers = members.map { m -> FamilyMember in
            var copy = m
            copy.avatarData = nil
            return copy
        }
        return FamilyWire(
            familyId: familyId,
            members: lightMembers,
            messages: messages,
            events: events,
            todos: todos,
            familyName: familyName,
            circles: circles,
            createdBy: createdBy,
            editorIds: editorIds.isEmpty ? nil : editorIds
        )
    }

    /// Merge another wire payload : last-write-wins for same id (members/events/todos),
    /// union for messages (deduplicated by id).
    func merge(_ wire: FamilyWire) {
        if familyName.isEmpty { familyName = wire.familyName }
        if let incoming = wire.familyId {
            familyId = incoming
        }

        var memberMap: [UUID: FamilyMember] = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
        for var m in wire.members {
            // The share wire strips avatar bytes to keep URLs short. Don't let
            // that nil overwrite an avatar we already have locally (or one we
            // have already received via CloudKit).
            if m.avatarData == nil, let existing = memberMap[m.id]?.avatarData {
                m.avatarData = existing
            }
            memberMap[m.id] = m
        }
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

        if let inc = wire.circles, !inc.isEmpty {
            var circleMap: [UUID: ShareCircle] = Dictionary(uniqueKeysWithValues: circles.map { ($0.id, $0) })
            for c in inc { circleMap[c.id] = c }
            circles = Array(circleMap.values)
        }

        // Adopt creator/editors from the wire when we don't have one yet, or when
        // the incoming wire was authored by the current creator (last-write-wins
        // for the editors list).
        if createdBy == nil, let inc = wire.createdBy {
            createdBy = inc
        }
        if let inc = wire.editorIds {
            editorIds = inc
        }

        if currentUserId == nil { currentUserId = members.first?.id }
        save()
    }

    // MARK: - URLs

    static let webBase = "https://boboul-cloud.github.io/MonPetitReseau/"
    static let appScheme = "monpetitreseau"

    func shareURL() -> URL? {
        guard let token = URLCodec.encode(makeWire()) else { return nil }
        var s = "\(Self.webBase)#d=\(token)"
        if let me = currentUserId { s += "&me=\(me.uuidString)" }
        return URL(string: s)
    }

    /// Custom-scheme URL that opens directly inside the app (no Safari hop).
    func shareAppURL() -> URL? {
        guard let token = URLCodec.encode(makeWire()) else { return nil }
        var s = "\(Self.appScheme)://import#d=\(token)"
        if let me = currentUserId { s += "&me=\(me.uuidString)" }
        return URL(string: s)
    }

    /// Pretty multi-line message ready for SMS / iMessage / Mail.
    func shareMessage() -> String {
        let name = familyName.isEmpty
            ? String(localized: "share.default.familyName")
            : familyName
        let intro = String(format: String(localized: "share.message.intro"), name)
        var lines: [String] = [intro]
        if let app = shareAppURL() {
            lines.append("")
            lines.append(String(localized: "share.message.app"))
            lines.append(app.absoluteString)
        }
        if let web = shareURL() {
            lines.append("")
            lines.append(String(localized: "share.message.web"))
            lines.append(web.absoluteString)
        }
        return lines.joined(separator: "\n")
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

// MARK: - AppStore (collection of independent groups)

@MainActor
@Observable
final class AppStore {

    /// All groups the user belongs to. Always non-empty after init().
    var groups: [FamilyStore]
    /// Currently displayed group.
    var selectedGroupId: UUID

    private static let appKey = "MonPetitReseau.app.v3"
    private static let defaults = UserDefaults.standard

    /// Convenience : the active group, fallback to the first one if the
    /// selected id no longer exists.
    var active: FamilyStore {
        groups.first { $0.familyId == selectedGroupId } ?? groups[0]
    }

    // MARK: - Init / migration

    init() {
        var loaded: [FamilyStore] = []
        var selected: UUID?

        // 1. Load app-level index (v3+).
        if let raw = Self.defaults.data(forKey: Self.appKey),
           let app = try? JSONDecoder.iso.decode(AppSnapshot.self, from: raw) {
            for gid in app.groupIds {
                let key = "MonPetitReseau.group.\(gid.uuidString)"
                if let data = Self.defaults.data(forKey: key),
                   let snap = try? JSONDecoder.iso.decode(FamilyStore.Snapshot.self, from: data) {
                    loaded.append(FamilyStore(snapshot: snap))
                }
            }
            selected = app.selectedGroupId
        }

        // 2. Migration v2 (single legacy group) → wrap into the new array.
        if loaded.isEmpty,
           let raw = Self.defaults.data(forKey: "MonPetitReseau.state.v2"),
           let snap = try? JSONDecoder.iso.decode(LegacySnapshotV2.self, from: raw) {
            let g = FamilyStore(snapshot: FamilyStore.Snapshot(
                familyName: snap.familyName,
                familyId: snap.familyId,
                members: snap.members,
                messages: snap.messages,
                events: snap.events,
                todos: snap.todos,
                photos: snap.photos,
                currentUserId: snap.currentUserId,
                circles: nil
            ))
            loaded.append(g)
            g.save()
        }

        // 3. Migration v1 (no familyId) → wrap with a fresh familyId.
        if loaded.isEmpty,
           let raw = Self.defaults.data(forKey: "MonPetitReseau.state.v1"),
           let snap = try? JSONDecoder.iso.decode(LegacySnapshotV1.self, from: raw) {
            let g = FamilyStore(snapshot: FamilyStore.Snapshot(
                familyName: snap.familyName,
                familyId: UUID(),
                members: snap.members,
                messages: snap.messages,
                events: snap.events,
                todos: snap.todos,
                photos: snap.photos,
                currentUserId: snap.currentUserId,
                circles: nil
            ))
            loaded.append(g)
            g.save()
        }

        // 4. Fresh install : start with one empty group so the UI always has
        //    something to display (the onboarding sheet will fill it in).
        if loaded.isEmpty {
            loaded.append(FamilyStore(newGroupNamed: ""))
        }

        self.groups = loaded
        self.selectedGroupId = selected.flatMap { sid in
            loaded.first { $0.familyId == sid }?.familyId
        } ?? loaded[0].familyId

        // Wire each group's onSave to keep the aggregated members file in sync
        // for the notification service extension.
        for g in groups { g.onSave = { [weak self] in self?.writeAggregatedMembers() } }
        save()
        writeAggregatedMembers()
    }

    // MARK: - Persistence (app-level index)

    private struct AppSnapshot: Codable {
        var groupIds: [UUID]
        var selectedGroupId: UUID?
    }

    private struct LegacySnapshotV2: Codable {
        var familyName: String
        var familyId: UUID
        var members: [FamilyMember]
        var messages: [FamilyMessage]
        var events: [FamilyEvent]
        var todos: [FamilyTodo]
        var photos: [FamilyPhoto]
        var currentUserId: UUID?
    }

    private struct LegacySnapshotV1: Codable {
        var familyName: String
        var members: [FamilyMember]
        var messages: [FamilyMessage]
        var events: [FamilyEvent]
        var todos: [FamilyTodo]
        var photos: [FamilyPhoto]
        var currentUserId: UUID?
    }

    func save() {
        let snap = AppSnapshot(groupIds: groups.map(\.familyId),
                                selectedGroupId: selectedGroupId)
        if let data = try? JSONEncoder.iso.encode(snap) {
            Self.defaults.set(data, forKey: Self.appKey)
        }
    }

    /// Mirror (memberId → fullName) across ALL groups into the App Group
    /// container, so the Notification Service Extension can resolve any
    /// sender's name regardless of which group the push came from.
    private func writeAggregatedMembers() {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier:
                "group.bob.oulhen-gmail.com.MonPetitReseau")
        else { return }
        var dict: [String: String] = [:]
        for g in groups {
            for m in g.members { dict[m.id.uuidString] = m.fullName }
        }
        let url = container.appendingPathComponent("members.json")
        if let data = try? JSONEncoder().encode(dict) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - Group management

    @discardableResult
    func createGroup(named name: String) -> FamilyStore {
        let g = FamilyStore(newGroupNamed: name)
        g.onSave = { [weak self] in self?.writeAggregatedMembers() }
        groups.append(g)
        selectedGroupId = g.familyId
        g.save()
        save()
        return g
    }

    func select(_ id: UUID) {
        guard groups.contains(where: { $0.familyId == id }) else { return }
        selectedGroupId = id
        save()
    }

    func deleteGroup(_ id: UUID) {
        // Wipe persisted state for this group.
        let key = "MonPetitReseau.group.\(id.uuidString)"
        UserDefaults.standard.removeObject(forKey: key)

        groups.removeAll { $0.familyId == id }
        if groups.isEmpty {
            // Always keep at least one group around.
            let g = FamilyStore(newGroupNamed: "")
            g.onSave = { [weak self] in self?.writeAggregatedMembers() }
            groups.append(g)
        }
        if !groups.contains(where: { $0.familyId == selectedGroupId }) {
            selectedGroupId = groups[0].familyId
        }
        save()
        writeAggregatedMembers()
    }

    // MARK: - URL import

    /// Parse a deep link / pasted URL. If the wire's familyId matches an
    /// existing group, merge into it. Otherwise create a fresh group.
    /// Always selects the resulting group.
    @discardableResult
    func importFromURL(_ url: URL) -> Bool {
        let raw = url.fragment ?? url.query ?? ""
        var token: String?
        var meId: UUID?
        for part in raw.split(separator: "&") {
            let kv = part.split(separator: "=", maxSplits: 1).map(String.init)
            guard kv.count == 2 else { continue }
            if kv[0] == "d" { token = kv[1] }
            if kv[0] == "me" { meId = UUID(uuidString: kv[1]) }
        }
        guard let t = token, let wire = URLCodec.decode(t) else { return false }

        let target: FamilyStore
        if let fid = wire.familyId,
           let existing = groups.first(where: { $0.familyId == fid }) {
            target = existing
        } else {
            // First-time install: if the only group is empty, reuse it.
            if let onlyEmpty = groups.first, groups.count == 1,
               onlyEmpty.members.isEmpty && onlyEmpty.messages.isEmpty {
                target = onlyEmpty
            } else {
                target = createGroup(named: wire.familyName)
            }
        }
        target.merge(wire)
        if let me = meId, target.members.contains(where: { $0.id == me }) {
            target.currentUserId = me
            target.save()
        }
        selectedGroupId = target.familyId
        save()
        return true
    }

    /// Bootstrap CloudKit subscriptions for every group.
    func bootstrapAllGroups() async {
        for g in groups { await g.bootstrapCloud() }
    }

    /// Sync every group (called on background push or foreground).
    func syncAll(notifyUser: Bool = false) async {
        for g in groups { await g.syncAll(notifyUser: notifyUser) }
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
