//
//  StudyTab.swift
//  LA Hacks
//
//  Quests tab — daily quest list, live XP tracking, completion state.
//  Quests map to real StarNodes from the lesson bank in LessonView.swift.
//

import SwiftUI

// MARK: - Quest model

private struct DailyQuest: Identifiable {
    let id: String          // matches StarNode.id in the lesson bank
    let title: String
    let sub: String
    let emoji: String
    let xp: Int
    let accent: Color
    let node: StarNode
}

// MARK: - Quests (StudyTab)

struct StudyTab: View {

    /// Called when the user starts a quest — passes the StarNode to launch as a lesson.
    let onBeginQuest: (StarNode) -> Void

    @ObservedObject private var questStore = QuestStore.shared

    // MARK: - Quest definitions

    /// Maps to the lesson bank in LessonView.swift.
    /// StarNode fields that matter: id, label, emoji, x/y/size are irrelevant here.
    private let quests: [DailyQuest] = [
        DailyQuest(
            id: "half",
            title: "Wake the Fractions star",
            sub: "Pizza puzzle · 8 min",
            emoji: "🍕",
            xp: 80,
            accent: Color(hex: 0xFF8AD8),
            node: LearningGalaxyView.makeSyntheticNode(label: "Fractions", emoji: "🍕")
        ),
        DailyQuest(
            id: "area",
            title: "Solve 5 Area puzzles",
            sub: "Mini-game · 6 min",
            emoji: "🟩",
            xp: 60,
            accent: Color(hex: 0x5EE7FF),
            node: LearningGalaxyView.makeSyntheticNode(label: "Area", emoji: "🟩")
        ),
        DailyQuest(
            id: "main",
            title: "Read & spot the Main Idea",
            sub: "Story time · 10 min",
            emoji: "💡",
            xp: 70,
            accent: Color(hex: 0xA78BFA),
            node: LearningGalaxyView.makeSyntheticNode(label: "Main Idea", emoji: "💡")
        ),
        DailyQuest(
            id: "mul",
            title: "Practice times tables",
            sub: "Speed round · 4 min",
            emoji: "✖️",
            xp: 30,
            accent: Color(hex: 0xFFE066),
            node: LearningGalaxyView.makeSyntheticNode(label: "Times Tables", emoji: "✖️")
        ),
    ]

    // MARK: - Derived

    private var completedCount: Int {
        quests.filter { questStore.isCompleted($0.id) }.count
    }

    private var totalPossibleXP: Int {
        quests.map(\.xp).reduce(0, +)
    }

    private var remainingQuests: [DailyQuest] {
        quests.filter { !questStore.isCompleted($0.id) }
    }

    private var completedQuests: [DailyQuest] {
        quests.filter { questStore.isCompleted($0.id) }
    }

    private var allDone: Bool { completedCount == quests.count }

    private var totalMinutes: Int { quests.map { _ in 7 }.reduce(0, +) }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TabHeader(
                    kicker: "✨ TODAY'S MISSION",
                    title: "Quests",
                    emoji: "🎯",
                    subtitle: "\(quests.count - completedCount) remaining · earn up to \(totalPossibleXP) XP!"
                )

                heroCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                metricRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                if !remainingQuests.isEmpty {
                    sectionLabel("🎒 YOUR QUESTS")
                    questList(remainingQuests, done: false)
                }

