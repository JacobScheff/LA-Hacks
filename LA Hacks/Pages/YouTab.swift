//
//  YouTab.swift
//  LA Hacks
//
//  Me tab — profile, stats heatmap, sticker book entry, streaks.
//  All metrics are live from UserSettings.
//

import SwiftUI

// MARK: - Me (YouTab)

struct YouTab: View {
    @State private var showSettings = false
    @State private var showStickerBook = false
    @State private var selectedHeatCell: HeatCellInfo? = nil
    @State private var contentID = UUID()
    @Environment(UserSettings.self) var userSettings

    private struct HeatCellInfo: Equatable {
        let date: Date
        let xp: Int

        var dateLabel: String {
            let cal = Calendar.current
            if cal.isDateInToday(date)     { return "Today" }
            if cal.isDateInYesterday(date) { return "Yesterday" }
            let f = DateFormatter()
            f.dateFormat = "EEE, MMM d"
            return f.string(from: date)
        }
        var isStudied: Bool { xp > 0 }
        var isStarDay: Bool { xp >= 150 }
    }

    private var stickers: [StarStickerItem] {
        Array(StarStickerData.items(
            unlocked: userSettings.unlockedStickers,
            dates: userSettings.stickerEarnedDates
        ).prefix(12))
    }

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

    private var earnedCount: Int { userSettings.unlockedStickers.count }
    private var totalStickerCount: Int { StarStickerData.totalCount }

    private var litCount: Int { userSettings.masteredStarsCount }
    private var totalNonLockedStars: Int {
        GalaxyData.constellations.flatMap { $0.nodes }.filter { !$0.initiallyLocked }.count
    }
    private var worldsStarted: Int {
        GalaxyData.constellations.filter { c in
            c.nodes.contains { userSettings.starMastery[$0.id] != nil }
        }.count
    }
    private var totalWorlds: Int { GalaxyData.constellations.count }

    private var metrics: [Metric] {[
        Metric(emoji: "⭐", label: "Stars Lit",
               value: "\(litCount)", total: totalNonLockedStars, valueAsInt: litCount,
               sub: nil, hue: Color(hex: 0xFFE066)),
        Metric(emoji: "🌌", label: "Worlds",
               value: "\(worldsStarted)", total: totalWorlds, valueAsInt: worldsStarted,
               sub: nil, hue: Color(hex: 0xA78BFA)),
        Metric(emoji: "🔥", label: "Streak",
               value: "\(userSettings.currentStreak)d", total: nil, valueAsInt: nil,
               sub: "best \(userSettings.longestStreak)d", hue: Color(hex: 0xFF8A4C)),
        Metric(emoji: "🏆", label: "Stickers",
               value: "\(earnedCount)/\(totalStickerCount)", total: nil, valueAsInt: nil,
               sub: nil, hue: Color(hex: 0xFF8AD8)),
    ]}

