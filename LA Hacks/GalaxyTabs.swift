//
//  GalaxyTabs.swift
//  LA Hacks
//
//  Star Hop! Quests, Trips, Me tabs. Ported from project/tabs.jsx.
//

import SwiftUI

// MARK: - Shared

private struct TabHeader: View {
    let kicker: String
    let title: String
    let emoji: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(kicker)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.5)
                .foregroundColor(Color(hex: 0xFFE066))
                .shadow(color: Color(hex: 0xFFE066, opacity: 0.5), radius: 6)
            Text("\(emoji) \(title)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .foregroundColor(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }
}

private extension View {
    func sCard(stroke: Color = Color.white.opacity(0.12), padding: EdgeInsets = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(stroke, lineWidth: 1.5)
            )
    }
}

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
                                colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
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
                    colors: [Color(hex: 0xFF8AD8, opacity: 0.22), Color(hex: 0xFFE066, opacity: 0.18)],
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
                            colors: [q.accent.opacity(0.33), q.accent.opacity(0.07)],
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
                        colors: [Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)],
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

// MARK: - MiniMetric

private struct MiniMetric: View {
    let emoji: String
    let label: String
    let value: String
    let sub: String?
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Text(emoji).font(.system(size: 14))
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(accent)
            if let sub {
                Text(sub)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sCard(stroke: accent.opacity(0.33), padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
    }
}

// MARK: - Trips (PathsTab)

struct PathsTab: View {

    private struct Trip: Identifiable {
        let id: String
        let title: String
        let kicker: String
        let desc: String
        let stars: [String]
        let progress: Double
        let minutes: Int
        let hue: Color
        let reward: String
    }

    private let trips: [Trip] = [
        Trip(
            id: "pizza",
            title: "Pizza Master Trip",
            kicker: "🍕 SLICE & SHARE",
            desc: "Slice, share, and add fractions like a pizza wizard!",
            stars: ["Halves","Read","Equal","Compare","Add","Mixed","Simplify"],
            progress: 0.4, minutes: 80,
            hue: Color(hex: 0xFF8AD8),
            reward: "🍕 Pizza Chef sticker"
        ),
        Trip(
            id: "space",
            title: "Space Explorer",
            kicker: "🪐 BLAST OFF",
            desc: "Visit every planet and become Earth's tiniest astronaut!",
            stars: ["Sun","Seasons","Weather","Water","Planets"],
            progress: 0.55, minutes: 70,
            hue: Color(hex: 0xA78BFA),
            reward: "🚀 Space Cadet badge"
        ),
        Trip(
            id: "story",
            title: "Story Wizard",
            kicker: "✨ TELL TALES",
            desc: "Read, write, and craft your very own story.",
            stars: ["Smooth Read","Main Idea","Details","Theme","Story"],
            progress: 0.42, minutes: 90,
            hue: Color(hex: 0xFFE066),
            reward: "📖 Wizard hat"
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TabHeader(
                    kicker: "🗺️ ADVENTURES",
                    title: "Trips",
                    emoji: "🚀",
                    subtitle: "Big journeys that unlock big rewards!"
                )

                VStack(spacing: 14) {
                    ForEach(trips) { p in tripCard(p) }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 70)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
    }

    private func tripCard(_ p: Trip) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(p.kicker)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(p.hue)
                    .padding(.bottom, 4)
                Text(p.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                    .foregroundColor(.white)
                    .padding(.bottom, 6)
                Text(p.desc)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 14)

                PathStrip(stars: p.stars, progress: p.progress, hue: p.hue)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [p.hue.opacity(0.13), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .overlay(
                Rectangle()
                    .fill(p.hue.opacity(0.2))
                    .frame(height: 1),
                alignment: .bottom
            )

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int((p.progress * 100).rounded()))% lit · \(p.minutes) min")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(p.hue)
                    Text("🎁 Reward: \(p.reward)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Button(action: {}) {
                    Text("Go! →")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0x1A0B40))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [p.hue, p.hue.opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: p.hue.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(p.hue.opacity(0.33), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct PathStrip: View {
    let stars: [String]
    let progress: Double
    let hue: Color

    var body: some View {
        let litCount = Int((Double(stars.count) * progress).rounded())
        ZStack(alignment: .top) {
            // line behind
            GeometryReader { g in
                let lit = g.size.width * CGFloat(progress)
                HStack(spacing: 0) {
                    Rectangle().fill(hue).frame(width: lit, height: 2)
                        .shadow(color: hue, radius: 4)
                    Rectangle().fill(Color.white.opacity(0.15)).frame(height: 2)
                }
            }
            .frame(height: 2)
            .padding(.top, 13)
            .padding(.horizontal, 6)

            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(stars.enumerated()), id: \.offset) { idx, s in
                    let lit = idx < litCount
                    VStack(spacing: 6) {
                        Circle()
                            .fill(lit ? hue : Color.white.opacity(0.18))
                            .frame(width: lit ? 14 : 10, height: lit ? 14 : 10)
                            .overlay(
                                Circle().stroke(
                                    lit ? Color.white : Color.white.opacity(0.3),
                                    lineWidth: lit ? 2 : 1.5
                                )
                            )
                            .shadow(color: lit ? hue : .clear, radius: lit ? 6 : 0)
                            .padding(.top, lit ? 7 : 9)
                        Text(s)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(lit ? .white : .white.opacity(0.5))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 44)
    }
}

// MARK: - Nova AI (NovaAITab)

struct NovaAITab: View {
    @State private var prompt: String = ""
    @State private var outputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var downloadProgress: Float = 0.0
    @FocusState private var isPromptFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TabHeader(
                    kicker: "🤖 POWERED BY GEMMA",
                    title: "Ask Nova",
                    emoji: "🦊",
                    subtitle: "Chat with your AI tutor!"
                )

                promptCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                if isProcessing && downloadProgress > 0 && downloadProgress < 1.0 {
                    downloadCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                if !outputText.isEmpty {
                    responseCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .padding(.top, 70)
            .padding(.bottom, 30)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { isPromptFocused = false }
        .scrollIndicators(.hidden)
        .foregroundColor(.white)
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💬 YOUR QUESTION")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))

            TextEditor(text: $prompt)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: 0xFFE066, opacity: 0.35), lineWidth: 2)
                )
                .overlay(alignment: .topLeading) {
                    if prompt.isEmpty {
                        Text("Ask Nova anything… explain a topic, help with homework…")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(20)
                            .allowsHitTesting(false)
                    }
                }
                .focused($isPromptFocused)

            Button(action: runLLM) {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .tint(Color(hex: 0x1A0B40))
                            .scaleEffect(0.85)
                        Text("Nova is thinking…")
                    } else {
                        Text("🚀 Ask Nova!")
                    }
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x1A0B40))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: isProcessing
                            ? [Color(hex: 0xFFE066, opacity: 0.55), Color(hex: 0xFFB300, opacity: 0.55)]
                            : [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: 0xFF8A4C, opacity: isProcessing ? 0.2 : 0.5), radius: 16, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing || prompt.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .sCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
    }

