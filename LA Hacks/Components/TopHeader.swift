//
//  TopHeader.swift
//  LA Hacks
//
//  Star Hop! TopHeader — live streak, XP, level, name, and avatar
//  all driven by UserSettings.
//

import SwiftUI
import UIKit

// MARK: - Top header (Hi [name], XP, streak, filters)

struct TopHeader: View {
    let stats: (mastered: Int, gaps: Int, learning: Int)
    let filter: MasteryStage?
    let onFilter: (MasteryStage?) -> Void
    let onProfile: () -> Void
    var topInset: CGFloat = 44

    @Environment(UserSettings.self) var userSettings

    // First name only (e.g. "Maya the Brave" → "Maya")
    private var firstName: String {
        userSettings.explorerName.components(separatedBy: " ").first ?? userSettings.explorerName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hi, \(firstName)! 👋")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .tracking(-0.4)
                        .foregroundColor(.white)
                    HStack(spacing: 0) {
                        Text("\(stats.mastered) stars shining")
                            .foregroundColor(Color(hex: 0xFFE066))
                        Text(" · \(stats.gaps) sleepy · \(stats.learning) twinkling")
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 8) {
                    streakChip
                    avatar
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, topInset + 60)

            xpBar
                .padding(.horizontal, 14)
                .padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    chip(id: nil,        label: "🌌 All",        dot: nil)
                    chip(id: .sleepy,    label: "😴 Sleepy",     dot: Color(hex: 0x5EE7FF))
                    chip(id: .twinkling, label: "✨ Twinkling",  dot: Color(hex: 0xFF8AD8))
                    chip(id: .shining,   label: "⭐ Shining",    dot: Color(hex: 0xFFE066))
                }
                .padding(.horizontal, 14)
            }
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var streakChip: some View {
        Text("🔥 \(userSettings.currentStreak)")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xFF8A4C), Color(hex: 0xFF4FB6)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 2)
            )
            .shadow(color: Color(hex: 0xFF4FB6, opacity: 0.5), radius: 8, x: 0, y: 4)
    }

    private var avatar: some View {
        Button(action: onProfile) {
            Text(userSettings.avatar)
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: 0xFFE066), lineWidth: 2)
                )
                .shadow(color: Color(hex: 0x5EE7FF, opacity: 0.5), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var xpBar: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: 0xFFE066), Color(hex: 0xFFB300)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                Text("\(userSettings.level)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x3A2A00))
            }
            .frame(width: 28, height: 28)
            .shadow(color: Color(hex: 0xFFE066, opacity: 0.6), radius: 6)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("\(userSettings.levelTitle) · Lvl \(userSettings.level)")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(userSettings.totalXP) / \(userSettings.xpForNextLevel) XP")
                        .foregroundColor(Color(hex: 0xFFE066))
                }
                .font(.system(size: 10, weight: .semibold, design: .rounded))

                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(hex: 0xFFE066), Color(hex: 0xFFB300)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: g.size.width * CGFloat(userSettings.xpProgress))
                            .shadow(color: Color(hex: 0xFFE066, opacity: 0.8), radius: 4)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: 0x140A32, opacity: 0.55))
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: 0xFFE066, opacity: 0.35), lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private func chip(id: MasteryStage?, label: String, dot: Color?) -> some View {
        let active = filter == id
        Button(action: { onFilter(id) }) {
            HStack(spacing: 6) {
                if let dot {
                    Circle()
                        .fill(dot)
                        .frame(width: 7, height: 7)
                        .shadow(color: dot, radius: 3)
                }
                Text(LocalizedStringKey(label))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(active ? Color(hex: 0xFFE066) : .white.opacity(0.85))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(active ? Color(hex: 0xFFE066, opacity: 0.18) : Color(hex: 0x140A32, opacity: 0.55))
            )
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule().stroke(
                    active ? Color(hex: 0xFFE066) : Color.white.opacity(0.18),
                    lineWidth: active ? 2 : 1.5
                )
            )
        }
        .buttonStyle(.plain)
    }
}
