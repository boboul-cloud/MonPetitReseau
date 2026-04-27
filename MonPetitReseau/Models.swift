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

// MARK: - Message (family wall)

struct FamilyMessage: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var authorId: UUID
    var text: String
    var date: Date = Date()
}

// MARK: - Family event (calendar)

struct FamilyEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var location: String
    var details: String
    var createdBy: UUID
}

// MARK: - Shared todo

struct FamilyTodo: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
    var createdBy: UUID
    var assignedTo: UUID?
    var date: Date = Date()
}

// MARK: - Photo (local only — too big for URL share)

struct FamilyPhoto: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var authorId: UUID
    var caption: String
    var date: Date = Date()
    var imageData: Data        // JPEG
}

// MARK: - Wire format (sharable subset, no photos)

struct FamilyWire: Codable {
    var v: Int = 1
    var members: [FamilyMember]
    var messages: [FamilyMessage]
    var events: [FamilyEvent]
    var todos: [FamilyTodo]
    var familyName: String
}
