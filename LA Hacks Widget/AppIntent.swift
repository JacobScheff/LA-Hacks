//
//  AppIntent.swift
//  LA Hacks Widget
//
//  4×4 (systemLarge) widget — constellation drawn as 5-pointed stars + dashed edges.
//

import WidgetKit
import SwiftUI

// MARK: - Shared constants

private let kWidgetSuite = "group.com.lahacks.widget"
private let kActiveKey   = "activeConstellation"

// MARK: - Color helper

private extension Color {
    init(hex rgb: UInt32, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >>  8) & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Models

struct WidgetStar {
    let x, y, size: CGFloat
    let status: String

    var coreColor: Color {
        switch status {
        case "mastered": return Color(hex: 0xFFD700)
        case "learning": return Color(hex: 0xFF80D0)
        case "gap":      return Color(hex: 0x40DCFF)
        default:         return Color(hex: 0x8090A8)
        }
    }
    var glowColor: Color {
        switch status {
        case "mastered": return Color(hex: 0xFFAA00, opacity: 0.50)
        case "learning": return Color(hex: 0xFF40A8, opacity: 0.45)
        case "gap":      return Color(hex: 0x10B8E8, opacity: 0.42)
        default:         return Color(hex: 0x506070, opacity: 0.22)
        }
    }
}

struct WidgetEdge { let ax, ay, bx, by: CGFloat }

// MARK: - Timeline entry

struct ConstellationEntry: TimelineEntry {
    let date: Date
    let name, emoji, course: String
    let masteryPercent: Int
    let stars: [WidgetStar]
    let edges: [WidgetEdge]

    static let preview = ConstellationEntry(
        date: .now, name: "Pizza Planet", emoji: "🍕",
        course: "Math · Grades 4–5", masteryPercent: 58,
        stars: [
            WidgetStar(x: 670, y: 250, size: 7, status: "mastered"),
            WidgetStar(x: 540, y: 260, size: 6, status: "mastered"),
            WidgetStar(x: 660, y: 340, size: 5, status: "learning"),
            WidgetStar(x: 600, y: 340, size: 6, status: "learning"),
            WidgetStar(x: 540, y: 340, size: 5, status: "gap"),
            WidgetStar(x: 600, y: 400, size: 4, status: "gap"),
            WidgetStar(x: 670, y: 460, size: 5, status: "gap"),
            WidgetStar(x: 530, y: 470, size: 7, status: "locked"),
        ],
        edges: [
            WidgetEdge(ax: 670, ay: 250, bx: 660, by: 340),
            WidgetEdge(ax: 540, ay: 260, bx: 540, by: 340),
            WidgetEdge(ax: 660, ay: 340, bx: 600, by: 340),
            WidgetEdge(ax: 600, ay: 340, bx: 540, by: 340),
            WidgetEdge(ax: 600, ay: 340, bx: 600, by: 400),
            WidgetEdge(ax: 660, ay: 340, bx: 670, by: 460),
            WidgetEdge(ax: 540, ay: 340, bx: 530, by: 470),
        ]
    )
}

// MARK: - Provider

struct ConstellationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConstellationEntry { .preview }
    func getSnapshot(in context: Context, completion: @escaping (ConstellationEntry) -> Void) {
        completion(context.isPreview ? .preview : load())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ConstellationEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [load()], policy: .after(next)))
    }

    private func load() -> ConstellationEntry {
        guard
            let defaults = UserDefaults(suiteName: kWidgetSuite),
            let data     = defaults.data(forKey: kActiveKey),
            let dict     = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return .preview }

        let stars: [WidgetStar] = (dict["nodes"] as? [[String: Any]] ?? []).compactMap { d in
            guard let x  = d["x"]      as? Double, let y  = d["y"]    as? Double,
                  let s  = d["status"] as? String,  let sz = d["size"] as? Double
            else { return nil }
            return WidgetStar(x: CGFloat(x), y: CGFloat(y), size: CGFloat(sz), status: s)
        }
        let edges: [WidgetEdge] = (dict["edges"] as? [[String: Any]] ?? []).compactMap { d in
            guard let ax = d["ax"] as? Double, let ay = d["ay"] as? Double,
                  let bx = d["bx"] as? Double, let by = d["by"] as? Double
            else { return nil }
            return WidgetEdge(ax: CGFloat(ax), ay: CGFloat(ay), bx: CGFloat(bx), by: CGFloat(by))
        }
        return ConstellationEntry(
            date: .now,
            name:           dict["name"]           as? String ?? "Star Hop!",
            emoji:          dict["emoji"]          as? String ?? "⭐",
            course:         dict["course"]         as? String ?? "Keep exploring",
            masteryPercent: dict["masteryPercent"] as? Int    ?? 0,
            stars: stars, edges: edges
        )
    }
}

