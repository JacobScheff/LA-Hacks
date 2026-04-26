//
//  ConstellationModal.swift
//  LA Hacks
//
//  Modal sheet showing details and stars within a constellation.
//  Extracted from GalaxyOverlays.swift.
//

import SwiftUI

// MARK: - Constellation modal

struct ConstellationModal: View {
    let constellation: Constellation
    let onJumpToStar: (StarNode) -> Void

    @Environment(\.dismiss) private var dismiss

    private var counts: (shining: Int, twinkling: Int, sleepy: Int, locked: Int) {
        let settings = UserSettings.shared
        var neighborMap: [String: [String]] = [:]
        for e in constellation.edges {
            neighborMap[e.a, default: []].append(e.b)
            neighborMap[e.b, default: []].append(e.a)
        }
        var sh = 0, tw = 0, sl = 0, lo = 0
        for n in constellation.nodes {
            switch settings.stage(for: n.id, initiallyLocked: n.initiallyLocked, neighborIds: neighborMap[n.id] ?? []) {
            case .shining:   sh += 1
            case .twinkling: tw += 1
            case .sleepy:    sl += 1
            case .locked:    lo += 1
            }
        }
        return (sh, tw, sl, lo)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                miniSky
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)

                VStack(alignment: .leading, spacing: 0) {
                    Text(constellation.course)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(0.4)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 4)

                    Text("\(constellation.emoji) \(constellation.name)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .tracking(-0.4)
                        .foregroundColor(.white)
                        .padding(.bottom, 12)

                    realConstellationPill
                        .padding(.bottom, 14)

                    masteryBar
                        .padding(.bottom, 14)

                    aboutCard
                        .padding(.bottom, 10)
                    skyLoreCard
                        .padding(.bottom, 16)

                    Text("⭐ Stars · \(constellation.nodes.count) total")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 8)

                    breakdownGrid
                        .padding(.bottom, 18)

