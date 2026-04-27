//
//  DirectoryView.swift
//  MonPetitReseau
//

import SwiftUI

struct DirectoryView: View {
    @Environment(FamilyStore.self) var store
    @State private var showAdd = false
    @State private var query = ""

    var filtered: [FamilyMember] {
        let sorted = store.members.sorted { $0.fullName < $1.fullName }
        guard !query.isEmpty else { return sorted }
        let q = query.lowercased()
        return sorted.filter {
            $0.fullName.lowercased().contains(q) ||
            $0.role.lowercased().contains(q) ||
            $0.city.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !store.upcomingBirthdays.prefix(3).isEmpty {
                    Section("directory.section.birthdays") {
                        ForEach(Array(store.upcomingBirthdays.prefix(3)), id: \.member.id) { item in
                            HStack {
                                AvatarView(member: item.member, size: 36)
                                VStack(alignment: .leading) {
                                    Text(item.member.fullName).font(.subheadline.bold())
                                    Text(item.next, format: .dateTime.day().month(.wide))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("🎂").font(.title3)
                            }
                        }
                    }
                }

                Section {
                    ForEach(filtered) { m in
                        NavigationLink(value: m.id) {
                            MemberRow(member: m, isCurrent: m.id == store.currentUserId)
                        }
                    }
                    .onDelete { idx in
                        for i in idx { store.deleteMember(filtered[i].id) }
                    }
                }
            }
            .searchable(text: $query, prompt: Text("directory.search"))
            .navigationTitle(Text(store.familyName.isEmpty
                                  ? String(localized: "tab.directory")
                                  : store.familyName))
            .navigationDestination(for: UUID.self) { id in
                if let m = store.member(id) { MemberDetailView(memberId: m.id) }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "person.badge.plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                MemberEditView(mode: .add)
            }
        }
    }
}

