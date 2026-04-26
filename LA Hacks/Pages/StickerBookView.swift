//
//  StickerBookView.swift
//  LA Hacks
//
//  Full sticker book page accessible from the Me tab.
//  Sticker unlock state is driven live from UserSettings.
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

    static let totalCount = 45

    /// No sticker ever shows a permanent "new" badge — newness is transient.
    static let newIds: Set<String> = []

    /// Returns all stickers with live unlock state from the provided sets.
    static func items(unlocked: Set<String>, dates: [String: String]) -> [StarStickerItem] {
        rawTemplates.map { t in
            StarStickerItem(
                id: t.id, cat: t.cat, emoji: t.emoji, label: t.label, rarity: t.rarity,
                unlocked: unlocked.contains(t.id),
                earnedDate: dates[t.id],
                how: t.how, xp: t.xp, shimmer: t.shimmer
            )
        }
    }

    // MARK: Raw template data (unlock state is injected at runtime)

    private struct T {
        let id: String; let cat: StickerCat; let emoji: String; let label: String
        let rarity: StickerRarity; let how: String; let xp: Int; let shimmer: Color
    }

    private static let rawTemplates: [T] = [
        // MATH
        T(id:"pizza_pro",       cat:.math,     emoji:"🍕", label:"Pizza Pro",          rarity:.rare,   how:"Master the fraction stars",                          xp:120, shimmer:Color(hex:0xFF8AD8)),
        T(id:"sharp_shoot",     cat:.math,     emoji:"🎯", label:"Sharp Shooter",      rarity:.common, how:"Build a 10-answer correct streak",                   xp:60,  shimmer:Color(hex:0xFFE066)),
        T(id:"times_whiz",      cat:.math,     emoji:"✖️", label:"Times Whiz",         rarity:.common, how:"Master the Multiplication star",                     xp:60,  shimmer:Color(hex:0x5EE7FF)),
        T(id:"cool_cube",       cat:.math,     emoji:"🧊", label:"Cool Cube",          rarity:.rare,   how:"Master 15 stars total",                              xp:100, shimmer:Color(hex:0x5EE7FF)),
        T(id:"geo_gem",         cat:.math,     emoji:"💎", label:"Geometry Gem",       rarity:.epic,   how:"Master both the Triangle and Area stars",            xp:150, shimmer:Color(hex:0xA78BFA)),
        T(id:"frac_king",       cat:.math,     emoji:"👑", label:"Fraction King",      rarity:.epic,   how:"Finish 3 lessons with a perfect score",              xp:150, shimmer:Color(hex:0xFFE066)),
        T(id:"speed_demon",     cat:.math,     emoji:"⚡", label:"Speed Demon",        rarity:.rare,   how:"Nail a lesson with no hints and no wrong answers",   xp:80,  shimmer:Color(hex:0xFFE066)),
        T(id:"numbers_boss",    cat:.math,     emoji:"🎲", label:"Numbers Boss",       rarity:.common, how:"Master 10 stars total",                              xp:60,  shimmer:Color(hex:0xFF8AD8)),
        T(id:"perfect_score",   cat:.math,     emoji:"✨", label:"Perfect Score",      rarity:.rare,   how:"Finish any lesson without a single wrong answer",    xp:80,  shimmer:Color(hex:0xFFE066)),
        T(id:"number_cruncher", cat:.math,     emoji:"🖥️", label:"Number Cruncher",    rarity:.epic,   how:"Earn 2000 total XP",                                 xp:150, shimmer:Color(hex:0x5EE7FF)),
        // READING
        T(id:"word_wiz",        cat:.reading,  emoji:"🧙", label:"Word Wizard",        rarity:.rare,   how:"Master the Main Idea and Habitat stars",             xp:100, shimmer:Color(hex:0xA78BFA)),
        T(id:"story_star",      cat:.reading,  emoji:"📚", label:"Story Star",         rarity:.common, how:"Complete 5 lessons total",                           xp:60,  shimmer:Color(hex:0xFFE066)),
        T(id:"speed_read",      cat:.reading,  emoji:"👁️", label:"Speed Reader",       rarity:.rare,   how:"Finish 3 lessons without using any hints",           xp:90,  shimmer:Color(hex:0x5EE7FF)),
        T(id:"detective",       cat:.reading,  emoji:"🔍", label:"Detail Detective",   rarity:.epic,   how:"Finish 7 lessons without using any hints",           xp:140, shimmer:Color(hex:0xFF8AD8)),
        T(id:"bookworm",        cat:.reading,  emoji:"🐛", label:"Bookworm",           rarity:.common, how:"Complete 10 lessons total",                          xp:60,  shimmer:Color(hex:0xFFE066)),
        T(id:"no_hints",        cat:.reading,  emoji:"💡", label:"No Hints Needed",    rarity:.rare,   how:"Finish 5 lessons without using any hints",           xp:90,  shimmer:Color(hex:0x5EE7FF)),
        T(id:"scholar",         cat:.reading,  emoji:"📜", label:"Scholar",            rarity:.epic,   how:"Complete 25 lessons total",                          xp:140, shimmer:Color(hex:0xA78BFA)),
        // STREAKS
        T(id:"streak_7",        cat:.streaks,  emoji:"🔥", label:"7-Day Streak",       rarity:.common, how:"Study 7 days in a row",                              xp:70,  shimmer:Color(hex:0xFF8A4C)),
        T(id:"streak_14",       cat:.streaks,  emoji:"🌡️", label:"14-Day Streak",      rarity:.rare,   how:"Study 14 days in a row",                             xp:120, shimmer:Color(hex:0xFF8A4C)),
        T(id:"quick_fox",       cat:.streaks,  emoji:"🐆", label:"Quick Fox",          rarity:.rare,   how:"Complete a lesson perfectly with no hints",          xp:80,  shimmer:Color(hex:0xFFE066)),
        T(id:"hot_streak",      cat:.streaks,  emoji:"🌋", label:"Hot Streak",         rarity:.epic,   how:"Study 21 days in a row",                             xp:200, shimmer:Color(hex:0xFF8A4C)),
        T(id:"streak_30",       cat:.streaks,  emoji:"🌊", label:"30-Day Streak",      rarity:.epic,   how:"Study 30 days in a row",                             xp:220, shimmer:Color(hex:0x5EE7FF)),
        T(id:"iron_will",       cat:.streaks,  emoji:"🏋️", label:"Iron Will",          rarity:.legend, how:"Study every day for 60 days",                        xp:500, shimmer:Color(hex:0xA78BFA)),
        T(id:"symm_star",       cat:.streaks,  emoji:"🦋", label:"Symmetry Star",      rarity:.rare,   how:"Master 5 stars total",                               xp:90,  shimmer:Color(hex:0xFF8AD8)),
        T(id:"early_bird",      cat:.streaks,  emoji:"🌅", label:"Early Bird",         rarity:.common, how:"Complete a lesson before 8 AM",                      xp:50,  shimmer:Color(hex:0xFFE066)),
        T(id:"night_owl",       cat:.streaks,  emoji:"🦉", label:"Night Owl",          rarity:.common, how:"Complete a lesson after 9 PM",                       xp:50,  shimmer:Color(hex:0xA78BFA)),
        // EXPLORER
        T(id:"rocket_kid",      cat:.explorer, emoji:"🚀", label:"Rocket Kid",         rarity:.common, how:"Visit your first star",                              xp:50,  shimmer:Color(hex:0x5EE7FF)),
        T(id:"galaxy_voyager",  cat:.explorer, emoji:"🔭", label:"Galaxy Voyager",     rarity:.common, how:"Visit 3 different stars",                            xp:60,  shimmer:Color(hex:0x5EE7FF)),
        T(id:"space_cadet",     cat:.explorer, emoji:"🪐", label:"Space Cadet",        rarity:.rare,   how:"Visit 10 different stars",                           xp:120, shimmer:Color(hex:0xA78BFA)),
        T(id:"star_20",         cat:.explorer, emoji:"🌟", label:"Star Lighter",       rarity:.rare,   how:"Light up 20 stars",                                  xp:110, shimmer:Color(hex:0xFFE066)),
        T(id:"star_captain",    cat:.explorer, emoji:"👨‍🚀", label:"Star Captain",       rarity:.epic,   how:"Light up 30 stars",                                  xp:180, shimmer:Color(hex:0xFFE066)),
        T(id:"cosmo_scout",     cat:.explorer, emoji:"🌌", label:"Cosmic Scout",       rarity:.rare,   how:"Visit 15 different stars",                           xp:130, shimmer:Color(hex:0x5EE7FF)),
        T(id:"deep_space",      cat:.explorer, emoji:"🛸", label:"Deep Space",         rarity:.rare,   how:"Master stars in 3 different constellations",         xp:130, shimmer:Color(hex:0xA78BFA)),
        T(id:"universe_child",  cat:.explorer, emoji:"🌍", label:"Universe Child",     rarity:.epic,   how:"Master stars in 5 different constellations",         xp:170, shimmer:Color(hex:0x5EE7FF)),
        T(id:"galaxy_brain",    cat:.explorer, emoji:"🌀", label:"Galaxy Brain",       rarity:.legend, how:"Master 40 stars across all subjects",                xp:400, shimmer:Color(hex:0xFF8AD8)),
        // SECRET
        T(id:"hist_hero",       cat:.secret,   emoji:"🦖", label:"History Hero",       rarity:.rare,   how:"???",                                                xp:100, shimmer:Color(hex:0xA78BFA)),
        T(id:"nova_friend",     cat:.secret,   emoji:"🐾", label:"Nova's Pal",         rarity:.epic,   how:"???",                                                xp:200, shimmer:Color(hex:0xFF8AD8)),
        T(id:"rainbow",         cat:.secret,   emoji:"🌈", label:"Rainbow Seeker",     rarity:.epic,   how:"???",                                                xp:200, shimmer:Color(hex:0xA78BFA)),
        T(id:"all_stars",       cat:.secret,   emoji:"🌠", label:"All Stars",          rarity:.legend, how:"???",                                                xp:500, shimmer:Color(hex:0x5EE7FF)),
        T(id:"champ",           cat:.secret,   emoji:"🏆", label:"Champion",           rarity:.legend, how:"???",                                                xp:500, shimmer:Color(hex:0xFFE066)),
        T(id:"midnight_nova",   cat:.secret,   emoji:"🌙", label:"Midnight Nova",      rarity:.epic,   how:"???",                                                xp:200, shimmer:Color(hex:0xA78BFA)),
        T(id:"nova_apprentice", cat:.secret,   emoji:"🔰", label:"Nova's Apprentice",  rarity:.rare,   how:"???",                                                xp:100, shimmer:Color(hex:0xFFE066)),
        T(id:"star_collector",  cat:.secret,   emoji:"🎪", label:"Star Collector",     rarity:.rare,   how:"???",                                                xp:120, shimmer:Color(hex:0xFF8AD8)),
        T(id:"legendary_path",  cat:.secret,   emoji:"🏅", label:"Legendary Path",     rarity:.legend, how:"???",                                                xp:400, shimmer:Color(hex:0xFFE066)),
        T(id:"xp_master",       cat:.secret,   emoji:"💫", label:"XP Master",          rarity:.legend, how:"???",                                                xp:350, shimmer:Color(hex:0x5EE7FF)),
    ]
}

