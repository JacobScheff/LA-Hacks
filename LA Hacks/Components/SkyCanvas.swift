//
//  SkyCanvas.swift
//  LA Hacks
//
//  Pure-render Canvas for the galaxy sky (stars, nebulas, links).
//  Added: onDiscoverTap callback — called when user taps the "New Skies" plus
//  button in the discover nebula. Parent sets showUploadModal = true in response.

import SwiftUI

struct SkyCanvas: View {
    let constellations: [Constellation]
    let stages: [String: MasteryStage]
    let pendingNewIds: Set<String>
    let tx: CGFloat
    let ty: CGFloat
    let scale: CGFloat
    let selectedId: String?
    let focusedConstellationId: String?
    let filter: MasteryStage?
    let showDiscoverNebula: Bool

    /// Called when the user taps the pulsing ➕ in the discover nebula.
    /// Wire this to `showUploadModal = true` in your galaxy parent view.
    var onDiscoverTap: (() -> Void)? = nil

    // Discover nebula centre (must match drawDiscoverNebula call below)
    private let discoverCX: CGFloat = 760
    private let discoverCY: CGFloat = 1450
    private let discoverHitR: CGFloat = 36   // tap radius around the plus button

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let wsc: CGFloat = 1.3

                drawParallaxStars(ctx: ctx, t: t)

                ctx.translateBy(x: tx, y: ty)
                ctx.scaleBy(x: scale * wsc, y: scale * wsc)