// MARK: - Star shape helper

private func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat) -> Path {
    var path = Path()
    for i in 0..<10 {
        let angle = CGFloat(i) * .pi / 5 - .pi / 2
        let r: CGFloat = i.isMultiple(of: 2) ? outer : inner
        let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
        i == 0 ? path.move(to: pt) : path.addLine(to: pt)
    }
    path.closeSubpath()
    return path
}

// MARK: - Constellation canvas

private struct StarMapCanvas: View {
    let stars: [WidgetStar]
    let edges: [WidgetEdge]

    var body: some View {
        Canvas { ctx, size in
            guard !stars.isEmpty else { return }

            // Bounding box with generous padding so stars spread out
            let xPad: CGFloat = 40, yPad: CGFloat = 40
            let minX = (stars.map(\.x).min()! - xPad)
            let maxX = (stars.map(\.x).max()! + xPad)
            let minY = (stars.map(\.y).min()! - yPad)
            let maxY = (stars.map(\.y).max()! + yPad)
            let rangeX = max(maxX - minX, 1)
            let rangeY = max(maxY - minY, 1)

            let margin: CGFloat = 28
            let labelH: CGFloat = 70          // bottom space reserved for text
            let availW = size.width  - margin * 2
            let availH = size.height - margin - labelH
            let scale  = min(availW / rangeX, availH / rangeY)

            let ox = margin + (availW - rangeX * scale) / 2
            let oy = margin + (availH - rangeY * scale) / 2

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: ox + (x - minX) * scale, y: oy + (y - minY) * scale)
            }

            // ── Dashed edges (matching the app's dashed constellation lines) ──
            for e in edges {
                var path = Path()
                path.move(to: pt(e.ax, e.ay))
                path.addLine(to: pt(e.bx, e.by))
                // Soft glow under the dash
                ctx.stroke(path,
                           with: .color(.white.opacity(0.10)),
                           style: StrokeStyle(lineWidth: 3.5))
                // Dashed line
                ctx.stroke(path,
                           with: .color(.white.opacity(0.35)),
                           style: StrokeStyle(lineWidth: 1.0, dash: [5, 4]))
            }

            // ── 5-pointed stars ───────────────────────────────────────────────
            for star in stars {
                let c      = pt(star.x, star.y)
                let outer  = (star.size / 9) * 9.0 + 4.0   // 5.8–13 pt outer radius
                let inner  = outer * 0.42
                let locked = star.status == "locked"

                // Wide diffuse glow (circle)
                let gr = outer * 2.8
                ctx.fill(
                    Path(ellipseIn: CGRect(x: c.x - gr, y: c.y - gr, width: gr * 2, height: gr * 2)),
                    with: .color(star.glowColor)
                )

                // Tighter inner glow (circle)
                if !locked {
                    let ig = outer * 1.6
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: c.x - ig, y: c.y - ig, width: ig * 2, height: ig * 2)),
                        with: .color(star.coreColor.opacity(0.25))
                    )
                }

                // Star body
                ctx.fill(starPath(center: c, outer: outer, inner: inner),
                         with: .color(star.coreColor))

                // Bright white highlight at centre
                if !locked {
                    let hr = outer * 0.28
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: c.x - hr, y: c.y - hr, width: hr * 2, height: hr * 2)),
                        with: .color(.white.opacity(0.95))
                    )
                }
            }
        }
    }
}

// MARK: - Widget view

struct ConstellationWidgetView: View {
    let entry: ConstellationEntry
    private var mastery: Double { min(1, max(0, Double(entry.masteryPercent) / 100)) }

