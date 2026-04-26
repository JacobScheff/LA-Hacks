//
//  YouTab.swift
//  LA Hacks
//
//  Me tab — profile, stats heatmap, sticker book entry, streaks.
//  Extracted from GalaxyTabs.swift.
//

import SwiftUI

// MARK: - Me (YouTab)

struct YouTab: View {
    @State private var showSettings = false
    @State private var showStickerBook = false
    @Environment(UserSettings.self) var userSettings
    
    /// Deterministic 12 weeks × 7 days heatmap
    private static let days: [Double] = {
        var seed: UInt64 = 17
        var out:[Double] = []
        for _ in 0..<84 {
            seed = (seed &* 9301 &+ 49297) % 233280
            out.append(Double(seed) / 233280.0)
        }
        return out
    }()
    
    private var stickers: [StarStickerItem] { Array(StarStickerData.all.prefix(12)) }
    
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
    private var earnedCount: Int { StarStickerData.unlockedCount }
    private var totalStickerCount: Int { StarStickerData.all.count }

    private struct Recent: Identifiable {
        let id = UUID()
        let emoji: String
        let title: String
        let sub: String
        let hue: Color
    }
    private let recent: [Recent] = [
        Recent(emoji: "⭐", title: "Lit up Inverse Operations",      sub: "2 hours ago · +60 XP",  hue: Color(hex: 0xFFE066)),
        Recent(emoji: "😴", title: "Found a sleepy star: Volume",    sub: "Yesterday",              hue: Color(hex: 0x5EE7FF)),
        Recent(emoji: "🎮", title: "Played Times Tables Speed",      sub: "2 days ago · 24 min",   hue: Color(hex: 0xFF8AD8)),
        Recent(emoji: "🏅", title: "Unlocked Symmetry Star sticker", sub: "3 days ago",             hue: Color(hex: 0xA78BFA)),
    ]
    private var metrics: [Metric] {[
        Metric(emoji: "⭐", label: "Stars Lit",  value: "23",      total: 47, valueAsInt: 23, sub: nil,         hue: Color(hex: 0xFFE066)),
        Metric(emoji: "🌌", label: "Worlds",     value: "2",       total: 9,  valueAsInt: 2,  sub: nil,         hue: Color(hex: 0xA78BFA)),
        Metric(emoji: "🔥", label: "Streak",     value: "12d",     total: nil,valueAsInt: nil,sub: "best 18d",  hue: Color(hex: 0xFF8A4C)),
        Metric(emoji: "🏆", label: "Stickers",   value: "\(earnedCount)/\(totalStickerCount)", total: nil, valueAsInt: nil, sub: nil, hue: Color(hex: 0xFF8AD8)),
    ]
    }
    
    var body: some View {
        ZStack {
            if showSettings {
                SettingsTab(onBack: { showSettings = false })
            } else {
                profileContent
            }
            
            if showStickerBook {
                StickerBookView(onBack: { showStickerBook = false })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: showStickerBook)
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
            .padding(.top, 62)
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
                Text("⭐ STAR CAPTAIN · LVL 4")
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
        .onTapGesture { showStickerBook = true }
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
    
}
