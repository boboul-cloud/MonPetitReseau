//
//  AvatarView.swift
//  MonPetitReseau
//

import SwiftUI

struct AvatarView: View {
    let member: FamilyMember?
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            if let m = member, !m.emoji.isEmpty {
                Text(m.emoji)
                    .font(.system(size: size * 0.55))
            } else {
                Text(member?.initials ?? "?")
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 1))
    }

    private var gradientColors: [Color] {
        guard let id = member?.id.uuidString else { return [.gray, .gray] }
        let hash = abs(id.hashValue)
        let palettes: [[Color]] = [
            [.pink, .purple], [.blue, .cyan], [.green, .mint],
            [.orange, .red], [.indigo, .blue], [.teal, .green],
            [.yellow, .orange], [.purple, .indigo]
        ]
        return palettes[hash % palettes.count]
    }
}
