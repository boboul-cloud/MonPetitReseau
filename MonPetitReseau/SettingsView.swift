//
//  SettingsView.swift
//  MonPetitReseau
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) var app
    @Environment(FamilyStore.self) var store
    @State private var familyName = ""
    @State private var showImport = false
    @State private var importText = ""
    @State private var importResult: ImportResult?
    @State private var showHelp = false
    @State private var showCircles = false
    @State private var showDeleteConfirm = false

    enum ImportResult: Identifiable {
        case ok, fail
        var id: Int { self == .ok ? 1 : 0 }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.section.family") {
                    TextField("field.familyName", text: $familyName)
                        .onChange(of: familyName) { _, v in
                            store.familyName = v; store.save()
                        }
                    Picker("settings.you", selection: Binding(
                        get: { store.currentUserId },
                        set: { store.currentUserId = $0; store.save() }
                    )) {
                        Text("picker.none").tag(UUID?.none)
                        ForEach(store.members) { m in
                            Text(m.fullName).tag(UUID?.some(m.id))
                        }
                    }
                }

                Section("settings.section.circles") {
                    Text("settings.circles.help")
                        .font(.caption).foregroundStyle(.secondary)
                    Button {
                        showCircles = true
                    } label: {
                        HStack {
                            Label("settings.circles.manage", systemImage: "person.2.circle")
                            Spacer()
                            Text("\(store.circles.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("settings.section.share") {
                    Text("settings.share.help")
                        .font(.caption).foregroundStyle(.secondary)
                    let message = store.shareMessage()
                    let appURL = store.shareAppURL()
                    if !message.isEmpty {
                        ShareLink(item: message,
                                  subject: Text(store.familyName.isEmpty
                                                ? "MonPetitReseau"
                                                : store.familyName)) {
                            Label("settings.share.button", systemImage: "square.and.arrow.up")
                        }
                    }
                    if let appURL {
                        Text(appURL.absoluteString)
                            .font(.caption2).foregroundStyle(.secondary)
                            .lineLimit(2).truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                }

                Section("settings.section.import") {
                    Button {
                        importText = ""; showImport = true
                    } label: {
                        Label("settings.import.button", systemImage: "tray.and.arrow.down")
                    }
                }

                Section("settings.section.about") {
                    Button {
                        showHelp = true
                    } label: {
                        Label("settings.help.button", systemImage: "questionmark.circle.fill")
                    }
                    LabeledContent("settings.about.app", value: "MonPetitReseau 1.0")
                    LabeledContent("settings.about.groups", value: "\(app.groups.count)")
                    LabeledContent("settings.about.members", value: "\(store.members.count)")
                    LabeledContent("settings.about.messages", value: "\(store.messages.count)")
                    LabeledContent("settings.about.events", value: "\(store.events.count)")
                    LabeledContent("settings.about.photos", value: "\(store.photos.count)")
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("settings.deleteGroup", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("tab.settings")
            .onAppear { familyName = store.familyName }
            .onChange(of: store.familyId) { _, _ in familyName = store.familyName }
            .sheet(isPresented: $showHelp) { HelpView() }
            .sheet(isPresented: $showCircles) {
                CirclesManagerView()
            }
            .alert("settings.import.title", isPresented: $showImport) {
                TextField("settings.import.placeholder", text: $importText)
                    .textInputAutocapitalization(.never)
                Button("button.import") {
                    let trimmed = importText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let url = URL(string: trimmed), app.importFromURL(url) {
                        importResult = .ok
                    } else {
                        importResult = .fail
                    }
                }
                Button("button.cancel", role: .cancel) { }
            } message: {
                Text("settings.import.help")
            }
            .alert(item: $importResult) { result in
                switch result {
                case .ok:  return Alert(title: Text("settings.import.ok"))
                case .fail:return Alert(title: Text("settings.import.fail"))
                }
            }
            .confirmationDialog("settings.deleteGroup.confirm.title",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("settings.deleteGroup.confirm.button", role: .destructive) {
                    app.deleteGroup(store.familyId)
                }
                Button("button.cancel", role: .cancel) { }
            } message: {
                Text("settings.deleteGroup.confirm.message")
            }
        }
    }
}

// MARK: - Circles manager

struct CirclesManagerView: View {
    @Environment(FamilyStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var editing: ShareCircle?
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("settings.circles.help")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if store.circles.isEmpty {
                    ContentUnavailableView("circles.empty.title",
                                           systemImage: "person.2.circle",
                                           description: Text("circles.empty.subtitle"))
                } else {
                    ForEach(store.circles) { c in
                        Button { editing = c } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(c.name).font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(c.memberIds.compactMap { store.member($0)?.fullName }
                                            .joined(separator: ", "))
                                        .font(.caption).foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary).font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { idx in
                        for i in idx { store.deleteCircle(store.circles[i].id) }
                    }
                }
            }
            .navigationTitle("settings.circles.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                CircleEditView(mode: .add)
            }
            .sheet(item: $editing) { c in
                CircleEditView(mode: .edit(c))
            }
        }
    }
}

struct CircleEditView: View {
    enum Mode: Identifiable {
        case add
        case edit(ShareCircle)
        var id: String {
            if case .edit(let c) = self { return c.id.uuidString }
            return "add"
        }
    }
    @Environment(FamilyStore.self) var store
    @Environment(\.dismiss) var dismiss
    let mode: Mode

    @State private var name = ""
    @State private var selected: Set<UUID> = []

    var isEditing: Bool { if case .edit = mode { return true } else { return false } }

    var body: some View {
        NavigationStack {
            Form {
                Section("circles.edit.name") {
                    TextField("field.name", text: $name)
                }
                Section("circles.edit.members") {
                    ForEach(store.members) { m in
                        Button {
                            if selected.contains(m.id) { selected.remove(m.id) }
                            else { selected.insert(m.id) }
                        } label: {
                            HStack {
                                AvatarView(member: m, size: 28)
                                Text(m.fullName)
                                Spacer()
                                if selected.contains(m.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if case .edit(let c) = mode { store.deleteCircle(c.id); dismiss() }
                        } label: { Label("button.delete", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "circles.edit.title" : "circles.add.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespaces)
                        switch mode {
                        case .add:
                            store.addCircle(ShareCircle(name: trimmedName,
                                                       memberIds: Array(selected)))
                        case .edit(var c):
                            c.name = trimmedName
                            c.memberIds = Array(selected)
                            store.updateCircle(c)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                              || selected.isEmpty)
                }
            }
            .onAppear {
                if case .edit(let c) = mode {
                    name = c.name
                    selected = Set(c.memberIds)
                }
            }
        }
    }
}

// MARK: - Audience badge (small lock + label)

struct AudienceBadge: View {
    @Environment(FamilyStore.self) var store
    let audienceIds: [UUID]?

    var body: some View {
        if let ids = audienceIds, !ids.isEmpty {
            HStack(spacing: 3) {
                Image(systemName: "lock.fill")
                Text(store.audienceLabel(for: ids) ?? "")
                    .lineLimit(1)
            }
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
            .foregroundStyle(Color.accentColor)
        }
    }
}

// MARK: - Audience picker (reusable)

/// Picker shown in compose flows to choose the audience of a new item.
/// Returns nil = everyone, or a non-empty set of member IDs.
struct AudiencePicker: View {
    @Environment(FamilyStore.self) var store
    @Binding var selectedIds: [UUID]?      // nil = everyone
    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack {
                Image(systemName: "eye")
                Text("audience.label")
                Spacer()
                Text(displayText)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary).font(.caption)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            AudienceChooserSheet(selectedIds: $selectedIds)
        }
    }

    private var displayText: String {
        if let ids = selectedIds, !ids.isEmpty {
            return store.audienceLabel(for: ids) ?? String(localized: "audience.custom")
        }
        return String(localized: "audience.everyone")
    }
}

struct AudienceChooserSheet: View {
    @Environment(FamilyStore.self) var store
    @Environment(\.dismiss) var dismiss
    @Binding var selectedIds: [UUID]?
    @State private var mode: PickerMode = .everyone
    @State private var picked: Set<UUID> = []
    @State private var pickedCircle: UUID?

    enum PickerMode: String, CaseIterable, Identifiable {
        case everyone, circle, custom
        var id: String { rawValue }
        var label: LocalizedStringKey {
            switch self {
            case .everyone: return "audience.everyone"
            case .circle:   return "audience.circle"
            case .custom:   return "audience.custom"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("audience.label", selection: $mode) {
                    ForEach(PickerMode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.segmented)

                switch mode {
                case .everyone:
                    Text("audience.everyone.help")
                        .font(.caption).foregroundStyle(.secondary)
                case .circle:
                    if store.circles.isEmpty {
                        Text("audience.noCircles.help")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Section("audience.pickCircle") {
                            ForEach(store.circles) { c in
                                Button {
                                    pickedCircle = c.id
                                    picked = Set(c.memberIds)
                                } label: {
                                    HStack {
                                        Text(c.name)
                                        Spacer()
                                        if pickedCircle == c.id {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color.accentColor)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                case .custom:
                    Section("audience.pickMembers") {
                        ForEach(store.members) { m in
                            Button {
                                if picked.contains(m.id) { picked.remove(m.id) }
                                else { picked.insert(m.id) }
                            } label: {
                                HStack {
                                    AvatarView(member: m, size: 26)
                                    Text(m.fullName)
                                    Spacer()
                                    if picked.contains(m.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("audience.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.save") {
                        switch mode {
                        case .everyone:
                            selectedIds = nil
                        case .circle, .custom:
                            selectedIds = picked.isEmpty ? nil : Array(picked)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let ids = selectedIds, !ids.isEmpty {
                    picked = Set(ids)
                    if let c = store.circles.first(where: { Set($0.memberIds) == picked }) {
                        mode = .circle
                        pickedCircle = c.id
                    } else {
                        mode = .custom
                    }
                } else {
                    mode = .everyone
                }
            }
        }
    }
}