    private var downloadCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("⬇️").font(.system(size: 14))
                Text("Downloading Nova's brain…")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%.0f%%", downloadProgress * 100))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066))
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: g.size.width * CGFloat(downloadProgress))
                        .shadow(color: Color(hex: 0xFFE066, opacity: 0.6), radius: 4)
                }
            }
            .frame(height: 8)
            Text("This only happens once — Nova will be much faster next time!")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .sCard(stroke: Color(hex: 0xFFE066, opacity: 0.3), padding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
    }

    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("🦊").font(.system(size: 20))
                Text("NOVA SAYS")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: 0x5EE7FF))
                Spacer()
                if isProcessing {
                    Text("streaming…")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFE066, opacity: 0.7))
                }
            }
            Text(outputText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sCard(
            stroke: Color(hex: 0x5EE7FF, opacity: 0.35),
            padding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        )
    }

    private func runLLM() {
        guard !isProcessing else { return }
        let userPrompt = prompt
        isProcessing = true
        outputText = ""
        downloadProgress = 0.0

        runModel(
            prompt: userPrompt,
            onDownload: { progress in
                DispatchQueue.main.async { self.downloadProgress = progress }
            },
            onStream: { currentText in
                DispatchQueue.main.async { self.outputText = currentText }
            },
            onComplete: { error in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    if let error = error {
                        self.outputText = "Oops! Nova had a problem: \(error.localizedDescription)"
                    }
                }
            }
        )
    }
}

// MARK: - Me (YouTab)

struct YouTab: View {
    @State private var showSettings = false

