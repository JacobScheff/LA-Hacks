//
//  StickerDetailSheet.swift
//  LA Hacks
//
//  Detail sheet shown when tapping a sticker in the sticker book.
//

import SwiftUI

// MARK: - Detail sheet

struct StickerDetailSheet: View {
    let sticker: StarStickerItem

    @Environment(\.dismiss) private var dismiss

    private var rarity: StickerRarity { sticker.rarity }
    private var locked: Bool { !sticker.unlocked }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Glow blob
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [sticker.shimmer.opacity(0.4), .clear],
                            center: .center, startRadius: 0, endRadius: 100
                        ))
                        .frame(width: 200, height: 200)
                        .offset(y: -50)

                    // Big emoji
                    Text(locked ? "❓" : sticker.emoji)
                        .font(.system(size: 72))
                        .grayscale(locked ? 1 : 0)
                        .opacity(locked ? 0.25 : 1)
                        .shadow(color: locked ? .clear : sticker.shimmer.opacity(0.8), radius: 18)
                        .padding(.top, 18)
                }
                .frame(height: 110)

                // Rarity badge
                Text(rarity.displayLabel.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(rarity.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(rarity.color.opacity(0.18)))
                    .overlay(Capsule().stroke(rarity.color.opacity(0.6), lineWidth: 1.5))
                    .padding(.bottom, 10)

                // Name
                Text(locked ? "Mystery Sticker" : sticker.label)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .tracking(-0.4)
                    .foregroundColor(locked ? .white.opacity(0.4) : .white)
                    .padding(.bottom, 4)

                // Category
                Text("\(sticker.cat.displayLabel) Collection")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .padding(.bottom, 18)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // How to earn card
                VStack(alignment: .leading, spacing: 6) {
                    Text(locked ? "🔒 HOW TO UNLOCK" : "🏅 HOW YOU EARNED IT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(locked ? .white.opacity(0.4) : rarity.color)
                    Text(sticker.how)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .lineSpacing(2)
                        .foregroundColor(locked ? .white.opacity(0.35) : .white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(locked ? Color.white.opacity(0.03) : sticker.shimmer.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(locked ? Color.white.opacity(0.08) : sticker.shimmer.opacity(0.3), lineWidth: 1.5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // XP + date chips
                HStack(spacing: 10) {
                    VStack(spacing: 4) {
                        Text("XP REWARD")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        Text("+\(sticker.xp) XP")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0xFFE066))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: 0xFFE066, opacity: 0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: 0xFFE066, opacity: 0.3), lineWidth: 1.5)
                    )

                    if sticker.unlocked, let date = sticker.earnedDate {
                        VStack(spacing: 4) {
                            Text("EARNED ON")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                            Text(date)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // Close button
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.07))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .foregroundColor(.white)
        .presentationDetents([.large, .fraction(0.9)])
        .presentationDragIndicator(.visible)
        .presentationBackground {
            LinearGradient(
                colors: [Color(hex: 0x281050, opacity: 0.97), Color(hex: 0x12082A, opacity: 0.99)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .presentationCornerRadius(28)
    }
}
