//
//  BottomNav.swift
//  LA Hacks
//
//  Star Hop! BottomNav.
//  Ported from project/galaxy-ui.jsx.
//

import SwiftUI
import UIKit

// MARK: - Bottom nav

struct BottomNav: View {
    let active: GalaxyTab
    let onChange: (GalaxyTab) -> Void
    var bottomSafeArea: CGFloat = 28

    private struct Item: Identifiable {
        let id: GalaxyTab; let label: String; let icon: String
    }
    private let items: [Item] = [
        .init(id: .galaxy,  label: "Galaxy", icon: "🌌"),
        .init(id: .study,   label: "Quests", icon: "🎯"),
        .init(id: .nova,    label: "Nova",   icon: "🦊"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { it in
                let isActive = it.id == active
                Button {
                    selectTab(it.id)
                } label: {
                    VStack(spacing: 3) {
                        Text(it.icon)
                            .font(.system(size: isActive ? 25 : 22))
                            .scaleEffect(isActive ? 1.05 : 1.0)
                        Text(it.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .tracking(0.2)
                            .foregroundColor(isActive ? Color(hex: 0xFFE066) : .white.opacity(0.52))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        Group {
                            if isActive {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(hex: 0xFFE066, opacity: 0.16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color(hex: 0xFFE066, opacity: 0.45), lineWidth: 1)
                                    )
                                    .shadow(color: Color(hex: 0xFFE066, opacity: 0.25), radius: 10, x: 0, y: 3)
                                    .padding(.horizontal, 4)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isActive)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .glassEffect(Glass.regular, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        // Drag-scrub overlay: finger slides across bar to switch tabs live.
        // Uses simultaneousGesture so it never blocks button taps.
        .overlay(
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { v in
                                let idx = max(0, min(items.count - 1,
                                                     Int(v.location.x / (geo.size.width / CGFloat(items.count)))))
                                selectTab(items[idx].id)
                            }
                            .onEnded { v in
                                let idx = max(0, min(items.count - 1,
                                                     Int(v.location.x / (geo.size.width / CGFloat(items.count)))))
                                selectTab(items[idx].id)
                            }
                    )
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, max(bottomSafeArea, 8))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func selectTab(_ tab: GalaxyTab) {
        guard tab != active else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
            onChange(tab)
        }
    }
}