    var body: some View {
        ZStack(alignment: .bottom) {

            // Constellation fills the whole widget
            StarMapCanvas(stars: entry.stars, edges: entry.edges)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom labels — no gradient box, just layered text shadows
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.95), radius: 3, x: 0, y: 1)
                        .shadow(color: .black.opacity(0.80), radius: 10, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.60), radius: 20, x: 0, y: 4)
                        .lineLimit(1).minimumScaleFactor(0.75)
                    Text(entry.course)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .shadow(color: .black.opacity(0.95), radius: 3)
                        .shadow(color: .black.opacity(0.70), radius: 10)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.masteryPercent)%")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0xFFD700))
                        .shadow(color: .black.opacity(0.95), radius: 3)
                        .shadow(color: .black.opacity(0.70), radius: 10)
                    Text("mastered")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: 0xFFD700, opacity: 0.60))
                        .shadow(color: .black.opacity(0.90), radius: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .containerBackground(for: .widget) { spaceBackground }
    }

    // MARK: Background

    @ViewBuilder
    private var spaceBackground: some View {
        ZStack {
            // Deep blue-purple base
            LinearGradient(
                colors: [Color(hex: 0x0C0335), Color(hex: 0x04010F)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // Top-centre: violet nebula
            RadialGradient(
                colors: [Color(hex: 0x6B18E8, opacity: 0.52),
                         Color(hex: 0x3808A0, opacity: 0.20), .clear],
                center: UnitPoint(x: 0.45, y: 0.10),
                startRadius: 0, endRadius: 300
            )
            // Right: royal blue nebula
            RadialGradient(
                colors: [Color(hex: 0x1050FF, opacity: 0.40),
                         Color(hex: 0x0428B0, opacity: 0.14), .clear],
                center: UnitPoint(x: 0.92, y: 0.38),
                startRadius: 0, endRadius: 260
            )
            // Bottom-left: cyan accent
            RadialGradient(
                colors: [Color(hex: 0x10C0FF, opacity: 0.32),
                         Color(hex: 0x0680B8, opacity: 0.10), .clear],
                center: UnitPoint(x: 0.08, y: 0.88),
                startRadius: 0, endRadius: 230
            )
            // Centre: deep indigo pool
            RadialGradient(
                colors: [Color(hex: 0x0F28B0, opacity: 0.28), .clear],
                center: UnitPoint(x: 0.50, y: 0.52),
                startRadius: 0, endRadius: 400
            )
            // Top-right: magenta whisper
            RadialGradient(
                colors: [Color(hex: 0xD828A0, opacity: 0.20), .clear],
                center: UnitPoint(x: 0.90, y: 0.06),
                startRadius: 0, endRadius: 190
            )

            // Star field
            Canvas { ctx, size in
                var seed: UInt64 = 83_721
                func rand() -> Double {
                    seed = (seed &* 9301 &+ 49297) % 233280
                    return Double(seed) / 233280.0
                }
                // 130 tiny background stars
                for _ in 0..<130 {
                    let x = rand() * Double(size.width)
                    let y = rand() * Double(size.height)
                    let r = rand() * 0.9 + 0.2
                    let op = rand() * 0.55 + 0.15
                    let t = rand()
                    let col: Color = t > 0.80 ? Color(hex: 0xA8C8FF)
                                   : t > 0.65 ? Color(hex: 0xFFE8D0)
                                               : .white
                    ctx.fill(Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)),
                             with: .color(col.opacity(op)))
                }
                // 20 medium stars with halos
                for _ in 0..<20 {
                    let x = rand() * Double(size.width)
                    let y = rand() * Double(size.height)
                    let r = rand() * 1.4 + 0.8
                    let op = rand() * 0.4 + 0.45
                    let h = r * 3.5
                    ctx.fill(Path(ellipseIn: CGRect(x: x-h, y: y-h, width: h*2, height: h*2)),
                             with: .color(Color.white.opacity(0.06)))
                    ctx.fill(Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)),
                             with: .color(Color.white.opacity(op)))
                }
                // 7 bright sparkle stars
                for _ in 0..<7 {
                    let x = rand() * Double(size.width)
                    let y = rand() * Double(size.height)
                    let r = rand() * 1.8 + 1.5
                    let h = r * 5.5
                    ctx.fill(Path(ellipseIn: CGRect(x: x-h, y: y-h, width: h*2, height: h*2)),
                             with: .color(Color.white.opacity(0.07)))
                    ctx.fill(Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)),
                             with: .color(.white))
                    let arm = r * 5.0
                    var sp = Path()
                    sp.move(to: CGPoint(x: x-arm, y: y)); sp.addLine(to: CGPoint(x: x+arm, y: y))
                    sp.move(to: CGPoint(x: x, y: y-arm)); sp.addLine(to: CGPoint(x: x, y: y+arm))
                    ctx.stroke(sp, with: .color(Color.white.opacity(0.40)), lineWidth: 0.7)
                }
            }
        }
    }
}

// MARK: - Widget

@main
struct LAHacksWidget: Widget {
    let kind = "LAHacksConstellationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ConstellationProvider()) { entry in
            ConstellationWidgetView(entry: entry)
        }
        .configurationDisplayName("Constellation")
        .description("Shows your most recently explored constellation.")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    LAHacksWidget()
} timeline: {
    ConstellationEntry.preview
}