                    Text("👉 Pick a star to visit")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 8)

                    VStack(spacing: 6) {
                        ForEach(constellation.nodes) { n in
                            starRow(n)
                        }
                    }
                    .padding(.bottom, 18)

                    Button(action: { dismiss() }) {
                        Text("🚀 Explore the constellation")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x1A0B40))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color(hex: 0xFF8A4C, opacity: 0.5), radius: 16, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
        .foregroundColor(.white)
        .presentationDetents([.large, .fraction(0.9)])
        .presentationDragIndicator(.visible)
        .presentationBackground {
            LinearGradient(
                colors: [Color(hex: 0x281050, opacity: 0.97), Color(hex: 0x12082A, opacity: 0.99)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .presentationCornerRadius(28)
    }

    private var miniSky: some View {
        let xs = constellation.nodes.map(\.x)
        let ys = constellation.nodes.map(\.y)
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 1
        let w = max(maxX - minX, 1), h = max(maxY - minY, 1)
        let pad: CGFloat = 24
        let W: CGFloat = 320, H: CGFloat = 170
        let sc = min((W - pad * 2) / w, (H - pad * 2) / h)
        let dx = pad + (W - pad * 2 - w * sc) / 2 - minX * sc
        let dy = pad + (H - pad * 2 - h * sc) / 2 - minY * sc

        return ZStack(alignment: .topLeading) {
            RadialGradient(
                colors: [Color(hex: 0xFF8AD8, opacity: 0.25), Color(hex: 0x08041A, opacity: 0.95)],
                center: .center, startRadius: 0, endRadius: 200
            )

            Canvas { ctx, _ in
                let settings = UserSettings.shared
                var neighborMap: [String: [String]] = [:]
                for e in constellation.edges {
                    neighborMap[e.a, default: []].append(e.b)
                    neighborMap[e.b, default: []].append(e.a)
                }
                let nodeMap = Dictionary(uniqueKeysWithValues: constellation.nodes.map { ($0.id, $0) })
                for e in constellation.edges {
                    guard let A = nodeMap[e.a], let B = nodeMap[e.b] else { continue }
                    let pa = CGPoint(x: A.x * sc + dx, y: A.y * sc + dy)
                    let pb = CGPoint(x: B.x * sc + dx, y: B.y * sc + dy)
                    let stageA = settings.stage(for: A.id, initiallyLocked: A.initiallyLocked, neighborIds: neighborMap[A.id] ?? [])
                    let stageB = settings.stage(for: B.id, initiallyLocked: B.initiallyLocked, neighborIds: neighborMap[B.id] ?? [])
                    let both = stageA == .shining && stageB == .shining
                    var p = Path()
                    p.move(to: pa); p.addLine(to: pb)
                    let style: StrokeStyle = both
                        ? StrokeStyle(lineWidth: 1.4)
                        : StrokeStyle(lineWidth: 0.8, dash: [3, 3])
                    let color: Color = both
                        ? Color(hex: 0xFFE066, opacity: 0.7)
                        : .white.opacity(0.25)
                    ctx.stroke(p, with: .color(color), style: style)
                }
                for n in constellation.nodes {
                    let p = CGPoint(x: n.x * sc + dx, y: n.y * sc + dy)
                    let nodeStage = settings.stage(for: n.id, initiallyLocked: n.initiallyLocked, neighborIds: neighborMap[n.id] ?? [])
                    let pal = nodeStage.palette
                    let r1 = n.size * 1.7
                    let r2 = n.size * 0.95
                    let r3 = n.size * 0.45
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - r1, y: p.y - r1, width: r1 * 2, height: r1 * 2)), with: .color(pal.glow))
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - r2, y: p.y - r2, width: r2 * 2, height: r2 * 2)), with: .color(pal.mid))
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - r3, y: p.y - r3, width: r3 * 2, height: r3 * 2)), with: .color(pal.core))
                }
            }
            .frame(width: W, height: H)

            Text("✨ CONSTELLATION")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.5)
                .foregroundColor(Color(hex: 0xFFE066))
                .padding(.top, 12)
                .padding(.leading, 14)
        }
        .frame(height: H)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xFFE066, opacity: 0.25), lineWidth: 1.5)
        )
    }

    private var realConstellationPill: some View {
        HStack(spacing: 6) {
            Text("🔭").font(.system(size: 11))
            Text(constellation.realName)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(0.6)
                .foregroundColor(Color(hex: 0xFFE066))
                .textCase(.uppercase)
            if !constellation.nickname.isEmpty {
                Text("· \"\(constellation.nickname)\"")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color(hex: 0xFFE066, opacity: 0.12)))
        .overlay(Capsule().stroke(Color(hex: 0xFFE066, opacity: 0.4), lineWidth: 1))
    }

    private var masteryBar: some View {
        let avg = constellation.masteryAvg
        let valueColor: Color = avg > 0.7 ? Color(hex: 0xFFE066) : avg > 0.4 ? Color(hex: 0xFF8AD8) : Color(hex: 0x5EE7FF)
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("How bright is this constellation?")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(Int((avg * 100).rounded()))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(valueColor)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8AD8)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: g.size.width * CGFloat(avg))
                        .shadow(color: Color(hex: 0xFFE066, opacity: 0.7), radius: 5)
                }
            }
            .frame(height: 10)
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📘 What's this about?")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: 0xFFE066))
            Text(constellation.blurb)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .lineSpacing(3)
                .foregroundColor(.white)
        }
        .padding(14)
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

    private var skyLoreCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("✨ Star Story")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: 0xFF8AD8))
            Text(constellation.skyStory)
                .font(.system(size: 13.5, weight: .medium, design: .rounded).italic())
                .lineSpacing(3)
                .foregroundColor(.white.opacity(0.92))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0xA855F7, opacity: 0.18), Color(hex: 0xFF8AD8, opacity: 0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xFF8AD8, opacity: 0.3), lineWidth: 1.5)
        )
    }

    private var breakdownGrid: some View {
        let c = counts
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
            cell(emoji: "⭐", label: "Shining",   count: c.shining,   palette: MasteryStage.shining.palette)
            cell(emoji: "✨", label: "Twinkling", count: c.twinkling, palette: MasteryStage.twinkling.palette)
            cell(emoji: "😴", label: "Sleepy",    count: c.sleepy,    palette: MasteryStage.sleepy.palette)
            cell(emoji: "🔒", label: "Locked",    count: c.locked,    palette: MasteryStage.locked.palette)
        }
    }

    private func cell(emoji: String, label: String, count: Int, palette: StarPalette) -> some View {
        HStack(spacing: 10) {
            Text(emoji).font(.system(size: 18))
            Text(label)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(palette.mid)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func starRow(_ n: StarNode) -> some View {
        let settings = UserSettings.shared
        var neighborMap: [String: [String]] = [:]
        for e in constellation.edges {
            neighborMap[e.a, default: []].append(e.b)
            neighborMap[e.b, default: []].append(e.a)
        }
        let nodeStage = settings.stage(for: n.id, initiallyLocked: n.initiallyLocked, neighborIds: neighborMap[n.id] ?? [])
        let pal = nodeStage.palette
        let rawMastery = settings.starMastery[n.id] ?? 0.0
        let m = nodeStage == .shining ? 1.0 : nodeStage == .locked ? 0.0 : rawMastery
        return Button(action: { onJumpToStar(n) }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [pal.glow, .clear],
                            center: .center, startRadius: 0, endRadius: 18
                        ))
                    Text(n.emoji).font(.system(size: 20))
                }
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(pal.glow.opacity(0.4))
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(n.label)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(pal.label)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(pal.mid)
                }

                Spacer()

                Text("\(Int((m * 100).rounded()))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(pal.mid)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(pal.mid.opacity(0.33), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
