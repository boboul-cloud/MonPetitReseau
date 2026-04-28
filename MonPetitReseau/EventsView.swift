//
//  EventsView.swift
//  MonPetitReseau
//

import SwiftUI

struct EventsView: View {
    @Environment(FamilyStore.self) var store
    @State private var showAdd = false
    @State private var editing: FamilyEvent?

    var body: some View {
        NavigationStack {
            List {
                if !store.upcomingBirthdays.isEmpty {
                    Section("events.section.birthdays") {
                        ForEach(store.upcomingBirthdays, id: \.member.id) { item in
                            HStack {
                                AvatarView(member: item.member, size: 36)
                                VStack(alignment: .leading) {
                                    Text(item.member.fullName).font(.body.weight(.medium))
                                    Text(item.next, format: .dateTime.weekday(.wide).day().month(.wide))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("🎂")
                            }
                        }
                    }
                }

                Section("events.section.events") {
                    if store.upcomingEvents.isEmpty {
                        Text("events.empty").foregroundStyle(.secondary)
                    } else {
                        ForEach(store.upcomingEvents) { e in
                            if store.canEditByCurrentUser {
                                Button { editing = e } label: { eventRow(e) }
                                    .buttonStyle(.plain)
                            } else {
                                eventRow(e)
                            }
                        }
                        .onDelete { idx in
                            guard store.canEditByCurrentUser else { return }
                            let arr = store.upcomingEvents
                            for i in idx { store.deleteEvent(arr[i].id) }
                        }
                    }
                }
            }
            .navigationTitle("tab.events")
            .toolbar {
                if store.canEditByCurrentUser {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showAdd = true } label: { Image(systemName: "calendar.badge.plus") }
                    }
                }
            }
            .readOnlyBanner(if: !store.canEditByCurrentUser)
            .sheet(isPresented: $showAdd) { EventEditView(mode: .add) }
            .sheet(item: $editing) { e in EventEditView(mode: .edit(e)) }
        }
    }

    @ViewBuilder
    private func eventRow(_ e: FamilyEvent) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(e.date, format: .dateTime.day())
                    .font(.title2.bold())
                Text(e.date, format: .dateTime.month(.abbreviated))
                    .font(.caption).textCase(.uppercase)
            }
            .frame(width: 56)
            .padding(8)
            .background(Color.accentColor.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(e.title).font(.body.weight(.semibold))
                if !e.location.isEmpty {
                    Label(e.location, systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Text(e.date, format: .dateTime.hour().minute())
                        .font(.caption2).foregroundStyle(.tertiary)
                    AudienceBadge(audienceIds: e.audienceIds)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EventEditView: View {
    enum Mode { case add, edit(FamilyEvent) }
    @Environment(FamilyStore.self) var store
    @Environment(\.dismiss) var dismiss

    let mode: Mode

    @State private var title = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var details = ""
    @State private var audienceIds: [UUID]? = nil

    var isEditing: Bool { if case .edit = mode { return true } else { return false } }

    var body: some View {
        NavigationStack {
            Form {
                TextField("field.title", text: $title)
                DatePicker("field.date", selection: $date)
                TextField("field.location", text: $location)
                TextField("field.details", text: $details, axis: .vertical)
                    .lineLimit(2...6)

                Section {
                    AudiencePicker(selectedIds: $audienceIds)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if case .edit(let e) = mode { store.deleteEvent(e.id); dismiss() }
                        } label: { Label("button.delete", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "edit.event.title" : "add.event.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.save") {
                        switch mode {
                        case .add:
                            guard let uid = store.currentUserId else { dismiss(); return }
                            store.addEvent(FamilyEvent(
                                title: title, date: date, location: location,
                                details: details, createdBy: uid,
                                audienceIds: audienceIds
                            ))
                        case .edit(var e):
                            e.title = title; e.date = date
                            e.location = location; e.details = details
                            e.audienceIds = audienceIds
                            store.updateEvent(e)
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if case .edit(let e) = mode {
                    title = e.title; date = e.date
                    location = e.location; details = e.details
                    audienceIds = e.audienceIds
                }
            }
        }
    }
}
