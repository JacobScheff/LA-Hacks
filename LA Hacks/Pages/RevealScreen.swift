//
//  RevealScreen.swift
//  LA Hacks
//
//  Star Hop! celebration screen after a successful generation.
//  Ported from project/galaxy-upload.jsx.
//

import SwiftUI

// MARK: - RevealScreen

struct RevealScreen: View {
    let result: GenerationResult
    let onClose: () -> Void
    let onExplore: () -> Void

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x2A0F5C), Color(hex: 0x0E0626)],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0, endRadius: 700
            )
            .ignoresSafeArea()

            confettiOverlay

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    HStack(alignment: .center, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(
                                    colors: [Color(hex: 0xFFE066, opacity: 0.4), .clear],
                                    center: .center, startRadius: 0, endRadius: 50
                                ))
                            Text(result.emoji)
                                .font(.system(size: 52))
                                .shadow(color: Color(hex: 0xFFE066, opacity: 0.9), radius: 16)
                        }
                        .frame(width: 80, height: 80)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.isNew ? "🌟 NEW CONSTELLATION!" : "✨ NEW STARS ADDED!")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .tracking(1.2)
                                .foregroundColor(Color(hex: 0xFFE066))
                            Text(result.constellationName)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 14)

                    Text(summaryText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 18)

                    VStack(spacing: 8) {
                        ForEach(Array(result.addedTopics.enumerated()), id: \.offset) { _, t in
                            topicRow(label: t.label, emoji: t.emoji)
                        }
                        if !result.neighborTopics.isEmpty {
                            neighborBlock
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)

                    HStack(spacing: 10) {
                        Button(action: onClose) {
                            Text("Later")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.white.opacity(0.05)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)

                        Button(action: onExplore) {
                            Text("🚀 Show me the stars!")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x3A2A00))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: 0xFFE066), Color(hex: 0xFFB300)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: Color(hex: 0xFFB300, opacity: 0.5), radius: 16, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 30)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var summaryText: String {
        if result.isNew {
            let extra = result.neighborTopics.isEmpty ? "" : " Plus \(result.neighborTopics.count) sleepy stars nearby waiting for you!"
            return "Nova found \(result.addedTopics.count) new ideas in your doc and grew them into a brand-new constellation.\(extra)"
        } else {
            return "Nova added \(result.addedTopics.count) new stars to \(result.constellationName). Time to wake them up!"
        }
    }

    private func topicRow(label: String, emoji: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: 0xFFE066, opacity: 0.25))
                )

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("New star · sleepy ⭐")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0xFFE066, opacity: 0.18), Color(hex: 0xFF8AD8, opacity: 0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0xFFE066, opacity: 0.4), lineWidth: 1.5)
        )
    }

    private var neighborBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("💤 Plus \(result.neighborTopics.count) bonus sleepy stars nearby:")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x5EE7FF))
            Text(result.neighborTopics.map { "\($0.emoji) \($0.label)" }.joined(separator: " · "))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: 0x5EE7FF, opacity: 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(hex: 0x5EE7FF, opacity: 0.4),
                              style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }

    private var confettiOverlay: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let colors: [UInt32] = [0xFFE066, 0xFF8AD8, 0x5EE7FF, 0xA78BFA, 0xFF8A4C]
                var seed: UInt64 = 42
                func r() -> Double {
                    seed = (seed &* 9301 &+ 49297) % 233280
                    return Double(seed) / 233280.0
                }
                for i in 0..<30 {
                    let left = r() * 100
                    let delay = r() * 1.4
                    let dur = 2.4 + r() * 1.6
                    let color = colors[Int(r() * Double(colors.count)) % colors.count]
                    let isCircle = r() > 0.5
                    let sz = 8 + r() * 8
                    let phase = ((t + delay).truncatingRemainder(dividingBy: dur)) / dur
                    let x = left / 100 * Double(size.width)
                    let y = phase * Double(size.height + 60) - 30
                    let alpha = phase < 0.15 ? phase / 0.15 : 0.6 + 0.4 * (1 - phase)
                    let rotation = Double(i) + phase * 6.28
                    var p = ctx
                    p.translateBy(x: x, y: y)
                    p.rotate(by: .radians(rotation))
                    let rect = CGRect(x: -sz/2, y: -sz/2, width: sz, height: sz)
                    if isCircle {
                        p.fill(Path(ellipseIn: rect), with: .color(Color(hex: color).opacity(alpha)))
                    } else {
                        p.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(Color(hex: color).opacity(alpha)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
