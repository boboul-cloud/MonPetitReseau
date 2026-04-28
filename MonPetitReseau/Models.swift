//
//  Models.swift
//  MonPetitReseau
//

import Foundation

// MARK: - Family Member

struct FamilyMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var emoji: String
    var birthDate: Date?
    var phone: String
    var email: String
    var city: String
    var role: String          // e.g. "Mom", "Brother", "Cousin"
    var bio: String
    var motherId: UUID?
    var fatherId: UUID?
    var partnerId: UUID?

    var fullName: String {
        let trimmed = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : trimmed
    }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        let initials = (f + l).uppercased()
        return initials.isEmpty ? "?" : initials
    }
}

// MARK: - Audience-restricted item

/// An item that may be restricted to a subset of group members.
/// `audienceIds == nil` (or empty) → visible to everyone in the group.
protocol AudienceConstrained {
    var audienceIds: [UUID]? { get }
}

extension AudienceConstrained {
    func isVisible(to userId: UUID?) -> Bool {
        guard let aids = audienceIds, !aids.isEmpty else { return true }
        guard let userId else { return false }
        return aids.contains(userId)
    }
}

// MARK: - Share circle (named subset of members, local-only for now)

struct ShareCircle: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var memberIds: [UUID]
}

// MARK: - Message (family wall)

struct FamilyMessage: Identifiable, Codable, Hashable, AudienceConstrained {
    var id: UUID = UUID()
    var authorId: UUID
    var text: String
    var date: Date = Date()
    var audienceIds: [UUID]? = nil
}

// MARK: - Family event (calendar)

struct FamilyEvent: Identifiable, Codable, Hashable, AudienceConstrained {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var location: String
    var details: String
    var createdBy: UUID
    var audienceIds: [UUID]? = nil
}

// MARK: - Shared todo

struct FamilyTodo: Identifiable, Codable, Hashable, AudienceConstrained {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
    var createdBy: UUID
    var assignedTo: UUID?
    var date: Date = Date()
    var audienceIds: [UUID]? = nil
}

// MARK: - Photo (local only — too big for URL share)

struct FamilyPhoto: Identifiable, Codable, Hashable, AudienceConstrained {
    var id: UUID = UUID()
    var authorId: UUID
    var caption: String
    var date: Date = Date()
    var imageData: Data        // JPEG
    var audienceIds: [UUID]? = nil
}

// MARK: - Wire format (sharable subset, no photos)

struct FamilyWire: Codable {
    var v: Int = 3
    var familyId: UUID?           // shared CloudKit channel id (added in v2)
    var members: [FamilyMember]
    var messages: [FamilyMessage]
    var events: [FamilyEvent]
    var todos: [FamilyTodo]
    var familyName: String
    var circles: [ShareCircle]?   // v3 — named share circles
}