    /// Deterministic 12 weeks × 7 days heatmap
    private static let days: [Double] = {
        var seed: UInt64 = 17
        var out: [Double] = []
        for _ in 0..<84 {
            seed = (seed &* 9301 &+ 49297) % 233280
            out.append(Double(seed) / 233280.0)
        }
        return out
    }()

    private struct Sticker: Identifiable {
        let id = UUID()
        let emoji: String
        let label: String
        let unlocked: Bool
    }
    private let stickers: [Sticker] = [
        Sticker(emoji: "🍕", label: "Pizza Pro",    unlocked: true),
        Sticker(emoji: "🚀", label: "Rocket Kid",   unlocked: true),
        Sticker(emoji: "🎯", label: "Sharp Shooter",unlocked: true),
        Sticker(emoji: "🔥", label: "7-Day Streak", unlocked: true),
        Sticker(emoji: "🦋", label: "Symmetry Star",unlocked: true),
        Sticker(emoji: "🦊", label: "Quick Fox",    unlocked: true),
        Sticker(emoji: "🪐", label: "Space Cadet",  unlocked: false),
        Sticker(emoji: "🧙", label: "Word Wizard",  unlocked: false),
        Sticker(emoji: "🧊", label: "Cool Cube",    unlocked: false),
        Sticker(emoji: "🦖", label: "History Hero", unlocked: false),
        Sticker(emoji: "🏆", label: "Champion",     unlocked: false),
        Sticker(emoji: "⭐", label: "All Stars",    unlocked: false),
    ]

    private struct Metric: Identifiable {
        let id = UUID()
        let emoji: String
        let label: String
        let value: String
        let total: Int?
        let valueAsInt: Int?
        let sub: String?
        let hue: Color
    }
    private var earnedCount: Int { stickers.filter { $0.unlocked }.count }
    private var metrics: [Metric] {
        [
            Metric(emoji: "⭐", label: "Stars Lit",  value: "23",      total: 47, valueAsInt: 23, sub: nil,         hue: Color(hex: 0xFFE066)),
            Metric(emoji: "🌌", label: "Worlds",     value: "2",       total: 9,  valueAsInt: 2,  sub: nil,         hue: Color(hex: 0xA78BFA)),
            Metric(emoji: "🔥", label: "Streak",     value: "12d",     total: nil,valueAsInt: nil,sub: "best 18d",  hue: Color(hex: 0xFF8A4C)),
            Metric(emoji: "🏆", label: "Stickers",   value: "\(earnedCount)/\(stickers.count)", total: nil, valueAsInt: nil, sub: nil, hue: Color(hex: 0xFF8AD8)),
        ]
    }

    private struct Recent: Identifiable {
        let id = UUID()
        let emoji: String
        let title: String
        let sub: String
        let hue: Color
    }
    private let recent: [Recent] = [
        Recent(emoji: "⭐", title: "Lit up Inverse Operations",     sub: "2 hours ago · +60 XP",   hue: Color(hex: 0xFFE066)),
        Recent(emoji: "😴", title: "Found a sleepy star: Volume",   sub: "Yesterday",              hue: Color(hex: 0x5EE7FF)),
        Recent(emoji: "🎮", title: "Played Times Tables Speed",     sub: "2 days ago · 24 min",    hue: Color(hex: 0xFF8AD8)),
        Recent(emoji: "🏅", title: "Unlocked Symmetry Star sticker",sub: "3 days ago",             hue: Color(hex: 0xA78BFA)),
    ]

    var body: some View {
        if showSettings {
            SettingsTab(onBack: { showSettings = false })
        } else {
            profileContent
        }
    }

