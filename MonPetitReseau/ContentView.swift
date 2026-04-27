//
//  ContentView.swift
//  MonPetitReseau
//
//  Created by Robert Oulhen on 27/04/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(FamilyStore.self) var store
    @State private var showOnboarding = false

    var body: some View {
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
        .onAppear {
            if store.members.isEmpty { showOnboarding = true }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
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
                           store.importFromURL(url) {
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
    ContentView().environment(FamilyStore())
}
