//
//  GalaxyOverlays.swift
//  LA Hacks
//
//  Star Hop! TrainingOverlay (Quest start) + ConstellationModal.
//  Ported from project/galaxy-ui.jsx.
//

import SwiftUI

// MARK: - Training overlay (Quest Start)

struct TrainingOverlay: View {
    let node: StarNode
    let onClose: () -> Void
    let onStart: (StarNode) -> Void

    @State private var step: Int = 0

    private var palette: StarPalette { node.status.palette }

    private let calibrationSteps: [String] = [
        "🎮 Loading mini-games…",
        "🎲 Picking just-right questions",
        "🌟 Charging up your XP rocket",
        "✨ Ready to launch!",
    ]

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()
            confetti
            VStack(spacing: 0) {
                topBar
                    .padding(.top, 50)
                Spacer()
                orbitingStar
                    .padding(.bottom, 22)
                Text("🚀 QUEST START!")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundColor(palette.mid)
                    .padding(.bottom, 6)
                Text(node.label)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .tracking(-0.4)
                    .foregroundColor(.white)
                    .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(calibrationSteps.enumerated()), id: \.offset) { idx, label in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(idx < step ? palette.mid : Color.white.opacity(0.25), lineWidth: 2)
                                Circle()
                                    .fill(idx < step ? palette.mid : Color.clear)
                                if idx < step {
                                    Text("✓")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: 0x1A0B40))
                                }
                            }
                            .frame(width: 22, height: 22)

                            Text(label)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .opacity(idx <= step ? 1 : 0.3)
                    }
                }
                .frame(maxWidth: 320)
                .padding(.horizontal, 24)

                if step >= 3 {
                    Button(action: { onStart(node) }) {
                        Text("🚀 Blast Off!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x1A0B40))
                            .padding(.horizontal, 36)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: [palette.mid, palette.halo],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: palette.glow, radius: 24, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 28)
                    .transition(.opacity)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { startSequence() }
    }

    private var backdrop: some View {
        ZStack {
            Color(hex: 0x08041A, opacity: 0.96)
            RadialGradient(
                colors: [Color(hex: 0x3C1464, opacity: 0.7), Color(hex: 0x08041A, opacity: 0.96)],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 0, endRadius: 600
            )
        }
        .background(.ultraThinMaterial)
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Text("✕")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
    }

    private var confetti: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let colors: [UInt32] = [0xFFE066, 0xFF8AD8, 0x5EE7FF, 0xA78BFA, 0xFF8A4C]
                for i in 0..<16 {
                    let phase = (t + Double(i) * 0.2).truncatingRemainder(dividingBy: 3.5) / 3.5
                    let x = (Double(i) * 6.7).truncatingRemainder(dividingBy: 100) / 100 * Double(size.width)
                    let y = phase * Double(size.height + 60) - 30
                    let rect = CGRect(x: x, y: y, width: 10, height: 14)
                    ctx.fill(
                        Path(roundedRect: rect, cornerRadius: 3),
                        with: .color(Color(hex: colors[i % colors.count]).opacity(0.7))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var orbitingStar: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach([1, 2, 3], id: \.self) { i in
                    let s: CGFloat = 0.55 + CGFloat(i) * 0.22
                    let dur = Double(10 + i * 4)
                    let angle = (t.truncatingRemainder(dividingBy: dur) / dur) * 360.0
                    Circle()
                        .stroke(palette.mid.opacity(0.33), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .scaleEffect(s)
                        .overlay(
                            Circle()
                                .fill(palette.core)
                                .frame(width: 8, height: 8)
                                .shadow(color: palette.mid, radius: 14)
                                .offset(y: -100 * s)
                                .rotationEffect(.degrees(angle))
                        )
                }
                Text(node.emoji)
                    .font(.system(size: 60))
                    .scaleEffect(1.0 + 0.06 * CGFloat(sin(t * 2.4)))
                    .shadow(color: palette.mid, radius: 30 + 20 * CGFloat((sin(t * 2.4) + 1) / 2))
            }
            .frame(width: 200, height: 200)
        }
    }

    private func startSequence() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            withAnimation { step = 1 }
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation { step = 2 }
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            withAnimation { step = 3 }
            try? await Task.sleep(nanoseconds: 800_000_000)
            withAnimation { step = 4 }
        }
    }
}

// MARK: - Constellation modal

struct ConstellationModal: View {
    let constellation: Constellation
    let onClose: () -> Void
    let onJumpToStar: (StarNode) -> Void

    @State private var sheetFraction: CGFloat = 0.90
    @GestureState private var handleDrag: CGFloat = 0

    private var counts: (mastered: Int, learning: Int, gap: Int, locked: Int) {
        var m = 0, l = 0, g = 0, k = 0
        for n in constellation.nodes {
            switch n.status {
            case .mastered: m += 1
            case .learning: l += 1
            case .gap:      g += 1
            case .locked:   k += 1
            }
        }
        return (m, l, g, k)
    }

    var body: some View {
        ZStack {
            Color(hex: 0x08041A, opacity: 0.78)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                Spacer(minLength: 40)
                modalSheet
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var modalSheet: some View {
        VStack(spacing: 0) {
            // Drag handle — drag up to full screen, drag down to close
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 44, height: 5)
                .padding(.top, 6)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .updating($handleDrag) { v, state, _ in state = v.translation.height }
                        .onEnded { v in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                if v.translation.height > 80 {
                                    onClose()
                                } else {
                                    sheetFraction = v.translation.height < -40 ? 1.0 : 0.90
                                }
                            }
                        }
                )
                .onTapGesture { onClose() }

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

                        Button(action: onClose) {
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
        }
        .containerRelativeFrame(.vertical) { length, _ in
            let live = sheetFraction - handleDrag / length
            return length * max(0.60, min(1.0, live))
        }
        .background(modalBackground)
        .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .stroke(Color(hex: 0xFFE066, opacity: 0.4), lineWidth: 2)
                .ignoresSafeArea(edges: .bottom)
        )
        .foregroundColor(.white)
    }

    private var modalBackground: some View {
        LinearGradient(
            colors: [Color(hex: 0x281050, opacity: 0.97), Color(hex: 0x12082A, opacity: 0.99)],
            startPoint: .top, endPoint: .bottom
        )
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
                let nodeMap = Dictionary(uniqueKeysWithValues: constellation.nodes.map { ($0.id, $0) })
                for e in constellation.edges {
                    guard let A = nodeMap[e.a], let B = nodeMap[e.b] else { continue }
                    let pa = CGPoint(x: A.x * sc + dx, y: A.y * sc + dy)
                    let pb = CGPoint(x: B.x * sc + dx, y: B.y * sc + dy)
                    let both = A.status == .mastered && B.status == .mastered
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
                    let pal = n.status.palette
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
            cell(emoji: "⭐", label: "Shining", count: c.mastered, palette: StarStatus.mastered.palette)
            cell(emoji: "🌱", label: "Growing", count: c.learning, palette: StarStatus.learning.palette)
            cell(emoji: "😴", label: "Sleepy",  count: c.gap,      palette: StarStatus.gap.palette)
            cell(emoji: "🔒", label: "Locked",  count: c.locked,   palette: StarStatus.locked.palette)
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
        let pal = n.status.palette
        let m = n.status == .mastered ? 1.0 : n.status == .locked ? 0.0 : (n.mastery ?? 0.3)
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