    var body: some View {
        ZStack {
            if showSettings {
                SettingsTab(onBack: { showSettings = false })
                    .id(contentID)
            } else {
                profileContent
                    .id(contentID)
            }

            if showStickerBook {
                StickerBookView(onBack: { showStickerBook = false })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: showStickerBook)
        .onChange(of: userSettings.language) { _, _ in contentID = UUID() }
    }

    private var profileContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Text("⚙️")
                            .font(.system(size: 17))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 16)
                }
                hero
                metricsGrid
                stickerBook
                heatmapCard
            }
            .padding(.top, 31)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .foregroundColor(.white)
    }

    private var hero: some View {
        HStack(spacing: 16) {
            Text(userSettings.avatar)
                .font(.system(size: 40))
                .frame(width: 80, height: 80)
                .background(
                    LinearGradient(
                        colors:[Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)],
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
                Text("⭐ \(userSettings.levelTitle.uppercased()) · LVL \(userSettings.level)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: 0xFFE066))
                Text(userSettings.explorerName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                    .foregroundColor(.white)
                Text("Exploring since January · \(userSettings.grade) grade")
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
        LazyVGrid(columns:[GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(metrics) { m in metricCard(m) }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
    }

    private func metricCard(_ m: Metric) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(m.emoji).font(.system(size: 16))
                Text(LocalizedStringKey(m.label))
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
                Text("\(earnedCount)/\(totalStickerCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: 0xFFE066, opacity: 0.14)))
                    .overlay(Capsule().stroke(Color(hex: 0xFFE066, opacity: 0.5), lineWidth: 1))

                Button(action: { showStickerBook = true }) {
                    Text("See all →")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0xA78BFA))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: 0xA78BFA, opacity: 0.12)))
                        .overlay(Capsule().stroke(Color(hex: 0xA78BFA, opacity: 0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
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

    private func stickerCell(_ s: StarStickerItem) -> some View {
        let c1 = s.shimmer
        let c2 = s.rarity.color
        return VStack(spacing: 7) {
            ZStack {
                if s.unlocked {
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

            Text(s.unlocked ? LocalizedStringKey(s.label) : "???")
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
        .onTapGesture { showStickerBook = true }
    }

    // MARK: - Heatmap

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📅 My Star Days")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(userSettings.starDaysInLast84) ⭐ star days")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFE066))
                    Text("\(userSettings.studiedDaysInLast84) of 84 days")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            if let info = selectedHeatCell {
                heatCellInfoPill(info)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }

            heatmapGrid
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: selectedHeatCell)
    }

    private func heatCellInfoPill(_ info: HeatCellInfo) -> some View {
        HStack(spacing: 6) {
            Text("📅")
                .font(.system(size: 12))
            Text(info.dateLabel)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            if info.isStudied {
                Text("·").foregroundColor(.white.opacity(0.35))
                Text("+\(info.xp) XP")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(info.isStarDay ? Color(hex: 0xFFE066) : Color(hex: 0xFF8AD8))
                if info.isStarDay {
                    Text("⭐ Star Day!")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFE066))
                }
            } else {
                Text("·").foregroundColor(.white.opacity(0.35))
                Text("No study")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            Button(action: { selectedHeatCell = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(info.isStarDay  ? Color(hex: 0xFFE066, opacity: 0.12) :
                      info.isStudied  ? Color(hex: 0xFF8AD8, opacity: 0.10) :
                                        Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(info.isStarDay ? Color(hex: 0xFFE066, opacity: 0.4) :
                        info.isStudied ? Color(hex: 0xFF8AD8, opacity: 0.3) :
                                         Color.white.opacity(0.12),
                        lineWidth: 1)
        )
    }

    private var heatmapGrid: some View {
        let grid = userSettings.heatmapGrid()
        let dowLabels = ["S","M","T","W","T","F","S"]

        return HStack(alignment: .top, spacing: 3) {
            // Day-of-week label column
            VStack(spacing: 0) {
                // Spacer to align with the month-label row
                Color.clear.frame(height: 14)
                ForEach(0..<7, id: \.self) { d in
                    Text(dowLabels[d])
                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.28))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 10)

            // Week columns
            ForEach(0..<12, id: \.self) { w in
                VStack(spacing: 3) {
                    // Month label
                    Text(monthLabel(week: w))
                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.38))
                        .frame(height: 11)

                    ForEach(0..<7, id: \.self) { d in
                        let xp = grid[w][d]
                        let intensity = xp < 0 ? 0 : (xp == 0 ? 0 : xp < 50 ? 1 : xp < 150 ? 2 : 3)
                        let isSelected = selectedHeatCell.map {
                            let cal = Calendar.current
                            let today = Date()
                            let weekday = cal.component(.weekday, from: today) - 1
                            let offset = w * 7 + d - (11 * 7 + weekday)
                            guard let date = cal.date(byAdding: .day, value: offset, to: today) else { return false }
                            return cal.isDate($0.date, inSameDayAs: date)
                        } ?? false
                        heatCell(intensity: intensity)
                            .opacity(xp < 0 ? 0.15 : 1.0)
                            .scaleEffect(isSelected ? 1.3 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                guard xp >= 0 else { return }
                                let cal = Calendar.current
                                let today = Date()
                                let weekday = cal.component(.weekday, from: today) - 1
                                let offset = w * 7 + d - (11 * 7 + weekday)
                                guard let date = cal.date(byAdding: .day, value: offset, to: today) else { return }
                                let info = HeatCellInfo(date: date, xp: xp)
                                withAnimation { selectedHeatCell = selectedHeatCell == info ? nil : info }
                            }
                    }
                }
            }
        }
    }

    private func monthLabel(week: Int) -> String {
        let cal = Calendar.current
        let today = Date()
        let weekday = cal.component(.weekday, from: today) - 1
        let offset = week * 7 - (11 * 7 + weekday)
        guard let date = cal.date(byAdding: .day, value: offset, to: today) else { return "" }
        let month = cal.component(.month, from: date)

        if week == 0 { return monthAbbr(month) }

        let prevOffset = (week - 1) * 7 - (11 * 7 + weekday)
        guard let prev = cal.date(byAdding: .day, value: prevOffset, to: today) else { return "" }
        let prevMonth = cal.component(.month, from: prev)
        return month != prevMonth ? monthAbbr(month) : ""
    }

    private func monthAbbr(_ m: Int) -> String {
        ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][m - 1]
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
}
