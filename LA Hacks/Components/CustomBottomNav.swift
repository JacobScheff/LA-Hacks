//
//  CustomBottomNav.swift
//  LA Hacks
//
//  Bottom navigation bar used by LearningGalaxyView (Galaxy / Quests / Nova / Me).
//

import SwiftUI

// MARK: - Custom bottom navigation

struct CustomBottomNav: View {
    @Binding var tab: GalaxyTab
    let safeBottom: CGFloat

    private let items: [(GalaxyTab, String, String)] = [
        (.galaxy,  "Galaxy", "🌌"),
        (.study,   "Quests", "🎯"),
        (.nova,    "Nova",   "🦊"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0.rawValue) { item in
                NavTabButton(
                    tabVal: item.0, label: item.1, emoji: item.2,
                    isActive: tab == item.0
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        tab = item.0
                    }
                }
            }
        }
        .frame(height: 62)
        .background(.ultraThinMaterial)
        .background(Color(hex: 0x1C0C3C, opacity: 0.78))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xFFE066, opacity: 0.25), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 14)
        .padding(.bottom, max(safeBottom, 10) + 14)
    }
}
