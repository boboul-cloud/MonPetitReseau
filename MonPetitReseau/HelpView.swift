//
//  HelpView.swift
//  MonPetitReseau
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    HelpHero()

                    HelpSection(
                        icon: "sparkles",
                        title: "help.intro.title",
                        text: "help.intro.body"
                    )

                    HelpStep(number: 1, icon: "person.badge.plus",
                             title: "help.step1.title",
                             text: "help.step1.body")

                    HelpStep(number: 2, icon: "person.2.fill",
                             title: "help.step2.title",
                             text: "help.step2.body")

                    HelpStep(number: 3, icon: "square.and.arrow.up",
                             title: "help.step3.title",
                             text: "help.step3.body")

                    HelpStep(number: 4, icon: "tray.and.arrow.down",
                             title: "help.step4.title",
                             text: "help.step4.body")

                    HelpStep(number: 5, icon: "bubble.left.and.bubble.right.fill",
                             title: "help.step5.title",
                             text: "help.step5.body")

                    Divider().padding(.vertical, 8)

                    Text("help.features.title")
                        .font(.title2.bold())

                    HelpFeature(icon: "person.2.fill", color: .blue,
                                title: "help.feat.directory.title",
                                text: "help.feat.directory.body")
                    HelpFeature(icon: "bubble.left.and.bubble.right.fill", color: .purple,
                                title: "help.feat.wall.title",
                                text: "help.feat.wall.body")
                    HelpFeature(icon: "photo.on.rectangle.angled", color: .pink,
                                title: "help.feat.photos.title",
                                text: "help.feat.photos.body")
                    HelpFeature(icon: "calendar", color: .orange,
                                title: "help.feat.events.title",
                                text: "help.feat.events.body")
                    HelpFeature(icon: "checklist", color: .green,
                                title: "help.feat.todos.title",
                                text: "help.feat.todos.body")

                    Divider().padding(.vertical, 8)

                    HelpSection(
                        icon: "lock.shield.fill",
                        title: "help.privacy.title",
                        text: "help.privacy.body"
                    )

                    HelpSection(
                        icon: "questionmark.circle.fill",
                        title: "help.faq.title",
                        text: "help.faq.body"
                    )

                    Text("help.footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("help.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Components

private struct HelpHero: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                Image(systemName: "house.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white)
            }
            Text("help.hero.title")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("help.hero.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct HelpSection: View {
    let icon: String
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.tint)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct HelpStep: View {
    let number: Int
    let icon: String
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 38, height: 38)
                Text("\(number)")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: icon)
                    .font(.subheadline.bold())
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct HelpFeature: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HelpView()
}