                drawBackdrop(ctx: &ctx, t: t)
                drawBridges(ctx: &ctx)
                drawConstellations(ctx: &ctx)
                if showDiscoverNebula {
                    drawDiscoverNebula(ctx: &ctx, t: t, cx: discoverCX, cy: discoverCY)
                }
                drawStars(ctx: &ctx, t: t, scale: scale)
            }
            // Transparent tap layer sitting over the canvas to catch discover-nebula taps
            .overlay {
                if showDiscoverNebula, let tapAction = onDiscoverTap {
                    GeometryReader { geo in
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                // Convert screen tap → world coordinates
                                let wsc: CGFloat = 1.3
                                let worldX = (location.x - tx) / (scale * wsc)
                                let worldY = (location.y - ty) / (scale * wsc)
                                let dx = worldX - discoverCX
                                let dy = worldY - discoverCY
                                if sqrt(dx * dx + dy * dy) <= discoverHitR {
                                    tapAction()
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: Parallax star field

    private func drawParallaxStars(ctx: GraphicsContext, t: TimeInterval) {
        var farCtx = ctx
        farCtx.translateBy(x: tx * 0.05, y: ty * 0.05)
        for s in GalaxyData.starLayers.far {
            farCtx.fill(
                Path(ellipseIn: CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r * 2, height: s.r * 2)),
                with: .color((s.warm ? Color(hex: 0xD0E8FF) : .white).opacity(s.o))
            )
        }

        var midCtx = ctx
        midCtx.translateBy(x: tx * 0.16, y: ty * 0.16)
        for s in GalaxyData.starLayers.mid {
            let tw = 0.5 + 0.5 * sin(t / s.tw * 2 + s.td)
            let alpha = s.o * (0.2 + 0.8 * tw)
            midCtx.fill(
                Path(ellipseIn: CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r * 2, height: s.r * 2)),
                with: .color((s.warm ? Color(hex: 0xFFE8C8) : .white).opacity(alpha))
            )
        }

        var nearCtx = ctx
        nearCtx.translateBy(x: tx * 0.36, y: ty * 0.36)
        for s in GalaxyData.starLayers.near {
            let tw = 0.5 + 0.5 * sin(t / s.tw * 2 + s.td)
            let alpha = s.o * (0.25 + 0.75 * tw)
            let hR = s.r * 2.8
            nearCtx.fill(
                Path(ellipseIn: CGRect(x: s.x - hR, y: s.y - hR, width: hR * 2, height: hR * 2)),
                with: .color(s.warm ? Color(hex: 0xFFDCA0, opacity: 0.18) : Color(hex: 0xB4DCFF, opacity: 0.18))
            )
            nearCtx.fill(
                Path(ellipseIn: CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r * 2, height: s.r * 2)),
                with: .color((s.warm ? Color(hex: 0xFFE4AA) : .white).opacity(alpha))
            )
        }
    }

    // MARK: Backdrop

    private func drawBackdrop(ctx: inout GraphicsContext, t: TimeInterval) {
        do {
            let cx: CGFloat = 500, cy: CGFloat = 800
            let rx: CGFloat = 900, ry: CGFloat = 180
            var p = ctx
            p.translateBy(x: cx, y: cy)
            p.rotate(by: .degrees(-22))
            p.translateBy(x: -cx, y: -cy)
            let rect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
            let grad = Gradient(stops: [
                .init(color: Color(hex: 0xDCD2FF, opacity: 0.18), location: 0),
                .init(color: Color(hex: 0xDCD2FF, opacity: 0.11), location: 0.35),
                .init(color: Color(hex: 0xDCD2FF, opacity: 0.04), location: 0.70),
                .init(color: Color(hex: 0xDCD2FF, opacity: 0), location: 1),
            ])
            p.fill(Path(ellipseIn: rect),
                   with: .radialGradient(grad, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: ry))
        }

        let nebulae: [(x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat, color: UInt32, opacity: Double)] = [
            (250, 295, 255, 210, 0x5EE7FF, 0.42),
            (600, 365, 280, 250, 0xFF8C3C, 0.44),
            (242, 625, 265, 230, 0xA855F7, 0.40),
            (772, 588, 290, 245, 0xFFE066, 0.40),
            (225, 952, 255, 235, 0xFF4FB6, 0.40),
            (540, 932, 275, 250, 0x5EE7FF, 0.40),
            (818, 345, 235, 300, 0xFF4FB6, 0.44),
            (820, 1038, 268, 268, 0x50E6A0, 0.36),
            (470, 1258, 295, 290, 0xA855F7, 0.38),
        ]
        for n in nebulae {
            let rect = CGRect(x: n.x - n.rx, y: n.y - n.ry, width: n.rx * 2, height: n.ry * 2)
            let grad = Gradient(stops: [
                .init(color: Color(hex: n.color, opacity: n.opacity),        location: 0),
                .init(color: Color(hex: n.color, opacity: n.opacity * 0.62), location: 0.28),
                .init(color: Color(hex: n.color, opacity: n.opacity * 0.28), location: 0.58),
                .init(color: Color(hex: n.color, opacity: n.opacity * 0.07), location: 0.82),
                .init(color: Color(hex: n.color, opacity: 0),                location: 1),
            ])
            ctx.fill(Path(ellipseIn: rect),
                     with: .radialGradient(grad, center: CGPoint(x: n.x, y: n.y), startRadius: 0, endRadius: max(n.rx, n.ry)))
        }
    }

    // MARK: Bridges

    private func drawBridges(ctx: inout GraphicsContext) {
        let nodes = nodesByIdLocal()
        for e in GalaxyData.bridges {
            guard let A = nodes[e.a], let B = nodes[e.b] else { continue }
            let both = stages[A.id] == .shining && stages[B.id] == .shining
            let mx = (A.x + B.x) / 2 + (B.y - A.y) * 0.08
            let my = (A.y + B.y) / 2 - (B.x - A.x) * 0.08
            var path = Path()
            path.move(to: A.point)
            path.addQuadCurve(to: B.point, control: CGPoint(x: mx, y: my))
            let color: Color = both
                ? Color(hex: 0xFFE066, opacity: 0.22)
                : Color(hex: 0x96AAC8, opacity: 0.10)
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 0.5, dash: [1, 5]))
        }
    }

    private func nodesByIdLocal() -> [String: StarNode] {
        var out: [String: StarNode] = [:]
        for c in constellations { for n in c.nodes { out[n.id] = n } }
        return out
    }

    // MARK: Constellation lines

    private func drawConstellations(ctx: inout GraphicsContext) {
        for c in constellations {
            for e in c.edges {
                let stageA = stages[e.a, default: .sleepy]
                let stageB = stages[e.b, default: .sleepy]
                let bothShining = stageA == .shining && stageB == .shining
                let eitherLocked = stageA == .locked || stageB == .locked
                guard let A = c.nodes.first(where: { $0.id == e.a }),
                      let B = c.nodes.first(where: { $0.id == e.b }) else { continue }
                let stroke: Color = bothShining
                    ? Color(hex: 0xFFE066, opacity: 0.7)
                    : eitherLocked
                        ? Color(hex: 0x788296, opacity: 0.18)
                        : Color(hex: 0xB4D2E6, opacity: 0.45)
                var path = Path()
                path.move(to: A.point)
                path.addLine(to: B.point)
                let style: StrokeStyle = bothShining
                    ? StrokeStyle(lineWidth: 1.1, lineCap: .round)
                    : StrokeStyle(lineWidth: 0.7, lineCap: .round, dash: [3, 4])
                ctx.stroke(path, with: .color(stroke), style: style)
            }
        }
    }

    // MARK: Stars

    private func drawStars(ctx: inout GraphicsContext, t: TimeInterval, scale: CGFloat) {
        for c in constellations {
            for n in c.nodes {
                let nodeStage = stages[n.id, default: .sleepy]
                let dim = (filter != nil && nodeStage != filter)
                let baseOpacity: Double = dim ? 0.18 : 1.0
                let pal = nodeStage.palette
                let r = n.size
                let isSelected = (selectedId == n.id)
                let isNew = pendingNewIds.contains(n.id)
                let popScale: CGFloat = isNew ? CGFloat(min(1.0, 0.6 + 0.4 * (sin(t * 6) + 1) / 2)) : 1.0

                // Halo (radial)
                let haloMul: CGFloat = nodeStage == .shining ? 6 : nodeStage == .twinkling ? 5 : 4
                let haloR = r * haloMul * popScale
                let haloRect = CGRect(x: n.x - haloR, y: n.y - haloR, width: haloR * 2, height: haloR * 2)
                let haloColor = pal.glow
                let haloGrad = Gradient(stops: [
                    .init(color: haloColor.opacity(0.88 * baseOpacity), location: 0),
                    .init(color: haloColor.opacity(0.55 * baseOpacity), location: 0.22),
                    .init(color: haloColor.opacity(0.22 * baseOpacity), location: 0.52),
                    .init(color: haloColor.opacity(0.05 * baseOpacity), location: 0.80),
                    .init(color: haloColor.opacity(0),                  location: 1),
                ])
                ctx.fill(Path(ellipseIn: haloRect),
                         with: .radialGradient(haloGrad, center: n.point, startRadius: 0, endRadius: haloR))

                if isSelected {
                    let phase = (sin(t * 2.6) + 1) / 2
                    let outerR = r * (3.2 + 1.3 * phase)
                    let outerOp = 0.9 - 0.7 * phase
                    var ring = Path()
                    ring.addEllipse(in: CGRect(x: n.x - outerR, y: n.y - outerR, width: outerR * 2, height: outerR * 2))
                    ctx.stroke(ring, with: .color(pal.mid.opacity(outerOp)), lineWidth: 1.2)
                }

                // Body — chunky 5-point star, dimmed for locked
                let bodyR = r * 1.9 * popScale
                drawFivePointStar(
                    ctx: &ctx,
                    cx: n.x, cy: n.y, size: bodyR,
                    fill: pal.mid.opacity(baseOpacity),
                    stroke: pal.halo.opacity(baseOpacity * (nodeStage == .locked ? 0.6 : 1)),
                    rotation: nodeStage == .shining ? sin(t * 1.0 + Double(n.id.hashValue % 100) * 0.1) * 0.1 : 0
                )

                // Shining: face overlay (small eyes + smile)
                if nodeStage == .shining {
                    let eyeR = bodyR * 0.10
                    ctx.fill(Path(ellipseIn: CGRect(x: n.x - bodyR * 0.22 - eyeR, y: n.y - bodyR * 0.05 - eyeR, width: eyeR * 2, height: eyeR * 2)),
                             with: .color(Color(hex: 0x3A2A00, opacity: baseOpacity)))
                    ctx.fill(Path(ellipseIn: CGRect(x: n.x + bodyR * 0.22 - eyeR, y: n.y - bodyR * 0.05 - eyeR, width: eyeR * 2, height: eyeR * 2)),
                             with: .color(Color(hex: 0x3A2A00, opacity: baseOpacity)))
                    var smile = Path()
                    smile.move(to: CGPoint(x: n.x - bodyR * 0.18, y: n.y + bodyR * 0.16))
                    smile.addQuadCurve(to: CGPoint(x: n.x + bodyR * 0.18, y: n.y + bodyR * 0.16),
                                       control: CGPoint(x: n.x, y: n.y + bodyR * 0.36))
                    ctx.stroke(smile, with: .color(Color(hex: 0x3A2A00, opacity: baseOpacity)),
                               style: StrokeStyle(lineWidth: bodyR * 0.07, lineCap: .round))
                }

                // Sleepy: extra pulsing aura
                if nodeStage == .sleepy {
                    let phase = (sin(t * 2.1 + Double(n.x) * 0.01) + 1) / 2
                    let gR = r * (2.2 + 2.8 * phase)
                    let gOp = 0.7 - 0.7 * phase
                    var gap = Path()
                    gap.addEllipse(in: CGRect(x: n.x - gR, y: n.y - gR, width: gR * 2, height: gR * 2))
                    ctx.stroke(gap, with: .color(pal.halo.opacity(gOp * baseOpacity)), lineWidth: 0.7)
                }

                // Center bright dot for twinkling
                if nodeStage == .twinkling {
                    let cR = r * 0.5
                    ctx.fill(Path(ellipseIn: CGRect(x: n.x - cR, y: n.y - cR, width: cR * 2, height: cR * 2)),
                             with: .color(pal.core.opacity(0.9 * baseOpacity)))
                }

                if isNew {
                    let chipW: CGFloat = 28, chipH: CGFloat = 14
                    let chipY = n.y - bodyR - 10
                    let wsc: CGFloat = 1.3
                    let invS = 1.0 / (scale * wsc)
                    var nctx = ctx
                    nctx.translateBy(x: n.x, y: chipY)
                    nctx.scaleBy(x: invS, y: invS)
                    let chip = Path(roundedRect: CGRect(x: -chipW/2, y: -chipH/2, width: chipW, height: chipH), cornerRadius: 7)
                    nctx.fill(chip, with: .color(Color(hex: 0xFFE066)))
                    nctx.stroke(chip, with: .color(Color(hex: 0xFFB300)), lineWidth: 1)
                    nctx.draw(Text("NEW").font(.system(size: 8.5, weight: .bold, design: .rounded)).foregroundColor(Color(hex: 0x3A2A00)),
                              at: .zero, anchor: .center)
                }

                let labelAlpha: Double = isSelected
                    ? 1.0
                    : max(0.0, min(1.0, Double((scale - 0.72) / 0.18)))
                if labelAlpha > 0.01 {
                    let labelText = "\(n.emoji) \(n.label)"
                    let chipH: CGFloat = 16
                    let approxW = max(48, CGFloat(labelText.count) * 5.6 + 18)
                    let chipY = n.y + bodyR + 10
                    let wsc: CGFloat = 1.3
                    let invS = 1.0 / (scale * wsc)
                    var lctx = ctx
                    lctx.opacity = labelAlpha
                    lctx.translateBy(x: n.x, y: chipY)
                    lctx.scaleBy(x: invS, y: invS)
                    let chipRect = CGRect(x: -approxW/2, y: -chipH/2, width: approxW, height: chipH)
                    lctx.fill(
                        Path(roundedRect: chipRect, cornerRadius: chipH/2),
                        with: .color(Color(hex: 0x0E1228, opacity: 0.82))
                    )
                    lctx.stroke(
                        Path(roundedRect: chipRect, cornerRadius: chipH/2),
                        with: .color(nodeStage == .locked ? Color(hex: 0xB4BED2, opacity: 0.3) : Color.white.opacity(0.18)),
                        lineWidth: 0.7
                    )
                    let label = Text(labelText)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(nodeStage == .locked ? Color(hex: 0xC8D2E6, opacity: 0.7) : .white)
                    lctx.draw(label, at: .zero, anchor: .center)
                }
            }
        }
        drawConstellationNameplates(ctx: &ctx)
    }

    private func drawConstellationNameplates(ctx: inout GraphicsContext) {
        let wsc: CGFloat = 1.3
        let invS = 1.0 / (scale * wsc)

        for c in constellations {
            let avg = c.masteryAvg
            let pct = Int((avg * 100).rounded())
            let hot = avg > 0.7
            let minY = c.nodes.map(\.y).min() ?? c.centroid.y
            let labelY = minY - 22
            let cx = c.centroid.x

            let label = "\(c.emoji) \(c.name)"
            let labelW = max(86, CGFloat(label.count) * 8.2 + 14)
            let chipW: CGFloat = 38
            let gap: CGFloat = 6
            let totalW = labelW + gap + chipW
            let halfW = totalW / 2
            let h: CGFloat = 26

            var tctx = ctx
            tctx.translateBy(x: cx, y: labelY)
            tctx.scaleBy(x: invS, y: invS)

            let haloRect = CGRect(x: -halfW - 6, y: -h/2 - 4, width: totalW + 12, height: h + 8)
            tctx.fill(Path(roundedRect: haloRect, cornerRadius: (h + 8)/2),
                     with: .color(Color(hex: 0x08041A, opacity: 0.42)))

            let nameRect = CGRect(x: -halfW, y: -h/2, width: labelW, height: h)
            tctx.fill(Path(roundedRect: nameRect, cornerRadius: h/2),
                     with: .color(Color(hex: 0x0E1228, opacity: 0.85)))
            tctx.stroke(Path(roundedRect: nameRect, cornerRadius: h/2),
                       with: .color(Color(hex: 0xFFE066, opacity: 0.4)), lineWidth: 1)
            tctx.draw(Text(label).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: 0xFFF8E1)),
                     at: CGPoint(x: -halfW + labelW/2, y: 0), anchor: .center)

            let chipRect = CGRect(x: -halfW + labelW + gap, y: -h/2, width: chipW, height: h)
            tctx.fill(Path(roundedRect: chipRect, cornerRadius: h/2),
                     with: .color(hot ? Color(hex: 0xFFB300, opacity: 0.9) : Color(hex: 0x5EE7FF, opacity: 0.18)))
            tctx.stroke(Path(roundedRect: chipRect, cornerRadius: h/2),
                       with: .color(hot ? Color(hex: 0xFFE066, opacity: 0.9) : Color(hex: 0x5EE7FF, opacity: 0.6)), lineWidth: 1)
            tctx.draw(Text("\(pct)%").font(.system(size: 11, weight: .bold, design: .rounded))
                     .foregroundColor(hot ? Color(hex: 0x2A1A00) : Color(hex: 0x5EE7FF)),
                     at: CGPoint(x: -halfW + labelW + gap + chipW/2, y: 0), anchor: .center)
        }
    }

    // MARK: Discover nebula

    private func drawDiscoverNebula(ctx: inout GraphicsContext, t: TimeInterval, cx: CGFloat, cy: CGFloat) {
        let clouds: [(dx: CGFloat, dy: CGFloat, r: CGFloat, color: UInt32, op: Double)] = [
            (0, 0, 120, 0xA855F7, 0.85),
            (-15, 10, 95, 0xFF4FB6, 0.65),
            (20, -15, 80, 0x5EE7FF, 0.5),
        ]
        for c in clouds {
            let rect = CGRect(x: cx + c.dx - c.r, y: cy + c.dy - c.r, width: c.r * 2, height: c.r * 2)
            let grad = Gradient(stops: [
                .init(color: Color(hex: c.color, opacity: c.op * 0.5), location: 0),
                .init(color: Color(hex: c.color, opacity: 0), location: 1),
            ])
            ctx.fill(Path(ellipseIn: rect),
                     with: .radialGradient(grad, center: CGPoint(x: cx + c.dx, y: cy + c.dy), startRadius: 0, endRadius: c.r))
        }

        let boundaryR: CGFloat = 78
        var boundary = ctx
        boundary.translateBy(x: cx, y: cy)
        boundary.rotate(by: .radians(t * 0.16))
        boundary.translateBy(x: -cx, y: -cy)
        boundary.stroke(
            Path(ellipseIn: CGRect(x: cx - boundaryR, y: cy - boundaryR, width: boundaryR * 2, height: boundaryR * 2)),
            with: .color(.white.opacity(0.22)),
            style: StrokeStyle(lineWidth: 1, dash: [3, 6])
        )

        let ghosts: [(dx: CGFloat, dy: CGFloat, r: CGFloat)] = [
            (-55, -30, 3.5), (30, -50, 4.5), (70, 20, 3),
            (-40, 35, 4), (0, 60, 3), (-75, 5, 2.6),
            (55, -10, 3), (20, 30, 2.6),
        ]
        for g in ghosts {
            let p = CGPoint(x: cx + g.dx, y: cy + g.dy)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - g.r, y: p.y - g.r, width: g.r * 2, height: g.r * 2)),
                     with: .color(.white.opacity(0.35)))
            ctx.stroke(Path(ellipseIn: CGRect(x: p.x - g.r - 2, y: p.y - g.r - 2, width: (g.r + 2) * 2, height: (g.r + 2) * 2)),
                       with: .color(.white.opacity(0.15)),
                       style: StrokeStyle(lineWidth: 0.6, dash: [1, 2]))
        }

        // Pulsing ring + plus button
        let pulsePhase = (sin(t * 2.6) + 1) / 2
        let outR = 26 + 12 * pulsePhase
        ctx.stroke(
            Path(ellipseIn: CGRect(x: cx - outR, y: cy - outR, width: outR * 2, height: outR * 2)),
            with: .color(Color(hex: 0xFFE066, opacity: 0.7 * (1 - pulsePhase))),
            lineWidth: 1.4
        )
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 32, y: cy - 32, width: 64, height: 64)),
                 with: .color(Color(hex: 0xFFE066, opacity: 0.18)))
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 26, y: cy - 26, width: 52, height: 52)),
                 with: .color(Color(hex: 0x140A32, opacity: 0.85)))
        ctx.stroke(Path(ellipseIn: CGRect(x: cx - 26, y: cy - 26, width: 52, height: 52)),
                   with: .color(Color(hex: 0xFFE066)), lineWidth: 1.6)
        var plus = Path()
        plus.move(to: CGPoint(x: cx - 10, y: cy)); plus.addLine(to: CGPoint(x: cx + 10, y: cy))
        plus.move(to: CGPoint(x: cx, y: cy - 10)); plus.addLine(to: CGPoint(x: cx, y: cy + 10))
        ctx.stroke(plus, with: .color(Color(hex: 0xFFE066)),
                   style: StrokeStyle(lineWidth: 3.4, lineCap: .round))

        // Nameplates (constant screen size)
        let wsc: CGFloat = 1.3
        let invS = 1.0 / (scale * wsc)

        do {
            let labelW: CGFloat = 130, labelH: CGFloat = 26
            var tctx = ctx
            tctx.translateBy(x: cx, y: cy + 110)
            tctx.scaleBy(x: invS, y: invS)
            let nameRect = CGRect(x: -labelW/2, y: -labelH/2, width: labelW, height: labelH)
            tctx.fill(Path(roundedRect: nameRect, cornerRadius: labelH/2),
                     with: .color(Color(hex: 0x0E1228, opacity: 0.85)))
            tctx.stroke(Path(roundedRect: nameRect, cornerRadius: labelH/2),
                       with: .color(Color(hex: 0xFFE066, opacity: 0.4)), lineWidth: 1)
            tctx.draw(Text("✨ New Skies").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: 0xFFF8E1)),
                     at: .zero, anchor: .center)
        }

        do {
            var tctx = ctx
            tctx.translateBy(x: cx, y: cy + 142)
            tctx.scaleBy(x: invS, y: invS)
            tctx.draw(
                Text("Tap to grow new stars!")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066, opacity: 0.95)),
                at: .zero, anchor: .center
            )
        }
    }

    private func drawFivePointStar(ctx: inout GraphicsContext, cx: CGFloat, cy: CGFloat, size: CGFloat,
                                    fill: Color, stroke: Color, rotation: Double) {
        var path = Path()
        for i in 0..<10 {
            let ang = Double.pi / 5 * Double(i) - Double.pi / 2 + rotation
            let rad = (i % 2 == 0) ? size : size * 0.42
            let x = cx + CGFloat(cos(ang)) * rad
            let y = cy + CGFloat(sin(ang)) * rad
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        ctx.fill(path, with: .color(fill))
        ctx.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: 0.9, lineJoin: .round))
    }
}
