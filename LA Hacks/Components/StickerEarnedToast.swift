//
//  StickerEarnedToast.swift
//  LA Hacks
//
//  Full-screen celebration overlay shown when a new sticker is unlocked.
//

import SwiftUI

struct StickerEarnedToast: View {
    let sticker: StarStickerItem
    let onDismiss: () -> Void

    @State private var visible = false
    @State private var emojiScale: CGFloat = 0.2
    @State private var emojiRotation: Double = -15
    @State private var sparkleOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 22) {
                // Glow + emoji
                ZStack {
                    Circle()
                        .fill(sticker.rarity.color.opacity(0.22))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .opacity(sparkleOpacity)

                    Text(sticker.emoji)
                        .font(.system(size: 80))
                        .scaleEffect(emojiScale)
                        .rotationEffect(.degrees(emojiRotation))
                        .shadow(color: sticker.rarity.glowColor, radius: 24)
                }
                .frame(height: 120)

                // Labels
                VStack(spacing: 10) {
                    Text("✨ NEW STICKER UNLOCKED!")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(sticker.rarity.color)
                        .shadow(color: sticker.rarity.glowColor, radius: 6)

                    Text(sticker.label)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .tracking(-0.3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // Rarity pill
                    Text(sticker.rarity.displayLabel.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(sticker.rarity.color)
                        .padding(.horizontal, 14).padding(.vertical, 5)
                        .background(Capsule().fill(sticker.rarity.color.opacity(0.18)))
                        .overlay(Capsule().stroke(sticker.rarity.color.opacity(0.5), lineWidth: 1))

                    // How-to (hide for secret stickers)
                    if sticker.cat != .secret {
                        Text(sticker.how)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 8)
                    }

                    // XP badge
                    Text("+\(sticker.xp) XP")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFE066))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(Color(hex: 0xFFE066, opacity: 0.16)))
                        .overlay(Capsule().stroke(Color(hex: 0xFFE066, opacity: 0.4), lineWidth: 1))
                        .shadow(color: Color(hex: 0xFFE066, opacity: 0.4), radius: 8)
                }

                // CTA button
                Button(action: dismiss) {
                    Text("Awesome! 🎉")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0x08041A))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [sticker.rarity.color, sticker.shimmer],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: sticker.rarity.glowColor.opacity(0.6), radius: 16, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: 0x120930), Color(hex: 0x08041A)],
                        startPoint: .top, endPoint: .bottom
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(sticker.rarity.color.opacity(0.45), lineWidth: 1.5)
            )
            .shadow(color: sticker.rarity.glowColor.opacity(0.35), radius: 40)
            .padding(.horizontal, 28)
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 60)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                visible = true
                emojiScale = 1.0
                emojiRotation = 0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                sparkleOpacity = 1
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.22)) {
            visible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { onDismiss() }
    }
}
