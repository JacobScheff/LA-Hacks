//
//  StudyTab.swift
//  LA Hacks
//
//  Quests tab — list of active quests, daily streaks, etc.
//  Extracted from GalaxyTabs.swift.
//

import SwiftUI

// MARK: - Quests (StudyTab)

struct StudyTab: View {
    let onBeginQuest: () -> Void

    private struct Quest: Identifiable {
        let id: Int
        let title: String
        let sub: String
        let emoji: String
        let xp: Int
        let accent: Color
    }

    private let quests: [Quest] = [
        Quest(id: 1, title: "Wake the Adding Slices star", sub: "Pizza puzzle · 8 min", emoji: "🍕", xp: 80, accent: Color(hex: 0x5EE7FF)),
        Quest(id: 2, title: "Solve 5 Area puzzles",        sub: "Mini-game · 6 min",  emoji: "🟩", xp: 60, accent: Color(hex: 0xFF8AD8)),
        Quest(id: 3, title: "Read & spot the Main Idea",   sub: "Story time · 10 min", emoji: "💡", xp: 70, accent: Color(hex: 0xFF8AD8)),
        Quest(id: 4, title: "Practice times tables",       sub: "Speed round · 4 min", emoji: "✖️", xp: 30, accent: Color(hex: 0xFFE066)),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TabHeader(
                    kicker: "✨ TODAY'S MISSION",
                    title: "Quests",
                    emoji: "🎯",
                    subtitle: "4 quests · 28 min · earn 240 XP!"
                )

                heroCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                metricRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)

                Text("🎒 YOUR QUESTS")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                VStack(spacing: 10) {
                    ForEach(quests) { q in questRow(q) }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 70)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .foregroundColor(.white)
    }

    private var heroCard: some View {
        ZStack(alignment: .topLeading) {
            // Big rocket emoji decoration
            Text("🚀")
                .font(.system(size: 110))
                .opacity(0.18)
                .offset(x: 220, y: -20)

            VStack(alignment: .leading, spacing: 0) {
                Text("🌟 DAILY ADVENTURE · 28 MIN")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.4)
                    .foregroundColor(Color(hex: 0xFFE066))
                    .padding(.bottom, 4)
                Text("Wake up 3 sleepy stars!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                    .foregroundColor(.white)
                    .padding(.bottom, 6)
                (Text("Finish today's quests to keep your ").foregroundColor(.white.opacity(0.85))
                + Text("🔥 12-day streak").foregroundColor(Color(hex: 0xFF8A4C)).bold()
                + Text(" and unlock a new sticker!").foregroundColor(.white.opacity(0.85)))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .padding(.bottom, 14)

                Button(action: onBeginQuest) {
                    Text("🚀 Start adventure!")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0x1A0B40))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors:[Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color(hex: 0xFF8A4C, opacity: 0.55), radius: 16, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors:[Color(hex: 0xFF8AD8, opacity: 0.22), Color(hex: 0xFFE066, opacity: 0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xFFE066, opacity: 0.45), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: 0xFF8AD8, opacity: 0.25), radius: 20, x: 0, y: 8)
    }

    private var metricRow: some View {
        HStack(spacing: 8) {
            MiniMetric(emoji: "🔥", label: "Streak",     value: "12d", sub: nil,         accent: Color(hex: 0xFF8A4C))
            MiniMetric(emoji: "⭐", label: "New stars",  value: "3",   sub: "this week", accent: Color(hex: 0xFFE066))
            MiniMetric(emoji: "😴", label: "Sleepy",     value: "2",   sub: "say hi!",   accent: Color(hex: 0x5EE7FF))
        }
    }

    private func questRow(_ q: Quest) -> some View {
        HStack(spacing: 12) {
            Text(q.emoji)
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(
                        RadialGradient(
                            colors:[q.accent.opacity(0.33), q.accent.opacity(0.07)],
                            center: .center, startRadius: 0, endRadius: 22
                        )
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(q.accent.opacity(0.55), lineWidth: 1.5)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(q.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(q.sub)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("+\(q.xp) XP")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(q.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(q.accent.opacity(0.13)))
                .overlay(Capsule().stroke(q.accent.opacity(0.55), lineWidth: 1.5))
        }
        .sCard(stroke: q.accent.opacity(0.33), padding: EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
    }
    private func chipButton(label: String, primary: Bool) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(primary ? Color(hex: 0x1A0B40) : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(
                    primary
                    ? AnyShapeStyle(LinearGradient(
                        colors:[Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color.white.opacity(0.08))
                )
            )
            .overlay(
                Capsule().stroke(primary ? Color.clear : Color.white.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: primary ? Color(hex: 0x5EE7FF, opacity: 0.4) : .clear, radius: 8, x: 0, y: 3)
    }
}
