//
//  StickerBookView.swift
//  LA Hacks
//
//  Star Hop! Full sticker book — accessible from the Me tab.
//

import SwiftUI

// MARK: - Data models

enum StickerCat: String, CaseIterable {
    case math, reading, streaks, explorer, secret
    var displayLabel: String {
        switch self {
        case .math:     return "Math"
        case .reading:  return "Reading"
        case .streaks:  return "Streaks"
        case .explorer: return "Explorer"
        case .secret:   return "Secret"
        }
    }
    var emoji: String {
        switch self {
        case .math:     return "🔢"
        case .reading:  return "📖"
        case .streaks:  return "🔥"
        case .explorer: return "🚀"
        case .secret:   return "🌟"
        }
    }
}

enum StickerRarity: String, CaseIterable {
    case common, rare, epic, legend
    var displayLabel: String {
        switch self {
        case .common: return "Common"
        case .rare:   return "Rare"
        case .epic:   return "Epic"
        case .legend: return "Legendary"
        }
    }
    var color: Color {
        switch self {
        case .common: return Color(hex: 0xA0AEC0)
        case .rare:   return Color(hex: 0x5EE7FF)
        case .epic:   return Color(hex: 0xA78BFA)
        case .legend: return Color(hex: 0xFFE066)
        }
    }
    var glowColor: Color {
        switch self {
        case .common: return Color(hex: 0xA0AEC0, opacity: 0.5)
        case .rare:   return Color(hex: 0x5EE7FF, opacity: 0.6)
        case .epic:   return Color(hex: 0xA78BFA, opacity: 0.7)
        case .legend: return Color(hex: 0xFFE066, opacity: 0.8)
        }
    }
    var sortOrder: Int {
        switch self {
        case .legend: return 0
        case .epic:   return 1
        case .rare:   return 2
        case .common: return 3
        }
    }
}

struct StarStickerItem: Identifiable {
    let id: String
    let cat: StickerCat
    let emoji: String
    let label: String
    let rarity: StickerRarity
    let unlocked: Bool
    let earnedDate: String?
    let how: String
    let xp: Int
    let shimmer: Color
}

// MARK: - Sticker data

