//
//  PhotosView.swift
//  MonPetitReseau
//

import SwiftUI
import PhotosUI

struct PhotosView: View {
    @Environment(FamilyStore.self) var store
    @State private var pickerItem: PhotosPickerItem?
    @State private var pendingImage: Data?
    @State private var showCaption = false
    @State private var caption = ""
    @State private var preview: FamilyPhoto?

    private let cols = [GridItem(.adaptive(minimum: 110), spacing: 4)]

    var body: some View {
        NavigationStack {
            Group {
                if store.photos.isEmpty {
                    ContentUnavailableView("photos.empty.title",
                                           systemImage: "photo",
                                           description: Text("photos.empty.subtitle"))
                } else {
                    ScrollView {
                        LazyVGrid(columns: cols, spacing: 4) {
                            ForEach(store.photos) { p in
                                if let ui = UIImage(data: p.imageData) {
                                    Image(uiImage: ui)
                                        .resizable().scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipped()
                                        .cornerRadius(6)
                                        .onTapGesture { preview = p }
                                }
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .navigationTitle("tab.photos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let resized = compress(data) {
                        pendingImage = resized
                        caption = ""
                        showCaption = true
                    }
                    pickerItem = nil
                }
            }
            .alert("photos.caption.title", isPresented: $showCaption) {
                TextField("photos.caption.placeholder", text: $caption)
                Button("button.save") {
                    if let data = pendingImage, let uid = store.currentUserId {
                        store.addPhoto(FamilyPhoto(authorId: uid, caption: caption, imageData: data))
                    }
                    pendingImage = nil
                }
                Button("button.cancel", role: .cancel) { pendingImage = nil }
            }
            .sheet(item: $preview) { p in
                PhotoDetailView(photo: p)
            }
        }
    }

    private func compress(_ data: Data) -> Data? {
        guard let ui = UIImage(data: data) else { return nil }
        let maxDim: CGFloat = 1600
        let size = ui.size
        let scale = min(1, maxDim / max(size.width, size.height))
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in ui.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

struct PhotoDetailView: View {
    @Environment(FamilyStore.self) var store
    @Environment(\.dismiss) var dismiss
    let photo: FamilyPhoto

    var body: some View {
        NavigationStack {
            VStack {
                if let ui = UIImage(data: photo.imageData) {
                    Image(uiImage: ui)
                        .resizable().scaledToFit()
                }
                if !photo.caption.isEmpty {
                    Text(photo.caption).font(.body).padding()
                }
                if let by = store.member(photo.authorId) {
                    HStack {
                        AvatarView(member: by, size: 28)
                        Text(by.fullName).font(.caption)
                        Spacer()
                        Text(photo.date, format: .dateTime.day().month().year())
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.close") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        store.deletePhoto(photo.id); dismiss()
                    } label: { Image(systemName: "trash") }
                }
            }
        }
    }
}
