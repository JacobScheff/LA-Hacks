//
//  SkillSheet.swift
//  LA Hacks
//
//  Star Hop! SkillSheet — half-modal for a tapped star.
//  Ported from project/galaxy-ui.jsx.
//

import SwiftUI

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