enum StarStickerData {
    static let all: [StarStickerItem] = [
        // MATH
        StarStickerItem(id: "pizza_pro",    cat: .math,     emoji: "🍕", label: "Pizza Pro",        rarity: .rare,   unlocked: true,  earnedDate: "Apr 12", how: "Mastered all fraction stars in Pizza Planet",      xp: 120, shimmer: Color(hex: 0xFF8AD8)),
        StarStickerItem(id: "sharp_shoot",  cat: .math,     emoji: "🎯", label: "Sharp Shooter",    rarity: .common, unlocked: true,  earnedDate: "Apr 8",  how: "Got 10 questions right in a row",                  xp: 60,  shimmer: Color(hex: 0xFFE066)),
        StarStickerItem(id: "times_whiz",   cat: .math,     emoji: "✖️", label: "Times Whiz",       rarity: .common, unlocked: true,  earnedDate: "Mar 30", how: "Finished the Times Tables speed round",            xp: 60,  shimmer: Color(hex: 0x5EE7FF)),
        StarStickerItem(id: "cool_cube",    cat: .math,     emoji: "🧊", label: "Cool Cube",        rarity: .rare,   unlocked: false, earnedDate: nil,      how: "Master all Volume & 3D Shape stars",               xp: 100, shimmer: Color(hex: 0x5EE7FF)),
        StarStickerItem(id: "geo_gem",      cat: .math,     emoji: "💎", label: "Geometry Gem",     rarity: .epic,   unlocked: false, earnedDate: nil,      how: "Complete the entire Shape City constellation",     xp: 150, shimmer: Color(hex: 0xA78BFA)),
        StarStickerItem(id: "frac_king",    cat: .math,     emoji: "👑", label: "Fraction King",    rarity: .epic,   unlocked: false, earnedDate: nil,      how: "Score 100% on 3 fraction quizzes",                 xp: 150, shimmer: Color(hex: 0xFFE066)),
        StarStickerItem(id: "speed_demon",  cat: .math,     emoji: "⚡", label: "Speed Demon",      rarity: .rare,   unlocked: false, earnedDate: nil,      how: "Finish a speed round in under 60 seconds",         xp: 80,  shimmer: Color(hex: 0xFFE066)),
        StarStickerItem(id: "numbers_boss", cat: .math,     emoji: "🔢", label: "Numbers Boss",     rarity: .common, unlocked: false, earnedDate: nil,      how: "Light up 10 math stars total",                     xp: 60,  shimmer: Color(hex: 0xFF8AD8)),
        // READING
        StarStickerItem(id: "word_wiz",     cat: .reading,  emoji: "🧙", label: "Word Wizard",      rarity: .rare,   unlocked: false, earnedDate: nil,      how: "Master all stars in Story Shore",                  xp: 100, shimmer: Color(hex: 0xA78BFA)),
        StarStickerItem(id: "story_star",   cat: .reading,  emoji: "📖", label: "Story Star",       rarity: .common, unlocked: false, earnedDate: nil,      how: "Complete 5 reading quests",                        xp: 60,  shimmer: Color(hex: 0xFFE066)),
        StarStickerItem(id: "speed_read",   cat: .reading,  emoji: "👁️", label: "Speed Reader",     rarity: .rare,   unlocked: false, earnedDate: nil,      how: "Read 3 stories without hints",                     xp: 90,  shimmer: Color(hex: 0x5EE7FF)),
        StarStickerItem(id: "detective",    cat: .reading,  emoji: "🔍", label: "Detail Detective",  rarity: .epic,   unlocked: false, earnedDate: nil,      how: "Find every hidden detail in 5 stories",            xp: 140, shimmer: Color(hex: 0xFF8AD8)),
        // STREAKS
        StarStickerItem(id: "streak_7",     cat: .streaks,  emoji: "🔥", label: "7-Day Streak",     rarity: .common, unlocked: true,  earnedDate: "Apr 15", how: "Studied 7 days in a row",                          xp: 70,  shimmer: Color(hex: 0xFF8A4C)),
        StarStickerItem(id: "quick_fox",    cat: .streaks,  emoji: "🦊", label: "Quick Fox",        rarity: .rare,   unlocked: true,  earnedDate: "Apr 1",  how: "Completed a quest in under 5 minutes",             xp: 80,  shimmer: Color(hex: 0xFFE066)),
        StarStickerItem(id: "hot_streak",   cat: .streaks,  emoji: "🌋", label: "Hot Streak",       rarity: .epic,   unlocked: false, earnedDate: nil,      how: "Keep a 21-day streak going",                       xp: 200, shimmer: Color(hex: 0xFF8A4C)),
        StarStickerItem(id: "iron_will",    cat: .streaks,  emoji: "🏋️", label: "Iron Will",        rarity: .legend, unlocked: false, earnedDate: nil,      how: "Study every single day for 60 days",               xp: 500, shimmer: Color(hex: 0xA78BFA)),
        StarStickerItem(id: "symm_star",    cat: .streaks,  emoji: "🦋", label: "Symmetry Star",    rarity: .rare,   unlocked: true,  earnedDate: "Apr 18", how: "Unlocked by completing Symmetry quests",           xp: 90,  shimmer: Color(hex: 0xFF8AD8)),
        // EXPLORER
        StarStickerItem(id: "rocket_kid",   cat: .explorer, emoji: "🚀", label: "Rocket Kid",       rarity: .common, unlocked: true,  earnedDate: "Jan 10", how: "Explored your first constellation",                xp: 50,  shimmer: Color(hex: 0x5EE7FF)),
        StarStickerItem(id: "space_cadet",  cat: .explorer, emoji: "🪐", label: "Space Cadet",      rarity: .rare,   unlocked: false, earnedDate: nil,      how: "Complete the Space Explorer trip",                 xp: 120, shimmer: Color(hex: 0xA78BFA)),
        StarStickerItem(id: "star_captain", cat: .explorer, emoji: "⭐", label: "Star Captain",     rarity: .epic,   unlocked: false, earnedDate: nil,      how: "Light up 30 stars total",                          xp: 180, shimmer: Color(hex: 0xFFE066)),
        StarStickerItem(id: "cosmo_scout",  cat: .explorer, emoji: "🌌", label: "Cosmic Scout",     rarity: .rare,   unlocked: false, earnedDate: nil,      how: "Visit every constellation in the galaxy",          xp: 130, shimmer: Color(hex: 0x5EE7FF)),
        StarStickerItem(id: "galaxy_brain", cat: .explorer, emoji: "🧠", label: "Galaxy Brain",     rarity: .legend, unlocked: false, earnedDate: nil,      how: "Master 40 stars across all subjects",              xp: 400, shimmer: Color(hex: 0xFF8AD8)),
        // SECRET
        StarStickerItem(id: "hist_hero",    cat: .secret,   emoji: "🦖", label: "History Hero",     rarity: .rare,   unlocked: false, earnedDate: nil,      how: "???",                                              xp: 100, shimmer: Color(hex: 0xA78BFA)),
        StarStickerItem(id: "champ",        cat: .secret,   emoji: "🏆", label: "Champion",         rarity: .legend, unlocked: false, earnedDate: nil,      how: "???",                                              xp: 500, shimmer: Color(hex: 0xFFE066)),
        StarStickerItem(id: "all_stars",    cat: .secret,   emoji: "🌠", label: "All Stars",        rarity: .legend, unlocked: false, earnedDate: nil,      how: "???",                                              xp: 500, shimmer: Color(hex: 0x5EE7FF)),
        StarStickerItem(id: "nova_friend",  cat: .secret,   emoji: "🦊", label: "Nova's Pal",       rarity: .epic,   unlocked: false, earnedDate: nil,      how: "???",                                              xp: 200, shimmer: Color(hex: 0xFF8AD8)),
        StarStickerItem(id: "rainbow",      cat: .secret,   emoji: "🌈", label: "Rainbow",          rarity: .epic,   unlocked: false, earnedDate: nil,      how: "???",                                              xp: 200, shimmer: Color(hex: 0xA78BFA)),
    ]

