//
//  GalaxyComponents.swift
//  LA Hacks
//
//  Star Hop! TopHeader, BottomNav, SkillSheet, MasteryRing.
//  Ported from project/galaxy-ui.jsx.
//

import SwiftUI
import UIKit

// MARK: - Top header (Hi Maya, XP, streak, filters)

struct TopHeader: View {
    let stats: (mastered: Int, gaps: Int, learning: Int)
    let filter: StarStatus?
    let onFilter: (StarStatus?) -> Void
    var topInset: CGFloat = 44

    private let xp = 1240
    private let xpMax = 1500
    private let level = 4
    private let streak = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hi, Maya! 👋")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .tracking(-0.4)
                        .foregroundColor(.white)
                    HStack(spacing: 0) {
                        Text("\(stats.mastered) stars shining")
                            .foregroundColor(Color(hex: 0xFFE066))
                        Text(" · \(stats.gaps) sleepy · \(stats.learning) growing")
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
                    chip(id: nil,        label: "🌌 All",      dot: nil)
                    chip(id: .gap,       label: "Wake up!",    dot: Color(hex: 0x5EE7FF))
                    chip(id: .learning,  label: "Growing",     dot: Color(hex: 0xFF8AD8))
                    chip(id: .mastered,  label: "Shining",     dot: Color(hex: 0xFFE066))
                }
                .padding(.horizontal, 14)
            }
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var streakChip: some View {
        Text("🔥 \(streak)")
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
        Text("🦊")
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

    private var xpBar: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: 0xFFE066), Color(hex: 0xFFB300)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                Text("\(level)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x3A2A00))
            }
            .frame(width: 28, height: 28)
            .shadow(color: Color(hex: 0xFFE066, opacity: 0.6), radius: 6)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Star Captain · Lvl \(level)")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(xp) / \(xpMax) XP")
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
                            .frame(width: g.size.width * CGFloat(xp) / CGFloat(xpMax))
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
    private func chip(id: StarStatus?, label: String, dot: Color?) -> some View {
        let active = filter == id
        Button(action: { onFilter(id) }) {
            HStack(spacing: 6) {
                if let dot {
                    Circle()
                        .fill(dot)
                        .frame(width: 7, height: 7)
                        .shadow(color: dot, radius: 3)
                }
                Text(label)
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

// MARK: - Bottom nav

struct BottomNav: View {
    let active: GalaxyTab
    let onChange: (GalaxyTab) -> Void
    var bottomSafeArea: CGFloat = 28
    
    private struct Item: Identifiable {
        let id: GalaxyTab; let label: String; let icon: String
    }
    private let items: [Item] = [
        .init(id: .galaxy,  label: "Galaxy", icon: "🌌"),
        .init(id: .study,   label: "Quests", icon: "🎯"),
        .init(id: .nova,    label: "Nova",   icon: "🦊"),
        .init(id: .profile, label: "Me",     icon: "👤"),
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { it in
                let isActive = it.id == active
                Button {
                    selectTab(it.id)
                } label: {
                    VStack(spacing: 3) {
                        Text(it.icon)
                            .font(.system(size: isActive ? 25 : 22))
                            .scaleEffect(isActive ? 1.05 : 1.0)
                        Text(it.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .tracking(0.2)
                            .foregroundColor(isActive ? Color(hex: 0xFFE066) : .white.opacity(0.52))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        Group {
                            if isActive {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(hex: 0xFFE066, opacity: 0.16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color(hex: 0xFFE066, opacity: 0.45), lineWidth: 1)
                                    )
                                    .shadow(color: Color(hex: 0xFFE066, opacity: 0.25), radius: 10, x: 0, y: 3)
                                    .padding(.horizontal, 4)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isActive)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .glassEffect(Glass.regular, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        // Drag-scrub overlay: finger slides across bar to switch tabs live.
        // Uses simultaneousGesture so it never blocks button taps.
        .overlay(
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { v in
                                let idx = max(0, min(items.count - 1,
                                                     Int(v.location.x / (geo.size.width / CGFloat(items.count)))))
                                selectTab(items[idx].id)
                            }
                            .onEnded { v in
                                let idx = max(0, min(items.count - 1,
                                                     Int(v.location.x / (geo.size.width / CGFloat(items.count)))))
                                selectTab(items[idx].id)
                            }
                    )
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, max(bottomSafeArea, 8))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    
    private func selectTab(_ tab: GalaxyTab) {
        guard tab != active else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
            onChange(tab)
        }
    }
}

// MARK: - Mastery ring

struct MasteryRing: View {
        let value: Double
        let color: Color
        let emoji: String
        var size: CGFloat = 78
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: max(0.0, min(1.0, value)))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color, radius: 6)
                Text(emoji).font(.system(size: 28))
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Skill sheet
    
    struct SkillSheet: View {
        @EnvironmentObject var state: GalaxyState
        let node: StarNode
        let onTrain: (StarNode) -> Void
        
        @Environment(\.dismiss) private var dismiss
        
        private var palette: StarPalette { node.status.palette }
        private var mastery: Double {
            switch node.status {
            case .mastered: return 1.0
            case .locked:   return 0.0
            default:        return node.mastery ?? 0.3
            }
        }
        private var xpReward: Int {
            switch node.status {
            case .gap: return 80
            case .learning: return 50
            case .mastered: return 20
            case .locked: return 0
            }
        }
        private var ctaLabel: String {
            switch node.status {
            case .mastered: return "✨ Practice for \(xpReward) XP"
            case .learning: return "🚀 Continue quest · +\(xpReward) XP"
            case .gap:      return "⚡ Wake up this star! +\(xpReward) XP"
            case .locked:   return "🔒 Master prerequisites first"
            }
        }
        private var statusBubble: (label: String, bg: Color, ring: Color) {
            switch node.status {
            case .mastered: return ("⭐ Shining bright!",         Color(hex: 0xFFE066, opacity: 0.25), Color(hex: 0xFFE066))
            case .learning: return ("🌱 Growing!",                Color(hex: 0xFF8AD8, opacity: 0.25), Color(hex: 0xFF8AD8))
            case .gap:      return ("😴 Sleepy — wake it up!",    Color(hex: 0x5EE7FF, opacity: 0.25), Color(hex: 0x5EE7FF))
            case .locked:   return ("🔒 Locked",                  Color(hex: 0x788296, opacity: 0.18), Color(hex: 0x7B8294))
            }
        }
        private var related: [StarNode] {
            guard let info = state.nodesById()[node.id],
                  let c = state.constellations.first(where: { $0.id == info.constellationId })
            else { return [] }
            let nodeMap = Dictionary(uniqueKeysWithValues: c.nodes.map { ($0.id, $0) })
            return c.edges
                .compactMap { e -> StarNode? in
                    if e.a == node.id { return nodeMap[e.b] }
                    if e.b == node.id { return nodeMap[e.a] }
                    return nil
                }
                .prefix(5)
                .map { $0 }
        }
        private var minutes: Int {
            switch node.status {
            case .mastered: return 5
            case .learning: return 8
            default: return 12
            }
        }
        private var novaSays: String {
            switch node.status {
            case .mastered: return "You crushed this one! Practice keeps your star super sparkly."
            case .locked:   return "Brighten the connecting stars first and I'll unlock this for you!"
            case .gap:      return "This star is taking a nap. Let's wake it up with a fun mini-game!"
            case .learning: return "You're doing great! A few more rounds and this star will SHINE."
            }
        }
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerRow
                        .padding(.bottom, 16)
                    novaCard
                        .padding(.bottom, 12)
                    statTiles
                        .padding(.bottom, 16)
                    if !related.isEmpty {
                        relatedSection
                            .padding(.bottom, 16)
                    }
                    if node.status == .locked {
                        lockedCTA
                    } else {
                        primaryCTA
                        Text("⏱ About \(minutes) min · Mini-games & quizzes")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
            .presentationDetents([.fraction(0.7), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: 0x281050, opacity: 0.0), Color(hex: 0x1C0C3C, opacity: 0.98), Color(hex: 0x12082A, opacity: 0.99)],
                        startPoint: .top, endPoint: .bottom
                    )
                }
                .background(.ultraThinMaterial)
            }
            .presentationCornerRadius(28)
        }
        
        private var headerRow: some View {
            HStack(alignment: .center, spacing: 14) {
                MasteryRing(value: mastery, color: palette.mid, emoji: node.emoji)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let info = state.nodesById()[node.id] {
                        Text("\(info.constellationEmoji) \(info.constellationName)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(0.4)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Text(node.label)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .tracking(-0.3)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let star = node.star {
                        Text("★ Star: \(star)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .tracking(0.6)
                            .foregroundColor(Color(hex: 0xFFE066))
                            .textCase(.uppercase)
                            .padding(.top, 4)
                    }
                    
                    Text(statusBubble.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(statusBubble.bg))
                        .overlay(Capsule().stroke(statusBubble.ring, lineWidth: 1.5))
                        .padding(.top, 6)
                }
                Spacer(minLength: 0)
            }
        }
        
        private var novaCard: some View {
            HStack(alignment: .top, spacing: 10) {
                Text("🦊")
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 0) {
                    (Text("Nova says: ").font(.system(size: 13.5, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: 0xFFE066))
                     + Text(novaSays).font(.system(size: 13.5, weight: .medium, design: .rounded)).foregroundColor(.white))
                    .lineSpacing(2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: 0xFFE066, opacity: 0.2), lineWidth: 1.5)
            )
        }
        
        private var statTiles: some View {
            HStack(spacing: 8) {
                statTile(icon: "🎮", label: "Played", value: node.status == .mastered ? "12x" : node.status == .locked ? "—" : "4x")
                statTile(icon: "⏰", label: "Last", value: node.status == .locked ? "—" : node.status == .mastered ? "6d" : "17h")
                statTile(icon: "🎯", label: "Score", value: node.status == .locked ? "—" : "\(Int(mastery * 100))%")
            }
        }
        
        private func statTile(icon: String, label: String, value: String) -> some View {
            VStack(spacing: 2) {
                Text(icon).font(.system(size: 16))
                Text(label)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        
        private var relatedSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("✨ Friends nearby")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                FlowLayout(spacing: 6) {
                    ForEach(related, id: \.id) { r in
                        let pal = r.status.palette
                        HStack(spacing: 6) {
                            Text(r.emoji).font(.system(size: 13))
                            Text(r.label)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                        .overlay(Capsule().stroke(pal.mid.opacity(0.33), lineWidth: 1))
                    }
                }
            }
        }
        
        private var primaryCTA: some View {
            Button(action: { onTrain(node) }) {
                Text(ctaLabel)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x1A0B40))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 20)
                    .background(
                        LinearGradient(
                            colors: [palette.mid, palette.halo],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: palette.glow, radius: 14, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        
        private var lockedCTA: some View {
            Text("🔒 Master prerequisites first")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: 0xC8D2E6, opacity: 0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: 0x788296, opacity: 0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: 0x788296, opacity: 0.4), lineWidth: 1.5)
                )
        }
    }
    
    // MARK: - Simple flow layout (for connected-stars chips)
    
    struct FlowLayout: Layout {
        var spacing: CGFloat = 6
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let maxW = proposal.width ?? .infinity
            var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, totalH: CGFloat = 0
            for s in subviews {
                let sz = s.sizeThatFits(.unspecified)
                if x + sz.width > maxW {
                    x = 0; y += rowH + spacing; rowH = 0
                }
                x += sz.width + spacing
                rowH = max(rowH, sz.height)
                totalH = y + rowH
            }
            return CGSize(width: maxW.isFinite ? maxW : x, height: totalH)
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowH: CGFloat = 0
            for s in subviews {
                let sz = s.sizeThatFits(.unspecified)
                if x + sz.width > bounds.maxX {
                    x = bounds.minX; y += rowH + spacing; rowH = 0
                }
                s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
                x += sz.width + spacing
                rowH = max(rowH, sz.height)
            }
        }
    }