struct MemberRow: View {
    let member: FamilyMember
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(member: member, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(member.fullName).font(.body.weight(.semibold))
                    if isCurrent {
                        Text("badge.you")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2),
                                        in: Capsule())
                    }
                }
                if !member.role.isEmpty {
                    Text(member.role).font(.caption).foregroundStyle(.secondary)
                }
                if !member.city.isEmpty {
                    Label(member.city, systemImage: "mappin.and.ellipse")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail

struct MemberDetailView: View {
    @Environment(FamilyStore.self) var store
    let memberId: UUID
    @State private var showEdit = false

    var member: FamilyMember? { store.member(memberId) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let m = member {
                    AvatarView(member: m, size: 110)
                        .padding(.top, 20)
                    Text(m.fullName).font(.title.bold())
                    if !m.role.isEmpty {
                        Text(m.role).font(.headline).foregroundStyle(.secondary)
                    }
                    if !m.bio.isEmpty {
                        Text(m.bio)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 0) {
                        if let bd = m.birthDate {
                            InfoRow(icon: "gift", label: "field.birthDate",
                                    value: bd.formatted(date: .long, time: .omitted))
                        }
                        if !m.phone.isEmpty {
                            InfoRow(icon: "phone.fill", label: "field.phone", value: m.phone,
                                    link: URL(string: "tel:\(m.phone)"))
                        }
                        if !m.email.isEmpty {
                            InfoRow(icon: "envelope.fill", label: "field.email", value: m.email,
                                    link: URL(string: "mailto:\(m.email)"))
                        }
                        if !m.city.isEmpty {
                            InfoRow(icon: "mappin.and.ellipse", label: "field.city", value: m.city)
                        }
                        if let mom = store.member(m.motherId) {
                            InfoRow(icon: "person.fill", label: "field.mother", value: mom.fullName)
                        }
                        if let dad = store.member(m.fatherId) {
                            InfoRow(icon: "person.fill", label: "field.father", value: dad.fullName)
                        }
                        if let p = store.member(m.partnerId) {
                            InfoRow(icon: "heart.fill", label: "field.partner", value: p.fullName)
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Button {
                        store.currentUserId = m.id
                        store.save()
                    } label: {
                        Label("detail.setAsMe", systemImage: "checkmark.seal.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    .disabled(store.currentUserId == m.id)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(member?.fullName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("button.edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let m = member { MemberEditView(mode: .edit(m)) }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: LocalizedStringKey
    let value: String
    var link: URL?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                if let link {
                    Link(value, destination: link)
                } else {
                    Text(value)
                }
            }
            Spacer()
        }
        .padding(.vertical, 10).padding(.horizontal, 14)
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - Add / Edit member

struct MemberEditView: View {
    enum Mode { case add, edit(FamilyMember) }

    @Environment(FamilyStore.self) var store
    @Environment(\.dismiss) var dismiss

    let mode: Mode

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var emoji = "🙂"
    @State private var hasBirthDate = false
    @State private var birthDate = Date()
    @State private var phone = ""
    @State private var email = ""
    @State private var city = ""
    @State private var role = ""
    @State private var bio = ""
    @State private var motherId: UUID?
    @State private var fatherId: UUID?
    @State private var partnerId: UUID?

    private let emojis = ["🙂","😀","😎","🥳","🧔","👨","👩","🧑","👴","👵","👶","🧓","👧","👦","🦊","🐱","🐶","🦁","🐼","🦄"]

    var isEditing: Bool {
        if case .edit = mode { return true } else { return false }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("section.identity") {
                    EmojiPicker(selected: $emoji, options: emojis)
                    TextField("field.firstName", text: $firstName)
                    TextField("field.lastName", text: $lastName)
                    TextField("field.role", text: $role)
                }

                Section("section.contact") {
                    TextField("field.phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("field.email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("field.city", text: $city)
                }

                Section("section.birthDate") {
                    Toggle("field.hasBirthDate", isOn: $hasBirthDate)
                    if hasBirthDate {
                        DatePicker("field.birthDate", selection: $birthDate,
                                   in: ...Date(), displayedComponents: .date)
                    }
                }

                Section("section.family") {
                    OptionalMemberPicker(label: "field.mother", selection: $motherId)
                    OptionalMemberPicker(label: "field.father", selection: $fatherId)
                    OptionalMemberPicker(label: "field.partner", selection: $partnerId)
                }

                Section("section.bio") {
                    TextField("field.bio", text: $bio, axis: .vertical)
                        .lineLimit(3...8)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if case .edit(let m) = mode {
                                store.deleteMember(m.id); dismiss()
                            }
                        } label: {
                            Label("button.delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "edit.member.title" : "add.member.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.save") { commit() }
                        .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if case .edit(let m) = mode {
                    firstName = m.firstName; lastName = m.lastName; emoji = m.emoji.isEmpty ? "🙂" : m.emoji
                    hasBirthDate = m.birthDate != nil
                    if let bd = m.birthDate { birthDate = bd }
                    phone = m.phone; email = m.email; city = m.city
                    role = m.role; bio = m.bio
                    motherId = m.motherId; fatherId = m.fatherId; partnerId = m.partnerId
                }
            }
        }
    }

    private func commit() {
        switch mode {
        case .add:
            let m = FamilyMember(
                firstName: firstName, lastName: lastName, emoji: emoji,
                birthDate: hasBirthDate ? birthDate : nil,
                phone: phone, email: email, city: city,
                role: role, bio: bio,
                motherId: motherId, fatherId: fatherId, partnerId: partnerId
            )
            store.addMember(m)
        case .edit(var m):
            m.firstName = firstName; m.lastName = lastName; m.emoji = emoji
            m.birthDate = hasBirthDate ? birthDate : nil
            m.phone = phone; m.email = email; m.city = city
            m.role = role; m.bio = bio
            m.motherId = motherId; m.fatherId = fatherId; m.partnerId = partnerId
            store.updateMember(m)
        }
        dismiss()
    }
}

struct OptionalMemberPicker: View {
    @Environment(FamilyStore.self) var store
    let label: LocalizedStringKey
    @Binding var selection: UUID?

    var body: some View {
        Picker(label, selection: $selection) {
            Text("picker.none").tag(UUID?.none)
            ForEach(store.members) { m in
                Text(m.fullName).tag(UUID?.some(m.id))
            }
        }
    }
}