    static var unlockedCount: Int { all.filter { $0.unlocked }.count }
    static let newIds: Set<String> = ["symm_star"]
}

// MARK: - Sticker cell

private struct StickerCell: View {
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
                        Text(locked ? "❓" : sticker.emoji)
                            .font(.system(size: 30))
                            .grayscale(locked ? 1 : 0)
                            .opacity(locked ? 0.3 : 1)
                            .scaleEffect(pressed && !locked ? 1.12 : 1)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
                    }
                    .frame(height: 38)

                    Text(locked ? "???" : sticker.label)
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

// MARK: - Detail sheet

private struct StickerDetailSheet: View {
    let sticker: StarStickerItem
    let onClose: () -> Void

    @State private var visible = false

    private var rarity: StickerRarity { sticker.rarity }
    private var locked: Bool { !sticker.unlocked }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(visible ? 0.75 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 40, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, 0)

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
                Button(action: dismiss) {
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
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x130a2e), Color(hex: 0x08041A)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(rarity.color.opacity(0.4), lineWidth: 2)
                    .frame(maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .offset(y: visible ? 0 : 300)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: visible)
        }
        .onAppear {
            withAnimation { visible = true }
        }
    }

    private func dismiss() {
        withAnimation { visible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onClose() }
    }
}

// MARK: - Main StickerBookView

struct StickerBookView: View {
    let onBack: () -> Void

    @State private var selectedCat: StickerCat? = nil  // nil = All
    @State private var detail: StarStickerItem? = nil
    @State private var visible = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var allItems: [StarStickerItem] { StarStickerData.all }
    private var filtered: [StarStickerItem] {
        guard let cat = selectedCat else { return allItems }
        return allItems.filter { $0.cat == cat }
    }
    private var sorted: [StarStickerItem] {
        filtered.sorted {
            if $0.unlocked != $1.unlocked { return $0.unlocked }
            return $0.rarity.sortOrder < $1.rarity.sortOrder
        }
    }

    private var unlockedCount: Int { allItems.filter { $0.unlocked }.count }
    private var totalCount: Int { allItems.count }
    private var progressPct: Double { Double(unlockedCount) / Double(totalCount) }

