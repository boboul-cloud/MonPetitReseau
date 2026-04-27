//
//  SettingsView.swift
//  MonPetitReseau
//

import SwiftUI

struct SettingsView: View {
    @Environment(FamilyStore.self) var store
    @State private var familyName = ""
    @State private var shareURL: URL?
    @State private var showImport = false
    @State private var importText = ""
    @State private var importResult: ImportResult?
    @State private var showHelp = false

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
                    LabeledContent("settings.about.members", value: "\(store.members.count)")
                    LabeledContent("settings.about.messages", value: "\(store.messages.count)")
                    LabeledContent("settings.about.events", value: "\(store.events.count)")
                    LabeledContent("settings.about.photos", value: "\(store.photos.count)")
                }

                Section {
                    Button(role: .destructive) {
                        store.members = []
                        store.messages = []
                        store.events = []
                        store.todos = []
                        store.photos = []
                        store.currentUserId = nil
                        store.familyName = ""
                        store.save()
                    } label: {
                        Label("settings.reset", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("tab.settings")
            .onAppear { familyName = store.familyName }
            .sheet(isPresented: $showHelp) { HelpView() }
            .alert("settings.import.title", isPresented: $showImport) {
                TextField("settings.import.placeholder", text: $importText)
                    .textInputAutocapitalization(.never)
                Button("button.import") {
                    let trimmed = importText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let url = URL(string: trimmed), store.importFromURL(url) {
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
        }
    }
}