                if !completedQuests.isEmpty {
                    sectionLabel("✅ COMPLETED")
                        .padding(.top, remainingQuests.isEmpty ? 0 : 18)
                    questList(completedQuests, done: true)
                }
            }
            .padding(.top, 35)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .foregroundColor(.white)
    }

    // MARK: - Hero card

    @ViewBuilder
    private var heroCard: some View {
        if allDone {
            allDoneCard
        } else {
            activeHeroCard
        }
    }

    private var activeHeroCard: some View {
        let progressFraction = Double(completedCount) / Double(quests.count)

        return ZStack(alignment: .topLeading) {
            Text("🚀")
                .font(.system(size: 110))
                .opacity(0.16)
                .offset(x: 215, y: -18)

            VStack(alignment: .leading, spacing: 0) {
                Text("🌟 DAILY ADVENTURE · \(totalMinutes) MIN")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.4)
                    .foregroundColor(Color(hex: 0xFFE066))
                    .padding(.bottom, 4)

                Text("Wake up \(quests.count - completedCount) sleepy star\(quests.count - completedCount == 1 ? "" : "s")!")
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

                // Progress bar
                if completedCount > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(completedCount) of \(quests.count) done")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: 0xFFE066))
                            Spacer()
                            Text("+\(questStore.totalXPToday) XP earned")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: 0xFF8AD8))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.10))
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: geo.size.width * CGFloat(progressFraction))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressFraction)
                                    .shadow(color: Color(hex: 0xFFE066, opacity: 0.5), radius: 4)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.bottom, 14)
                }

                // CTA — start first remaining quest
                if let firstQuest = remainingQuests.first {
                    Button(action: { onBeginQuest(nodeFor(firstQuest)) }) {
                        Text("🚀 Start adventure!")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x1A0B40))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color(hex: 0xFF8A4C, opacity: 0.55), radius: 16, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0xFF8AD8, opacity: 0.22), Color(hex: 0xFFE066, opacity: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xFFE066, opacity: 0.45), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: 0xFF8AD8, opacity: 0.25), radius: 20, x: 0, y: 8)
    }

    private var allDoneCard: some View {
        ZStack(alignment: .topLeading) {
            // Animated confetti-style star burst in corner
            Text("🌟")
                .font(.system(size: 90))
                .opacity(0.20)
                .offset(x: 215, y: -10)

            VStack(alignment: .leading, spacing: 0) {
                Text("🎉 ALL DONE!")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: 0xFFE066))
                    .padding(.bottom, 4)

                Text("You crushed today's quests!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                    .foregroundColor(.white)
                    .padding(.bottom, 6)

                Text("⭐ \(questStore.totalXPToday) XP earned · 🔥 Streak extended · New sticker incoming!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
                    .padding(.bottom, 14)

                // Full progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.10))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width)
                            .shadow(color: Color(hex: 0xFFE066, opacity: 0.55), radius: 6)
                    }
                }
                .frame(height: 8)
                .padding(.bottom, 4)

                Text("\(quests.count) of \(quests.count) completed · Come back tomorrow for more!")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066, opacity: 0.8))
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0xFFE066, opacity: 0.22), Color(hex: 0xFF8A4C, opacity: 0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xFFE066, opacity: 0.6), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: 0xFFE066, opacity: 0.30), radius: 24, x: 0, y: 8)
    }

    // MARK: - Metric row

    private var metricRow: some View {
        HStack(spacing: 8) {
            MiniMetric(
                emoji: "🔥",
                label: "Streak",
                value: "12d",
                sub: nil,
                accent: Color(hex: 0xFF8A4C)
            )
            MiniMetric(
                emoji: "⭐",
                label: "XP today",
                value: "\(questStore.totalXPToday)",
                sub: "of \(totalPossibleXP)",
                accent: Color(hex: 0xFFE066)
            )
            MiniMetric(
                emoji: "✅",
                label: "Done",
                value: "\(completedCount)/\(quests.count)",
                sub: allDone ? "all!" : "quests",
                accent: Color(hex: 0x50E6A0)
            )
        }
    }

    // MARK: - Section helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.65))
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
    }

    private func questList(_ list: [DailyQuest], done: Bool) -> some View {
        VStack(spacing: 10) {
            ForEach(list) { q in questRow(q, done: done) }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Quest row

    private func questRow(_ q: DailyQuest, done: Bool) -> some View {
        Button(action: {
            guard !done else { return }
            onBeginQuest(nodeFor(q))
        }) {
            HStack(spacing: 12) {
                // Emoji badge
                Text(q.emoji)
                    .font(.system(size: 22))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(
                            RadialGradient(
                                colors: [
                                    done ? Color(hex: 0x50E6A0, opacity: 0.28) : q.accent.opacity(0.28),
                                    done ? Color(hex: 0x50E6A0, opacity: 0.06) : q.accent.opacity(0.06),
                                ],
                                center: .center, startRadius: 0, endRadius: 22
                            )
                        )
                    )
                    .overlay(
                        Circle().stroke(
                            done ? Color(hex: 0x50E6A0, opacity: 0.55) : q.accent.opacity(0.55),
                            lineWidth: 1.5
                        )
                    )
                    .opacity(done ? 0.75 : 1.0)

                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text(q.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(done ? .white.opacity(0.5) : .white)
                        .strikethrough(done, color: .white.opacity(0.35))
                    Text(q.sub)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(done ? 0.35 : 0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Trailing badge
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: 0x50E6A0))
                        .shadow(color: Color(hex: 0x50E6A0, opacity: 0.5), radius: 6)
                } else {
                    VStack(spacing: 2) {
                        Text("+\(q.xp)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(q.accent)
                        Text("XP")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(q.accent.opacity(0.7))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(q.accent.opacity(0.12)))
                    .overlay(Capsule().stroke(q.accent.opacity(0.50), lineWidth: 1.5))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.30))
                }
            }
            .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(done ? 0.03 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        done ? Color.white.opacity(0.08) : q.accent.opacity(0.30),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(done)
        .animation(.easeOut(duration: 0.25), value: done)
    }

    // MARK: - Node builder

    /// Returns the real StarNode to pass to LessonView.
    /// Tries to find the node in GalaxyData first; falls back to a synthetic node.
    private func nodeFor(_ quest: DailyQuest) -> StarNode {
        if let found = GalaxyData.nodesById[quest.id]?.node {
            return found
        }
        // Fallback — create a synthetic node whose id matches the lesson bank key.
        return StarNode(
            id: quest.id,
            label: quest.node.label,
            star: nil,
            emoji: quest.emoji,
            x: 0, y: 0,
            initiallyLocked: false,
            size: 5
        )
    }
}
