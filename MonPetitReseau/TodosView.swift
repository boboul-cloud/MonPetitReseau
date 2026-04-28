//
//  TodosView.swift
//  MonPetitReseau
//

import SwiftUI

struct TodosView: View {
    @Environment(FamilyStore.self) var store
    @State private var showAdd = false

    var pending: [FamilyTodo] { store.visibleTodos().filter { !$0.isDone }.sorted { $0.date > $1.date } }
    var done: [FamilyTodo] { store.visibleTodos().filter { $0.isDone }.sorted { $0.date > $1.date } }

    var body: some View {
        NavigationStack {
            List {
                Section("todos.section.pending") {
                    if pending.isEmpty {
                        Text("todos.empty").foregroundStyle(.secondary)
                    } else {
                        ForEach(pending) { t in row(t) }
                            .onDelete { idx in
                                guard store.canEditByCurrentUser else { return }
                                for i in idx { store.deleteTodo(pending[i].id) }
                            }
                    }
                }
                if !done.isEmpty {
                    Section("todos.section.done") {
                        ForEach(done) { t in row(t) }
                            .onDelete { idx in
                                guard store.canEditByCurrentUser else { return }
                                for i in idx { store.deleteTodo(done[i].id) }
                            }
                    }
                }
            }
            .navigationTitle("tab.todos")
            .toolbar {
                if store.canEditByCurrentUser {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showAdd = true } label: { Image(systemName: "plus") }
                    }
                }
            }
            .readOnlyBanner(if: !store.canEditByCurrentUser)
            .sheet(isPresented: $showAdd) { TodoAddView() }
        }
    }

    @ViewBuilder
    private func row(_ t: FamilyTodo) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button { store.toggleTodo(t.id) } label: {
                Image(systemName: t.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(t.isDone ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(!store.canEditByCurrentUser)

            VStack(alignment: .leading, spacing: 2) {
                Text(t.title)
                    .strikethrough(t.isDone)
                    .foregroundStyle(t.isDone ? .secondary : .primary)
                HStack(spacing: 6) {
                    if let by = store.member(t.createdBy) {
                        Text(by.fullName).font(.caption2).foregroundStyle(.secondary)
                    }
                    if let to = store.member(t.assignedTo) {
                        Text("→ \(to.fullName)").font(.caption2).foregroundStyle(.tertiary)
                    }
                    AudienceBadge(audienceIds: t.audienceIds)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct TodoAddView: View {
    @Environment(FamilyStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var assignedTo: UUID?
    @State private var audienceIds: [UUID]? = nil

    var body: some View {
        NavigationStack {
            Form {
                TextField("field.title", text: $title)
                OptionalMemberPicker(label: "field.assignedTo", selection: $assignedTo)
                Section {
                    AudiencePicker(selectedIds: $audienceIds)
                }
            }
            .navigationTitle("add.todo.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.save") {
                        guard let uid = store.currentUserId else { dismiss(); return }
                        store.addTodo(FamilyTodo(
                            title: title, createdBy: uid,
                            assignedTo: assignedTo,
                            audienceIds: audienceIds
                        ))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