// MARK: - Main StickerBookView

struct StickerBookView: View {
    let onBack: () -> Void

    @State private var selectedCat: StickerCat? = nil
    @State private var detail: StarStickerItem? = nil
    @State private var visible = false
    @Environment(UserSettings.self) var userSettings

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var allItems: [StarStickerItem] {
        StarStickerData.items(
            unlocked: userSettings.unlockedStickers,
            dates: userSettings.stickerEarnedDates
        )
    }
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

    private var unlockedCount: Int { userSettings.unlockedStickers.count }
    private var totalCount: Int { StarStickerData.totalCount }
    private var progressPct: Double { Double(unlockedCount) / Double(totalCount) }

    var body: some View {
        ZStack {
            Color(hex: 0x08041A).ignoresSafeArea()
            nebulaBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                rarityLegend
                scrollContent
            }
        }
        .sheet(item: $detail) { s in
            StickerDetailSheet(sticker: s)
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
            Button(action: {
                withAnimation { visible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onBack() }
            }) {
                HStack(spacing: 6) {
                    Text("←")
                    Text("Me")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(Color.white.opacity(0.10)))
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 14)

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
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.bottom, 6)

            Text("\(Int((progressPct * 100).rounded()))% collected · \(totalCount - unlockedCount) stickers left to find")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 14)

            // Recently earned banner — shows the most-recently dated unlocked sticker
            if let recent = recentlyEarned {
                HStack(spacing: 12) {
                    Text(recent.emoji).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("✨ JUST EARNED!")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(0.4)
                            .foregroundColor(Color(hex: 0xFF8AD8))
                        Text("\(recent.label) — you're on a roll! 🎉")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("+\(recent.xp) XP")
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
            }

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

    /// The unlocked sticker whose earnedDate sorts last (most recently added).
    private var recentlyEarned: StarStickerItem? {
        allItems
            .filter { $0.unlocked && $0.earnedDate != nil }
            .last
    }

    private func categoryPill(id: StickerCat?, label: String, emoji: String) -> some View {
        let active = selectedCat == id
        let catItems = id == nil ? allItems : allItems.filter { $0.cat == id }
        let catUnlocked = catItems.filter { $0.unlocked }.count

        return Button(action: { withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { selectedCat = id } }) {
            HStack(spacing: 5) {
                Text(emoji).font(.system(size: 12))
                Text(LocalizedStringKey(label))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("\(catUnlocked)/\(catItems.count)")
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
                    ForEach(StickerRarity.allCases, id: \.self) { rarity in
                        let group = sorted.filter { $0.rarity == rarity }
                        if !group.isEmpty {
                            raritySectionView(rarity: rarity, items: group)
                        }
                    }
                } else {
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

    private var novaHintText: String {
        let locked = allItems.filter { !$0.unlocked }
        // Find the closest non-secret locked sticker to unlock
        if let next = locked.filter({ $0.cat != .secret }).sorted(by: { $0.rarity.sortOrder > $1.rarity.sortOrder }).first {
            return "You're \(locked.count) stickers away from completing your book! Try to unlock \(next.emoji) \(next.label) next."
        }
        if !locked.isEmpty {
            return "You're so close! Only \(locked.count) secret sticker\(locked.count == 1 ? "" : "s") left. Keep exploring! 🌌"
        }
        return "You collected ALL \(totalCount) stickers! You're a true Galaxy Legend! 🏆"
    }

    private var novaHint: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("🦊").font(.system(size: 24))
            VStack(alignment: .leading, spacing: 4) {
                Text("NOVA SAYS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x5EE7FF))
                Text(novaHintText)
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
