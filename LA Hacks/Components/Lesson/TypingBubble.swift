//
//  TypingBubble.swift
//  LA Hacks
//
//  Animated "Nova is typing…" bouncing-dots bubble.
//

import SwiftUI

// MARK: - Typing indicator

struct TypingBubble: View {
    let pal: StarPalette

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            BouncingDots()
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: 0x201048, opacity: 0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        }
    }
}

private struct BouncingDots: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate * 4.5
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 6, height: 6)
                        .offset(y: CGFloat(sin(t + Double(i) * 0.7) * -3.5))
                }
            }
        }
    }
}
