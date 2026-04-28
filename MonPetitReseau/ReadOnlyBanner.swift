//
//  ReadOnlyBanner.swift
//  MonPetitReseau
//
//  Small banner shown atop a tab when the current user is not allowed to
//  edit content in the active group. The permission system is honor-based
//  (we do not enforce it cryptographically — see FamilyStore.canEdit).
//

import SwiftUI

struct ReadOnlyBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
            Text("banner.readonly")
                .font(.footnote)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.18))
        .foregroundStyle(.orange)
    }
}

extension View {
    /// Prepends a "read-only" banner above the view when `showBanner` is true.
    @ViewBuilder
    func readOnlyBanner(if showBanner: Bool) -> some View {
        if showBanner {
            VStack(spacing: 0) {
                ReadOnlyBanner()
                self
            }
        } else {
            self
        }
    }
}
