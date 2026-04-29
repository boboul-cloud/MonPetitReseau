//
//  MessagesView.swift
//  MonPetitReseau
//

import SwiftUI

struct MessagesView: View {
    @Environment(FamilyStore.self) var store
    @State private var draft = ""
    @State private var draftAudience: [UUID]? = nil
    @State private var showAudience = false
    @FocusState private var focused: Bool
    @State private var pollTask: Task<Void, Never>?

    var visible: [FamilyMessage] { store.visibleMessages() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(visible) { msg in
                                MessageBubble(message: msg,
                                              isMe: msg.authorId == store.currentUserId,
                                              author: store.member(msg.authorId))
                                .id(msg.id)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        store.deleteMessage(msg.id)
                                    } label: { Label("button.delete", systemImage: "trash") }
                                }
                            }
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable { await store.syncAll() }
                    .onChange(of: visible.count) { _, _ in
                        if let last = visible.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onAppear {
                        if let last = visible.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                Divider()

                VStack(spacing: 6) {
                    if draftAudience != nil {
                        HStack {
                            AudienceBadge(audienceIds: draftAudience)
                            Spacer()
                            Button("audience.clear") { draftAudience = nil }
                                .font(.caption2)
                        }
                        .padding(.horizontal)
                    }
                    HStack(alignment: .bottom, spacing: 8) {
                        Button {
                            showAudience = true
                        } label: {
                            Image(systemName: draftAudience == nil ? "eye" : "lock.fill")
                                .font(.title3)
                                .padding(10)
                                .background(Circle().fill(Color(.secondarySystemBackground)))
                                .foregroundStyle(draftAudience == nil ? .secondary : Color.accentColor)
                        }
                        TextField("messages.placeholder", text: $draft, axis: .vertical)
                            .lineLimit(1...5)
                            .padding(10)
                            .background(Color(.secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 18))
                            .focused($focused)
                        Button {
                            store.postMessage(draft, audienceIds: draftAudience)
                            draft = ""
                            focused = false
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .padding(10)
                                .background(Circle().fill(Color.accentColor))
                                .foregroundStyle(.white)
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  || store.currentUserId == nil)
                    }
                    .padding(.horizontal).padding(.bottom)
                }
                .padding(.top, 6)
            }
            .navigationTitle("tab.messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    cloudStatusIcon
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("button.done") { focused = false }
                }
            }
            .sheet(isPresented: $showAudience) {
                AudienceChooserSheet(selectedIds: $draftAudience)
            }
            .task {
                await store.syncAll()
                pollTask?.cancel()
                pollTask = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(8))
                        if Task.isCancelled { break }
                        await store.syncAll()
                    }
                }
            }
            .onDisappear { pollTask?.cancel() }
            .overlay {
                if visible.isEmpty {
                    ContentUnavailableView("messages.empty.title",
                                           systemImage: "bubble.left",
                                           description: Text("messages.empty.subtitle"))
                }
            }
        }
    }

    @ViewBuilder
    private var cloudStatusIcon: some View {
        switch store.cloudStatus {
        case .idle:
            Image(systemName: "icloud.fill")
                .foregroundStyle(.secondary)
                .accessibilityLabel("cloud.status.synced")
        case .syncing:
            ProgressView().controlSize(.small)
        case .unavailable(let reason):
            Image(systemName: "icloud.slash")
                .foregroundStyle(.orange)
                .help(reason)
                .accessibilityLabel(Text(reason))
        }
    }
}

struct MessageBubble: View {
    let message: FamilyMessage
    let isMe: Bool
    let author: FamilyMember?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 40) }
            if !isMe { AvatarView(member: author, size: 30) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                if !isMe {
                    Text(author?.fullName ?? "?")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Text(message.text)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(
                        isMe ? Color.accentColor : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .foregroundStyle(isMe ? .white : .primary)
                HStack(spacing: 6) {
                    Text(message.date, format: .relative(presentation: .named))
                        .font(.caption2).foregroundStyle(.tertiary)
                    AudienceBadge(audienceIds: message.audienceIds)
                }
            }

            if isMe { AvatarView(member: author, size: 30) }
            if !isMe { Spacer(minLength: 40) }
        }
    }
}
