//
//  MessagesView.swift
//  MonPetitReseau
//

import SwiftUI

struct MessagesView: View {
    @Environment(FamilyStore.self) var store
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.messages) { msg in
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
                    .onChange(of: store.messages.count) { _, _ in
                        if let last = store.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onAppear {
                        if let last = store.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                Divider()

                HStack(alignment: .bottom, spacing: 8) {
                    TextField("messages.placeholder", text: $draft, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(10)
                        .background(Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 18))
                        .focused($focused)
                    Button {
                        store.postMessage(draft)
                        draft = ""
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
                .padding()
            }
            .navigationTitle("tab.messages")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if store.messages.isEmpty {
                    ContentUnavailableView("messages.empty.title",
                                           systemImage: "bubble.left",
                                           description: Text("messages.empty.subtitle"))
                }
            }
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
                Text(message.date, format: .relative(presentation: .named))
                    .font(.caption2).foregroundStyle(.tertiary)
            }

            if isMe { AvatarView(member: author, size: 30) }
            if !isMe { Spacer(minLength: 40) }
        }
    }
}