    private var profileContent: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    metricsGrid
                    stickerBook
                    heatmapCard
                    recentBlock
                }
                .padding(.top, 60)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .foregroundColor(.white)

            // Gear button (top-right, floats above scroll)
            Button(action: { showSettings = true }) {
                Text("⚙️")
                    .font(.system(size: 17))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 62)
            .padding(.trailing, 16)
        }
    }

    private var hero: some View {
        HStack(spacing: 16) {
            Text("🦊")
                .font(.system(size: 40))
                .frame(width: 80, height: 80)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(hex: 0xFFE066), lineWidth: 3)
                )
                .shadow(color: Color(hex: 0x5EE7FF, opacity: 0.5), radius: 16, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("⭐ STAR CAPTAIN · LVL 4")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: 0xFFE066))
                Text("Maya the Brave")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                    .foregroundColor(.white)
                Text("Exploring since January · 4th grade")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 3)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(metrics) { m in metricCard(m) }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
    }

    private func metricCard(_ m: Metric) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(m.emoji).font(.system(size: 16))
                Text(m.label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 6)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(m.value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(m.hue)
                if let total = m.total {
                    Text("/ \(total)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            if let sub = m.sub {
                Text(sub)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 4)
            }
            if let total = m.total, let v = m.valueAsInt {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08))
                        Capsule().fill(m.hue)
                            .frame(width: g.size.width * CGFloat(v) / CGFloat(total))
                            .shadow(color: m.hue, radius: 3)
                    }
                }
                .frame(height: 5)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sCard(stroke: m.hue.opacity(0.33), padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14))
    }

    private var stickerBook: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🎟️ Sticker Book")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(earnedCount)/\(stickers.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: 0xFFE066, opacity: 0.14)))
                    .overlay(Capsule().stroke(Color(hex: 0xFFE066, opacity: 0.5), lineWidth: 1))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(stickers) { s in stickerCell(s) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
    }

    private func stickerColors(_ s: Sticker) -> (Color, Color) {
        switch s.emoji {
        case "🍕": return (Color(hex: 0xFF8A4C), Color(hex: 0xFFE066))
        case "🚀": return (Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA))
        case "🎯": return (Color(hex: 0xFF4FB6), Color(hex: 0xA855F7))
        case "🔥": return (Color(hex: 0xFF8A4C), Color(hex: 0xFF4FB6))
        case "🦋": return (Color(hex: 0xFF8AD8), Color(hex: 0x5EE7FF))
        case "🦊": return (Color(hex: 0xFFE066), Color(hex: 0xFF8A4C))
        default:   return (Color(hex: 0xA78BFA), Color(hex: 0x5EE7FF))
        }
    }

    private func stickerCell(_ s: Sticker) -> some View {
        let (c1, c2) = stickerColors(s)
        return VStack(spacing: 7) {
            ZStack {
                if s.unlocked {
                    // Glow bloom
                    Text(s.emoji)
                        .font(.system(size: 34))
                        .blur(radius: 10)
                        .opacity(0.55)
                    Text(s.emoji)
                        .font(.system(size: 34))
                } else {
                    Text(s.emoji)
                        .font(.system(size: 34))
                        .blur(radius: 3)
                        .grayscale(1)
                        .opacity(0.35)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .frame(height: 42)

            Text(s.unlocked ? s.label : "???")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(s.unlocked ? .white : .white.opacity(0.35))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(s.unlocked
                      ? AnyShapeStyle(LinearGradient(
                            colors: [c1.opacity(0.22), c2.opacity(0.14)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(Color.white.opacity(0.04)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    s.unlocked
                        ? AnyShapeStyle(LinearGradient(
                            colors: [c1.opacity(0.80), c2.opacity(0.50)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.white.opacity(0.10)),
                    style: StrokeStyle(lineWidth: 1.5, dash: s.unlocked ? [] : [4, 3])
                )
        )
        .shadow(color: s.unlocked ? c1.opacity(0.38) : .clear, radius: 12, x: 0, y: 4)
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📅 My Star Days")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("81 of 84 days!")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066))
            }

            HStack(spacing: 3) {
                ForEach(0..<12, id: \.self) { w in
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { d in
                            let v = Self.days[w * 7 + d]
                            let intensity = v < 0.15 ? 0 : v < 0.4 ? 1 : v < 0.7 ? 2 : 3
                            heatCell(intensity: intensity)
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private func heatCell(intensity: Int) -> some View {
        let fills: [Color] = [
            Color.white.opacity(0.06),
            Color(hex: 0xFFE066, opacity: 0.32),
            Color(hex: 0xFF8AD8, opacity: 0.55),
            Color(hex: 0xFFE066, opacity: 0.95),
        ]
        let shadows: [Color] = [
            .clear, .clear,
            Color(hex: 0xFF8AD8, opacity: 0.45),
            Color(hex: 0xFFE066, opacity: 0.85),
        ]
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(fills[intensity])
            .shadow(color: shadows[intensity], radius: intensity == 3 ? 5 : intensity == 2 ? 3 : 0)
    }

    private var recentBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("🌟 RECENT WINS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 4)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(recent.enumerated()), id: \.element.id) { idx, r in
                    HStack(spacing: 12) {
                        Text(r.emoji)
                            .font(.system(size: 20))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(
                                    RadialGradient(
                                        colors: [r.hue.opacity(0.4), .clear],
                                        center: .center, startRadius: 0, endRadius: 18
                                    )
                                )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.title)
                                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text(r.sub)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    if idx < recent.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
            )
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Settings Tab

struct SettingsTab: View {
    let onBack: () -> Void

    @State private var avatar: String = "🦊"
    @State private var explorerName: String = "Maya the Brave"
    @State private var grade: String = "4th"
    @State private var soundOn: Bool = true
    @State private var musicOn: Bool = true
    @State private var notifOn: Bool = true
    @State private var notifTime: String = "18:00"
    @State private var editingName: Bool = false
    @State private var parentUnlocked: Bool = false
    @State private var parentPin: String = ""
    @State private var pinError: Bool = false

    private let avatars = ["🦊","🐸","🐧","🦁","🐙","🦋","🐬","🦄"]
    private let grades = ["K","1st","2nd","3rd","4th","5th","6th","7th","8th","9th","10th","11th","12th"]
    private let times = ["07:00","12:00","15:30","18:00","20:00"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Back + header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Text("←")
                            Text("Me")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: 0xC8AAF0, opacity: 0.75))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }

                TabHeader(kicker: "⚙️ PREFERENCES", title: "Settings", emoji: "", subtitle: "Make Star Hop yours!")

                VStack(spacing: 12) {
                    profileSection
                    soundSection
                    reminderSection
                    grownUpSection
                    aboutSection
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 70)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .foregroundColor(.white)
    }

    // MARK: Profile

    private var profileSection: some View {
        SettingsSection(label: "🧑‍🚀 My Profile") {
            // Avatar picker
            VStack(alignment: .leading, spacing: 8) {
                SettingsLabel("Avatar")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(avatars, id: \.self) { a in
                            Button(action: { avatar = a }) {
                                Text(a).font(.system(size: 26))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(avatar == a
                                                  ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x5EE7FF, opacity: 0.3), Color(hex: 0xA78BFA, opacity: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                  : AnyShapeStyle(Color.white.opacity(0.06)))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(avatar == a ? Color(hex: 0x5EE7FF) : Color.clear, lineWidth: 2)
                                    )
                                    .animation(.easeOut(duration: 0.15), value: avatar == a)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.bottom, 14)

            // Name
            VStack(alignment: .leading, spacing: 6) {
                SettingsLabel("Explorer name")
                if editingName {
                    HStack(spacing: 8) {
                        TextField("Explorer name", text: $explorerName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.07))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(hex: 0x5EE7FF, opacity: 0.4), lineWidth: 1.5)
                            )
                            .onSubmit { editingName = false }
                        Button(action: { editingName = false }) {
                            Text("Save")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x1A0B40))
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(
                                    LinearGradient(colors: [Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button(action: { editingName = true }) {
                        HStack {
                            Text(explorerName)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text("Edit ✏️")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 14)

            // Grade
            VStack(alignment: .leading, spacing: 8) {
                SettingsLabel("Grade")
                FlexWrap(spacing: 6) {
                    ForEach(grades, id: \.self) { g in
                        Button(action: { grade = g }) {
                            Text(g)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(grade == g ? Color(hex: 0x1A0B40) : .white.opacity(0.75))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(
                                    Capsule().fill(grade == g
                                                   ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8AD8)], startPoint: .leading, endPoint: .trailing))
                                                   : AnyShapeStyle(Color.white.opacity(0.07)))
                                )
                                .shadow(color: grade == g ? Color(hex: 0xFFE066, opacity: 0.35) : .clear, radius: 8)
                                .animation(.easeOut(duration: 0.15), value: grade == g)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Sound

    private var soundSection: some View {
        SettingsSection(label: "🔊 Sound") {
            ToggleRow(label: "Sound effects", sub: "Whooshes, pops, and cheers", on: soundOn, accent: Color(hex: 0x5EE7FF)) {
                soundOn.toggle()
            }
            SettingsDivider()
            ToggleRow(label: "Background music", sub: "Calm space tunes while you learn", on: musicOn, accent: Color(hex: 0xA78BFA)) {
                musicOn.toggle()
            }
        }
    }

    // MARK: Reminders

    private var reminderSection: some View {
        SettingsSection(label: "🔔 Daily Reminder") {
            ToggleRow(label: "Remind me to study", sub: "Never miss your streak!", on: notifOn, accent: Color(hex: 0xFF8AD8)) {
                notifOn.toggle()
            }
            if notifOn {
                VStack(alignment: .leading, spacing: 8) {
                    SettingsLabel("Reminder time").padding(.top, 12)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(times, id: \.self) { t in
                                Button(action: { notifTime = t }) {
                                    Text(t)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(notifTime == t ? Color(hex: 0x1A0B40) : .white.opacity(0.75))
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(notifTime == t
                                                           ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFF8AD8), Color(hex: 0xA78BFA)], startPoint: .leading, endPoint: .trailing))
                                                           : AnyShapeStyle(Color.white.opacity(0.07)))
                                        )
                                        .animation(.easeOut(duration: 0.15), value: notifTime == t)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Grown-up corner

    private var grownUpSection: some View {
        SettingsSection(label: "👨‍👩‍👧 Grown-Up Corner") {
            if !parentUnlocked {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter your grown-up PIN to see progress reports and manage the account.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineSpacing(2)

                    HStack(spacing: 8) {
                        SecureField("PIN", text: $parentPin)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 90)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(pinError ? Color(hex: 0xFF5050, opacity: 0.15) : Color.white.opacity(0.07))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(pinError ? Color(hex: 0xFF5050, opacity: 0.6) : Color.white.opacity(0.12), lineWidth: 1.5)
                            )
                            .onSubmit { tryUnlock() }
                            .animation(.easeOut(duration: 0.2), value: pinError)

                        Button(action: tryUnlock) {
                            Text("Unlock")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    if pinError {
                        Text("Hmm, that PIN doesn't match. Try again! (hint: 1234)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Color(hex: 0xFF8080))
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach([
                        ("📊", "Progress report",      "Full breakdown by subject"),
                        ("⏱️", "Screen time",           "Set daily limits"),
                        ("📧", "Weekly email digest",   "maya@example.com"),
                        ("🔒", "Change grown-up PIN",   "Currently 4 digits"),
                    ], id: \.1) { (icon, title, sub) in
                        HStack(spacing: 12) {
                            Text(icon).font(.system(size: 18))
                                .frame(width: 38, height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.07))
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).font(.system(size: 14, weight: .semibold, design: .rounded))
                                Text(sub).font(.system(size: 11, design: .rounded)).foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            Text("›").foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.vertical, 12)
                        .overlay(Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1), alignment: .bottom)
                    }
                    Button(action: { parentUnlocked = false }) {
                        Text("🔒 Lock grown-up corner")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: 0xFF8080))
                            .frame(maxWidth: .infinity).padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: 0xFF5050, opacity: 0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        SettingsSection(label: "ℹ️ About") {
            VStack(spacing: 0) {
                ForEach([
                    ("App version", "1.0.0 🚀"),
                    ("Stars available", "47"),
                    ("Last updated", "Apr 2026"),
                ], id: \.0) { (label, val) in
                    HStack {
                        Text(label).font(.system(size: 13, design: .rounded)).foregroundColor(.white.opacity(0.65))
                        Spacer()
                        Text(val).font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .padding(.vertical, 10)
                    .overlay(Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1), alignment: .bottom)
                }
            }
        }
    }

    private func tryUnlock() {
        if parentPin == "1234" {
            parentUnlocked = true; pinError = false; parentPin = ""
        } else {
            pinError = true; parentPin = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { pinError = false }
        }
    }
}

// MARK: - Settings helpers

private struct SettingsSection<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 12)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1.5)
        )
    }
}

private struct SettingsLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .tracking(0.4)
            .textCase(.uppercase)
            .foregroundColor(.white.opacity(0.5))
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1).padding(.vertical, 10)
    }
}

private struct ToggleRow: View {
    let label: String
    let sub: String
    let on: Bool
    let accent: Color
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(sub).font(.system(size: 11, design: .rounded)).foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Capsule()
                    .fill(on ? accent : Color.white.opacity(0.12))
                    .frame(width: 48, height: 28)
                    .shadow(color: on ? accent.opacity(0.5) : .clear, radius: 6)
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3)
                    .frame(width: 20, height: 20)
                    .offset(x: on ? 10 : -10)
                    .animation(.spring(response: 0.22, dampingFraction: 0.82), value: on)
            }
            .onTapGesture { onToggle() }
            .animation(.easeOut(duration: 0.22), value: on)
        }
    }
}

// Simple horizontal-wrapping layout for grade chips
private struct FlexWrap: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
        return CGSize(width: maxW.isFinite ? maxW : x, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX && x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}
