//
//  AboutView.swift
//  MonPetitReseau
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private let promoURL = URL(string: "https://boboul-cloud.github.io/MonPetitReseau/promo.html")!
    private let privacyURL = URL(string: "https://boboul-cloud.github.io/MonPetitReseau/privacy.html")!
    private let supportURL = URL(string: "https://boboul-cloud.github.io/MonPetitReseau/support.html")!
    private let repoURL = URL(string: "https://github.com/boboul-cloud/MonPetitReseau")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Hero
                    VStack(spacing: 12) {
                        ZStack {
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            Image(systemName: "person.2.crop.square.stack.fill")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text("MonPetitReseau")
                            .font(.title2.bold())
                        Text("about.tagline")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Text(verbatim: appVersion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12).padding(.vertical, 4)
                            .background(Capsule().fill(.thinMaterial))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Description
                    AboutSection(
                        icon: "sparkles",
                        color: .purple,
                        title: "about.description.title",
                        text: "about.description.body"
                    )

                    // Privacy
                    AboutSection(
                        icon: "lock.shield.fill",
                        color: .green,
                        title: "about.privacy.title",
                        text: "about.privacy.body"
                    )

                    // Links
                    VStack(spacing: 0) {
                        AboutLinkRow(icon: "globe", color: .blue,
                                     title: "about.link.promo", url: promoURL)
                        Divider().padding(.leading, 56)
                        AboutLinkRow(icon: "hand.raised.fill", color: .green,
                                     title: "about.link.privacy", url: privacyURL)
                        Divider().padding(.leading, 56)
                        AboutLinkRow(icon: "lifepreserver", color: .orange,
                                     title: "about.link.support", url: supportURL)
                        Divider().padding(.leading, 56)
                        AboutLinkRow(icon: "chevron.left.forwardslash.chevron.right", color: .gray,
                                     title: "about.link.source", url: repoURL)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Credits
                    VStack(spacing: 6) {
                        Text("about.credits")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Text("about.copyright")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("about.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.close") { dismiss() }
                }
            }
        }
    }
}

private struct AboutSection: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(title).font(.headline)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct AboutLinkRow: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    let url: URL
    @Environment(\.openURL) var openURL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AboutView()
}
