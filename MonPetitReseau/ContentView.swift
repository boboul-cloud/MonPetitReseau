//
//  ContentView.swift
//  MonPetitReseau
//
//  Created by Robert Oulhen on 27/04/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) var app
    @Environment(FamilyStore.self) var store
    @State private var showOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            GroupSelectorBar()
            TabView {
                DirectoryView()
                    .tabItem { Label("tab.directory", systemImage: "person.2.fill") }

                MessagesView()
                    .tabItem { Label("tab.messages", systemImage: "bubble.left.and.bubble.right.fill") }

                PhotosView()
                    .tabItem { Label("tab.photos", systemImage: "photo.on.rectangle.angled") }

                EventsView()
                    .tabItem { Label("tab.events", systemImage: "calendar") }

                TodosView()
                    .tabItem { Label("tab.todos", systemImage: "checklist") }

                SettingsView()
                    .tabItem { Label("tab.settings", systemImage: "gearshape.fill") }
            }
        }
        .onAppear {
            if store.members.isEmpty { showOnboarding = true }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}

// MARK: - Group selector bar (always visible)

struct GroupSelectorBar: View {
    @Environment(AppStore.self) var app
    @Environment(FamilyStore.self) var store
    @State private var showNewGroup = false
    @State private var showJoin = false

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                Section("groups.menu.section") {
                    ForEach(app.groups, id: \.familyId) { g in
                        Button {
                            app.select(g.familyId)
                        } label: {
                            if g.familyId == app.selectedGroupId {
                                Label(displayName(for: g), systemImage: "checkmark")
                            } else {
                                Text(displayName(for: g))
                            }
                        }
                    }
                }
                Divider()
                Button {
                    showNewGroup = true
                } label: { Label("groups.menu.new", systemImage: "plus.circle") }
                Button {
                    showJoin = true
                } label: { Label("groups.menu.join", systemImage: "link") }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.subheadline)
                    Text(displayName(for: store))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color(.secondarySystemBackground),
                            in: Capsule())
                .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
        .sheet(isPresented: $showNewGroup) {
            NewGroupSheet()
        }
        .sheet(isPresented: $showJoin) {
            JoinGroupSheet()
        }
    }

    private func displayName(for s: FamilyStore) -> String {
        s.familyName.isEmpty ? String(localized: "default.familyName") : s.familyName
    }
}

// MARK: - Sheet : create a new group

struct NewGroupSheet: View {
    @Environment(AppStore.self) var app
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var emoji = "🙂"

    private let emojis = ["🙂","😀","😎","🥳","🧔","👨","👩","🧑","👴","👵","👶","🧓","🦸","🦸‍♀️","👮","👨‍🍳","👩‍🎤","🧙","🦊","🐱"]

    var body: some View {
        NavigationStack {
            Form {
                Section("groups.new.section") {
                    TextField("field.familyName", text: $name)
                }
                Section("groups.new.you.section") {
                    TextField("field.firstName", text: $firstName)
                    TextField("field.lastName", text: $lastName)
                    EmojiPicker(selected: $emoji, options: emojis)
                }
            }
            .navigationTitle("groups.new.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.create") {
                        let groupName = name.trimmingCharacters(in: .whitespaces).isEmpty
                            ? String(localized: "default.familyName")
                            : name
                        let g = app.createGroup(named: groupName)
                        let member = FamilyMember(
                            firstName: firstName, lastName: lastName,
                            emoji: emoji, birthDate: nil,
                            phone: "", email: "", city: "",
                            role: String(localized: "role.self"), bio: ""
                        )
                        g.addMember(member)
                        Task { await g.bootstrapCloud() }
                        dismiss()
                    }
                    .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Sheet : join a group via URL

struct JoinGroupSheet: View {
    @Environment(AppStore.self) var app
    @Environment(\.dismiss) var dismiss
    @State private var pasteURL = ""
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("groups.join.help")
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("onboarding.paste.placeholder", text: $pasteURL, axis: .vertical)
                        .lineLimit(2...5)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                if failed {
                    Text("settings.import.fail")
                        .font(.caption).foregroundStyle(.red)
                }
            }
            .navigationTitle("groups.join.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.import") {
                        let trimmed = pasteURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let url = URL(string: trimmed), app.importFromURL(url) {
                            dismiss()
                        } else {
                            failed = true
                        }
                    }
                    .disabled(pasteURL.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Onboarding (first launch)

struct OnboardingView: View {
    @Environment(AppStore.self) var app
    @Environment(FamilyStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var familyName = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var emoji = "🙂"
    @State private var pasteURL = ""
    @State private var showHelp = false

    private let emojis = ["🙂","😀","😎","🥳","🧔","👨","👩","🧑","👴","👵","👶","🧓","🦸","🦸‍♀️","👮","👨‍🍳","👩‍🎤","🧙","🦊","🐱"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("onboarding.welcome")
                        .font(.title2.bold())
                    Text("onboarding.subtitle")
                        .foregroundStyle(.secondary)
                }

                Section("onboarding.section.create") {
                    TextField("field.familyName", text: $familyName)
                    TextField("field.firstName", text: $firstName)
                    TextField("field.lastName", text: $lastName)
                    EmojiPicker(selected: $emoji, options: emojis)
                    Button {
                        let m = FamilyMember(
                            firstName: firstName, lastName: lastName,
                            emoji: emoji, birthDate: nil,
                            phone: "", email: "", city: "",
                            role: String(localized: "role.self"), bio: ""
                        )
                        store.familyName = familyName.isEmpty
                            ? String(localized: "default.familyName")
                            : familyName
                        store.addMember(m)
                        dismiss()
                    } label: {
                        Label("onboarding.create.button", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section("onboarding.section.join") {
                    Text("onboarding.join.help")
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("onboarding.paste.placeholder", text: $pasteURL, axis: .vertical)
                        .lineLimit(2...5)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        if let url = URL(string: pasteURL.trimmingCharacters(in: .whitespacesAndNewlines)),
                           app.importFromURL(url) {
                            dismiss()
                        }
                    } label: {
                        Label("onboarding.join.button", systemImage: "link")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(pasteURL.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section {
                    Button {
                        store.loadSampleIfEmpty()
                        dismiss()
                    } label: {
                        Label("onboarding.sample", systemImage: "sparkles")
                    }
                    Button {
                        showHelp = true
                    } label: {
                        Label("onboarding.help", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("onboarding.title")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showHelp) { HelpView() }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Emoji picker

struct EmojiPicker: View {
    @Binding var selected: String
    let options: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(options, id: \.self) { e in
                    Text(e)
                        .font(.system(size: 28))
                        .padding(6)
                        .background(
                            Circle().fill(selected == e ? Color.accentColor.opacity(0.25) : .clear)
                        )
                        .onTapGesture { selected = e }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    let app = AppStore()
    return ContentView()
        .environment(app)
        .environment(app.active)
}
