//
//  StickerCell.swift
//  LA Hacks
//
//  Single sticker tile in the sticker book grid.
//

import SwiftUI

// MARK: - Sticker cell

struct StickerCell: View {
    let sticker: StarStickerItem
    let isNew: Bool
    let onTap: (StarStickerItem) -> Void

    @State private var pressed = false

    private var rarity: StickerRarity { sticker.rarity }
    private var locked: Bool { !sticker.unlocked }

    var body: some View {
        Button(action: { onTap(sticker) }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    ZStack {
                        if !locked {
                            // Glow bloom
                            Text(sticker.emoji)
                                .font(.system(size: 30))
                                .blur(radius: 8)
                                .opacity(0.5)
                        }
                        Text(locked && sticker.cat == .secret ? "❓" : sticker.emoji)
                            .font(.system(size: 30))
                            .grayscale(locked ? 1 : 0)
                            .opacity(locked ? 0.3 : 1)
                            .scaleEffect(pressed && !locked ? 1.12 : 1)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
                    }
                    .frame(height: 38)

                    Text(locked && sticker.cat == .secret ? "???" : sticker.label)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(locked ? .white.opacity(0.25) : .white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 4)

                // Rarity gem
                if !locked {
                    Circle()
                        .fill(rarity.color)
                        .frame(width: 7, height: 7)
                        .shadow(color: rarity.glowColor, radius: 4)
                        .padding(6)
                }

                // NEW badge
                if isNew && !locked {
                    Text("NEW")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: 0xFF8AD8)))
                        .shadow(color: Color(hex: 0xFF8AD8, opacity: 0.8), radius: 4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(5)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(locked
                          ? AnyShapeStyle(Color.white.opacity(0.03))
                          : AnyShapeStyle(LinearGradient(
                              colors: [sticker.shimmer.opacity(0.25), sticker.shimmer.opacity(0.10)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        locked
                        ? AnyShapeStyle(Color.white.opacity(0.12))
                        : AnyShapeStyle(rarity.color.opacity(0.65)),
                        style: StrokeStyle(lineWidth: 1.5, dash: locked ? [4, 3] : [])
                    )
            )
            .shadow(color: locked ? .clear : rarity.glowColor.opacity(0.4), radius: 10, x: 0, y: 4)
            .scaleEffect(pressed && !locked ? 1.05 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in if !locked { pressed = true } }
            .onEnded   { _ in pressed = false }
        )
    }
}