    var body: some View {
        ZStack {
            // Background
            Color(hex: 0x08041A).ignoresSafeArea()
            nebulaBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                rarityLegend
                scrollContent
            }

            // Detail sheet overlay
            if let s = detail {
                StickerDetailSheet(sticker: s, onClose: { detail = nil })
                    .zIndex(10)
            }
        }
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 50)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: visible)
        .onAppear { withAnimation { visible = true } }
        .foregroundColor(.white)
    }

    // MARK: Nebula background

    private var nebulaBg: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0xA78BFA, opacity: 0.22), .clear],
                center: UnitPoint(x: 0.2, y: 0.1),
                startRadius: 0, endRadius: 300
            )
            RadialGradient(
                colors: [Color(hex: 0x5EE7FF, opacity: 0.16), .clear],
                center: UnitPoint(x: 0.85, y: 0.9),
                startRadius: 0, endRadius: 300
            )
            RadialGradient(
                colors: [Color(hex: 0xFF8AD8, opacity: 0.10), .clear],
                center: UnitPoint(x: 0.55, y: 0.45),
                startRadius: 0, endRadius: 280
            )
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Back button
            Button(action: {
                withAnimation { visible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onBack() }
            }) {
                HStack(spacing: 5) {
                    Text("←")
                    Text("Me")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: 0xA78BFA, opacity: 0.8))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 14)

            // Title row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("🎟️ COLLECTION")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(0.5)
                        .foregroundColor(Color(hex: 0xFFE066))
                        .shadow(color: Color(hex: 0xFFE066, opacity: 0.5), radius: 6)
                    Text("Sticker Book")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .tracking(-0.4)
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(spacing: 1) {
                    Text("\(unlockedCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFE066))
                    Text("of \(totalCount)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: 0xFFE066, opacity: 0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xFFE066, opacity: 0.45), lineWidth: 1.5)
                )
            }
            .padding(.bottom, 12)

            // Progress bar
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8AD8), Color(hex: 0xA78BFA)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: g.size.width * CGFloat(progressPct))
                        .shadow(color: Color(hex: 0xFFE066, opacity: 0.6), radius: 4)
                }
            }
            .frame(height: 8)
            .overlay(
                Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.bottom, 6)

            Text("\(Int((progressPct * 100).rounded()))% collected · \(totalCount - unlockedCount) stickers left to find")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 14)

            // Recently earned banner
            HStack(spacing: 12) {
                Text("🦋").font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text("✨ JUST EARNED!")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.4)
                        .foregroundColor(Color(hex: 0xFF8AD8))
                    Text("Symmetry Star — you're on a roll! 🎉")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("+90 XP")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0xFF8AD8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(hex: 0xFF8AD8, opacity: 0.18)))
                    .overlay(Capsule().stroke(Color(hex: 0xFF8AD8, opacity: 0.4), lineWidth: 1))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: 0xFF8AD8, opacity: 0.18), Color(hex: 0xA78BFA, opacity: 0.12)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: 0xFF8AD8, opacity: 0.4), lineWidth: 1.5)
            )
            .padding(.bottom, 14)

            // Category pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    categoryPill(id: nil, label: "All", emoji: "✨")
                    ForEach(StickerCat.allCases, id: \.self) { cat in
                        categoryPill(id: cat, label: cat.displayLabel, emoji: cat.emoji)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
    }

    private func categoryPill(id: StickerCat?, label: String, emoji: String) -> some View {
        let active = selectedCat == id
        let count: Int
        let total: Int
        if let cat = id {
            count = allItems.filter { $0.cat == cat && $0.unlocked }.count
            total = allItems.filter { $0.cat == cat }.count
        } else {
            count = unlockedCount
            total = totalCount
        }

        return Button(action: { withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { selectedCat = id } }) {
            HStack(spacing: 5) {
                Text(emoji).font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("\(count)/\(total)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(active ? Color.black.opacity(0.15) : Color.white.opacity(0.1)))
            }
            .foregroundColor(active ? Color(hex: 0x1A0B40) : .white.opacity(0.7))
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(active
                          ? AnyShapeStyle(LinearGradient(
                              colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8AD8)],
                              startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color.white.opacity(0.07)))
            )
            .shadow(color: active ? Color(hex: 0xFFE066, opacity: 0.4) : .clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: Rarity legend

    private var rarityLegend: some View {
        HStack(spacing: 14) {
            ForEach(StickerRarity.allCases, id: \.self) { r in
                HStack(spacing: 4) {
                    Circle()
                        .fill(r.color)
                        .frame(width: 7, height: 7)
                        .shadow(color: r.glowColor, radius: 3)
                    Text(r.displayLabel)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: Scroll content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                if selectedCat == nil {
                    // Group by rarity with section headers
                    ForEach(StickerRarity.allCases, id: \.self) { rarity in
                        let group = sorted.filter { $0.rarity == rarity }
                        if !group.isEmpty {
                            raritySectionView(rarity: rarity, items: group)
                        }
                    }
                } else {
                    // Flat grid for single category
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(sorted) { s in
                            StickerCell(sticker: s, isNew: StarStickerData.newIds.contains(s.id), onTap: { detail = $0 })
                        }
                    }
                    .padding(.top, 6)
                }

                novaHint
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
    }

    private func raritySectionView(rarity: StickerRarity, items: [StarStickerItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Circle()
                    .fill(rarity.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: rarity.glowColor, radius: 5)
                Text(rarity.displayLabel.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.4)
                    .foregroundColor(rarity.color)
                Rectangle()
                    .fill(rarity.color.opacity(0.2))
                    .frame(height: 1)
                Text("\(items.filter { $0.unlocked }.count)/\(items.count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items) { s in
                    StickerCell(sticker: s, isNew: StarStickerData.newIds.contains(s.id), onTap: { detail = $0 })
                }
            }
        }
    }

    // MARK: Nova hint

    private var novaHint: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("🦊").font(.system(size: 24))
            VStack(alignment: .leading, spacing: 4) {
                Text("NOVA SAYS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x5EE7FF))
                Text("You're \(totalCount - unlockedCount) stickers away from completing your book! Finish the Space Explorer trip next to get 🪐 Space Cadet.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
        )
    }
}
