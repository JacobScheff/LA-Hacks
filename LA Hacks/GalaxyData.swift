//
//  GalaxyData.swift
//  LA Hacks
//
//  Star Hop! Knowledge graph + design tokens. Ported from project/galaxy.jsx.
//

import SwiftUI

// MARK: - Color helpers

extension Color {
    init(hex rgb: UInt32, opacity: Double = 1.0) {
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double( rgb        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Mastery stages & color tokens

enum MasteryStage: String, Hashable {
    case locked, sleepy, twinkling, shining
}

struct StarPalette {
    let core: Color
    let mid: Color
    let halo: Color
    let glow: Color
    let label: String
}

struct StarParticle {
    let x: CGFloat
    let y: CGFloat
    let r: CGFloat
    let o: Double
    let tw: Double
    let td: Double
    let warm: Bool
    let animate: Bool
}

extension MasteryStage {
    var palette: StarPalette {
        switch self {
        case .shining:
            return StarPalette(
                core: Color(hex: 0xFFFCEB),
                mid:  Color(hex: 0xFFE066),
                halo: Color(hex: 0xFFB300),
                glow: Color(hex: 0xFFE066, opacity: 0.6),
                label: "Shining"
            )
        case .twinkling:
            return StarPalette(
                core: Color(hex: 0xFFF1FA),
                mid:  Color(hex: 0xFF8AD8),
                halo: Color(hex: 0xFF4FB6),
                glow: Color(hex: 0xFF8AD8, opacity: 0.55),
                label: "Twinkling"
            )
        case .sleepy:
            return StarPalette(
                core: Color(hex: 0xE8FAFF),
                mid:  Color(hex: 0x5EE7FF),
                halo: Color(hex: 0x22B8E0),
                glow: Color(hex: 0x5EE7FF, opacity: 0.5),
                label: "Sleepy"
            )
        case .locked:
            return StarPalette(
                core: Color(hex: 0xC7CDD9),
                mid:  Color(hex: 0x7B8294),
                halo: Color(hex: 0x4A5168),
                glow: Color(hex: 0x788296, opacity: 0.18),
                label: "Locked"
            )
        }
    }
}

// MARK: - Models

struct StarNode: Identifiable, Hashable {
    let id: String
    let label: String
    let constellationID: String
    /// Real star this node sits on (e.g. "Polaris", "Vega"). Optional for synthetic.
    let star: String?
    /// Kid-friendly emoji shown alongside the label.
    let emoji: String
    let x: CGFloat
    let y: CGFloat
    /// True = locked until a connected neighbor reaches Twinkling mastery.
    let initiallyLocked: Bool
    let size: CGFloat

    var point: CGPoint { CGPoint(x: x, y: y) }
}

struct Edge: Hashable {
    let a: String
    let b: String
}

struct Constellation: Identifiable, Hashable {
    let id: String
    let name: String
    let realName: String
    let nickname: String
    let emoji: String
    let course: String
    let blurb: String
    let skyStory: String
    let centroid: CGPoint
    let nodes: [StarNode]
    let edges: [Edge]

    var masteryAvg: Double {
        let settings = UserSettings.shared
        var neighborMap: [String: [String]] = [:]
        for e in edges {
            neighborMap[e.a, default: []].append(e.b)
            neighborMap[e.b, default: []].append(e.a)
        }
        let total = nodes.reduce(0.0) { sum, n in
            switch settings.stage(for: n.id, initiallyLocked: n.initiallyLocked, neighborIds: neighborMap[n.id] ?? []) {
            case .shining:   return sum + 1.0
            case .twinkling: return sum + 0.55
            case .sleepy:    return sum + 0.1
            case .locked:    return sum
            }
        }
        return total / Double(max(nodes.count, 1))
    }
}

// MARK: - Convex hull + bounding box

/// Graham scan — returns hull vertices in counter-clockwise order.
/// Falls back to the original points when fewer than 3 are provided.
func convexHull(of points: [CGPoint]) -> [CGPoint] {
    guard points.count >= 3 else { return points }
    let pivot = points.min { $0.y < $1.y || ($0.y == $1.y && $0.x < $1.x) }!
    let rest = points.filter { $0 != pivot }.sorted { a, b in
        let ta = atan2(a.y - pivot.y, a.x - pivot.x)
        let tb = atan2(b.y - pivot.y, b.x - pivot.x)
        if ta != tb { return ta < tb }
        return hypot(a.x - pivot.x, a.y - pivot.y) < hypot(b.x - pivot.x, b.y - pivot.y)
    }
    var hull = [pivot]
    for p in rest {
        while hull.count >= 2 {
            let a = hull[hull.count - 2], b = hull.last!
            let cross = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
            if cross <= 0 { hull.removeLast() } else { break }
        }
        hull.append(p)
    }
    return hull
}

extension Constellation {
    func boundingRect(padding: CGFloat = 80) -> CGRect {
        let pts = nodes.map(\.point)
        let hull = convexHull(of: pts)
        let verts = hull.isEmpty ? pts : hull
        guard !verts.isEmpty else { return .zero }
        let minX = verts.map(\.x).min()! - padding
        let minY = verts.map(\.y).min()! - padding
        let maxX = verts.map(\.x).max()! + padding
        let maxY = verts.map(\.y).max()! + padding
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - Constellation data

enum GalaxyData {
    static let SKY_W: CGFloat = 1000
    static let SKY_H: CGFloat = 1600

    static let constellations: [Constellation] = [
        // Ursa Major / Big Dipper → MATH BASICS
        Constellation(
            id: "numbers",
            name: "Number Land",
            realName: "Ursa Major · the Great Bear",
            nickname: "The Big Dipper",
            emoji: "🐻",
            course: "Math · Grades 3–4",
            blurb: "Where counting starts! Add, subtract, and zoom through times tables.",
            skyStory: "The Big Dipper is the easiest constellation to find — its 7 bright stars look like a soup ladle scooping the sky.",
            centroid: CGPoint(x: 250, y: 300),
            nodes: [
                StarNode(id: "count", label: "Counting",     star: "Dubhe",  emoji: "👆", x: 360, y: 240, initiallyLocked: false, status: .mastered, size: 7, mastery: nil),
                StarNode(id: "place", label: "Place Value",  star: "Merak",  emoji: "🏠", x: 350, y: 310, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
                StarNode(id: "add",   label: "Adding",       star: "Phecda", emoji: "➕", x: 290, y: 320, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
                StarNode(id: "sub",   label: "Subtracting",  star: "Megrez", emoji: "➖", x: 280, y: 270, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "mul",   label: "Times Tables", star: "Alioth", emoji: "✖️", x: 220, y: 260, initiallyLocked: false, status: .mastered, size: 7, mastery: nil),
                StarNode(id: "div",   label: "Sharing (÷)",  star: "Mizar",  emoji: "➗", x: 165, y: 245, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
                StarNode(id: "odd",   label: "Odd & Even",   star: "Alkaid", emoji: "👯", x: 110, y: 220, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
            ],
            edges: [
                Edge(a:"count",b:"place"), Edge(a:"place",b:"add"), Edge(a:"add",b:"sub"), Edge(a:"sub",b:"count"),
                Edge(a:"sub",b:"mul"), Edge(a:"mul",b:"div"), Edge(a:"div",b:"odd"),
            ]
        ),
        // Orion → FRACTIONS
        Constellation(
            id: "fractions",
            name: "Pizza Planet",
            realName: "Orion · the Hunter",
            nickname: "Orion's Belt",
            emoji: "🍕",
            course: "Math · Grades 4–5",
            blurb: "Slice the pizza, share the cake! Fractions cut things into fair pieces. Zorblix loves adding slices.",
            skyStory: "Orion the Hunter strides across winter skies. His belt — three bright stars in a row — is the most famous line in the heavens.",
            centroid: CGPoint(x: 600, y: 340),
            nodes: [
                // Betelgeuse is upper-LEFT (α Ori), Rigel lower-RIGHT (β Ori, brightest in Orion).
                // Belt runs left-to-right: Alnitak → Alnilam → Mintaka.
                StarNode(id: "half",     label: "Halves & Quarters",  star: "Betelgeuse", emoji: "🍰", x: 530, y: 250, initiallyLocked: false, status: .mastered, size: 9, mastery: nil),
                StarNode(id: "frac",     label: "Reading Fractions",  star: "Bellatrix",  emoji: "📖", x: 660, y: 260, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
                StarNode(id: "equiv",    label: "Equal Fractions",    star: "Alnitak",    emoji: "🟰", x: 540, y: 340, initiallyLocked: false, status: .learning, size: 5, mastery: 0.65),
                StarNode(id: "compare",  label: "Bigger or Smaller?", star: "Alnilam",    emoji: "⚖️", x: 600, y: 340, initiallyLocked: false, status: .learning, size: 6, mastery: 0.5),
                StarNode(id: "addfrac",  label: "Adding Slices",      star: "Mintaka",    emoji: "🍕", x: 660, y: 340, initiallyLocked: false, status: .gap,      size: 5, mastery: 0.28),
                StarNode(id: "mixed",    label: "Mixed Numbers",      star: "Hatysa",     emoji: "🥧", x: 600, y: 400, initiallyLocked: false, status: .gap,      size: 4, mastery: 0.18),
                StarNode(id: "simplify", label: "Simplifying",        star: "Saiph",      emoji: "✂️", x: 530, y: 460, initiallyLocked: false, status: .gap,      size: 5, mastery: 0.22),
                StarNode(id: "word",     label: "Word Problems",      star: "Rigel",      emoji: "🧩", x: 670, y: 470, initiallyLocked: true,  status: .locked, size: 9, mastery: nil),
            ],
            edges: [
                Edge(a:"half",b:"equiv"), Edge(a:"frac",b:"addfrac"),
                Edge(a:"equiv",b:"compare"), Edge(a:"compare",b:"addfrac"),
                Edge(a:"compare",b:"mixed"),
                Edge(a:"equiv",b:"simplify"), Edge(a:"addfrac",b:"word"),
            ]
        ),
        // Cassiopeia → GEOMETRY
        Constellation(
            id: "shapes",
            name: "Shape City",
            realName: "Cassiopeia · the Queen",
            nickname: "The Sky W",
            emoji: "🔷",
            course: "Geometry · Grades 3–5",
            blurb: "Triangles, squares, circles — the building blocks of EVERYTHING.",
            skyStory: "Cassiopeia looks like a giant W (or M, when it flips upside down). Five bright stars zig-zag across the northern sky like a queen's crown.",
            centroid: CGPoint(x: 235, y: 600),
            nodes: [
                StarNode(id: "tri",   label: "Triangles", star: "Caph",      emoji: "🔺", x: 130, y: 540, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
                StarNode(id: "sq",    label: "Squares",   star: "Schedar",   emoji: "🟦", x: 180, y: 620, initiallyLocked: false, status: .mastered, size: 7, mastery: nil),
                StarNode(id: "circ",  label: "Circles",   star: "Gamma Cas", emoji: "⭕", x: 235, y: 540, initiallyLocked: false, status: .mastered, size: 7, mastery: nil),
                StarNode(id: "poly",  label: "Polygons",  star: "Ruchbah",   emoji: "🔶", x: 290, y: 620, initiallyLocked: false, status: .learning, size: 6, mastery: 0.7),
                StarNode(id: "sym",   label: "Symmetry",  star: "Segin",     emoji: "🦋", x: 345, y: 535, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "angle", label: "Angles",    star: "Achird",    emoji: "📐", x: 220, y: 700, initiallyLocked: false, status: .learning, size: 4, mastery: 0.55),
                StarNode(id: "area",  label: "Area",      star: "Marfak",    emoji: "🟩", x: 130, y: 700,      initiallyLocked: false, status: .gap,      size: 4, mastery: 0.3),
                StarNode(id: "vol",   label: "Volume",    star: "Fulu",      emoji: "🧊", x: 320, y: 720,      initiallyLocked: false, status: .gap,      size: 4, mastery: 0.2),
            ],
            edges: [
                Edge(a:"tri",b:"sq"), Edge(a:"sq",b:"circ"), Edge(a:"circ",b:"poly"), Edge(a:"poly",b:"sym"),
                Edge(a:"sq",b:"area"), Edge(a:"poly",b:"angle"), Edge(a:"poly",b:"vol"),
            ]
        ),
        // Leo → TIME & MONEY
        Constellation(
            id: "time",
            name: "Clock Cove",
            realName: "Leo · the Lion",
            nickname: "The Sickle",
            emoji: "🦁",
            course: "Practical Math · Grades 2–3",
            blurb: "Tell time, count coins, and make change like a pro shopkeeper.",
            skyStory: "Leo's head is a backward question-mark called the Sickle. Its heart-star Regulus is one of the brightest in the spring sky.",
            centroid: CGPoint(x: 720, y: 600),
            nodes: [
                StarNode(id: "clock",    label: "Reading Clocks",  star: "Regulus",     emoji: "🕒", x: 700, y: 620, initiallyLocked: false, status: .mastered, size: 8, mastery: nil),
                StarNode(id: "min",      label: "Hours & Minutes", star: "Eta Leonis",  emoji: "⏱️", x: 700, y: 560, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "cal",      label: "Calendar",        star: "Algieba",     emoji: "📅", x: 720, y: 510, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
                StarNode(id: "elapsed",  label: "How Long?",       star: "Adhafera",    emoji: "⌛", x: 760, y: 470, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "rasalas",  label: "AM vs PM",        star: "Rasalas",     emoji: "🌗", x: 800, y: 480, initiallyLocked: false, status: .mastered, size: 4, mastery: nil),
                StarNode(id: "algenubi", label: "Time Words",      star: "Algenubi",    emoji: "💬", x: 815, y: 530, initiallyLocked: false, status: .mastered, size: 4, mastery: nil),
                StarNode(id: "coins",    label: "Coins",           star: "Chertan",     emoji: "🪙", x: 800, y: 640, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "change",   label: "Making Change",   star: "Zosma",       emoji: "💱", x: 820, y: 600, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "dollar",   label: "Dollars & Cents", star: "Denebola",    emoji: "💵", x: 880, y: 670, initiallyLocked: false, status: .mastered, size: 7, mastery: nil),
            ],
            edges: [
                Edge(a:"clock",b:"min"), Edge(a:"min",b:"cal"), Edge(a:"cal",b:"elapsed"),
                Edge(a:"elapsed",b:"rasalas"), Edge(a:"rasalas",b:"algenubi"),
                Edge(a:"clock",b:"coins"), Edge(a:"coins",b:"change"), Edge(a:"change",b:"dollar"), Edge(a:"coins",b:"dollar"),
            ]
        ),
        // Lyra → READING
        Constellation(
            id: "reading",
            name: "Story Shore",
            realName: "Lyra · the Harp",
            nickname: "Vega's Parallelogram",
            emoji: "📚",
            course: "Reading · Grades 3–5",
            blurb: "From letters to legends! Reading is your ticket anywhere a book can take you.",
            skyStory: "Lyra is a tiny constellation but it holds Vega — the 5th brightest star in our whole night sky. Below Vega, four stars form a perfect parallelogram, like a little harp.",
            centroid: CGPoint(x: 220, y: 940),
            nodes: [
                StarNode(id: "phon",    label: "Phonics",         star: "Vega",          emoji: "🔤", x: 220, y: 850, initiallyLocked: false, status: .mastered, size: 9, mastery: nil),
                StarNode(id: "sight",   label: "Sight Words",     star: "Epsilon Lyrae", emoji: "👀", x: 270, y: 880, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "flu",     label: "Smooth Reading",  star: "Zeta Lyrae",    emoji: "🌊", x: 170, y: 900, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "main",    label: "Main Idea",       star: "Sheliak",       emoji: "💡", x: 175, y: 970, initiallyLocked: false, status: .learning, size: 6, mastery: 0.6),
                StarNode(id: "detail",  label: "Key Details",     star: "Sulafat",       emoji: "🔍", x: 290, y: 990, initiallyLocked: false, status: .learning, size: 6, mastery: 0.55),
                StarNode(id: "infer",   label: "Reading Clues",   star: "Delta Lyrae",   emoji: "🕵️", x: 270, y: 1050,      initiallyLocked: false, status: .gap,      size: 5, mastery: 0.3),
                StarNode(id: "theme",   label: "Theme",           star: "Aladfar",       emoji: "🎭", x: 155, y: 1030,      initiallyLocked: false, status: .gap,      size: 4, mastery: 0.2),
            ],
            edges: [
                Edge(a:"phon",b:"sight"), Edge(a:"phon",b:"flu"),
                Edge(a:"main",b:"detail"), Edge(a:"detail",b:"infer"), Edge(a:"infer",b:"theme"), Edge(a:"theme",b:"main"),
                Edge(a:"flu",b:"main"), Edge(a:"sight",b:"detail"),
            ]
        ),
        // Cygnus → WRITING
        Constellation(
            id: "writing",
            name: "Inkwell Isle",
            realName: "Cygnus · the Swan",
            nickname: "The Northern Cross",
            emoji: "✏️",
            course: "Writing · Grades 3–5",
            blurb: "Sentences, stories, and silly poems. Every author starts with one capital letter.",
            skyStory: "Cygnus the Swan flies along the Milky Way. Its 5 brightest stars form a neat cross — sometimes called the Northern Cross.",
            centroid: CGPoint(x: 540, y: 920),
            nodes: [
                StarNode(id: "caps",  label: "Caps & Periods",  star: "Deneb",     emoji: "🔠", x: 540, y: 820, initiallyLocked: false, status: .mastered, size: 8, mastery: nil),
                StarNode(id: "noun",  label: "Nouns & Verbs",   star: "Sadr",      emoji: "🐶", x: 540, y: 920, initiallyLocked: false, status: .mastered, size: 7, mastery: nil),
                StarNode(id: "sent",  label: "Full Sentences",  star: "Albireo",   emoji: "📝", x: 540, y: 1030, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
                StarNode(id: "adj",   label: "Adjectives",      star: "Gienah",    emoji: "🌈", x: 460, y: 920, initiallyLocked: false, status: .learning, size: 6, mastery: 0.6),
                StarNode(id: "para",  label: "Paragraphs",      star: "Delta Cyg", emoji: "📄", x: 620, y: 920, initiallyLocked: false, status: .learning, size: 6, mastery: 0.55),
                StarNode(id: "story", label: "Story Building",  star: "Aljanah",   emoji: "🏰", x: 410, y: 870,      initiallyLocked: false, status: .gap,      size: 5, mastery: 0.25),
                StarNode(id: "opin",  label: "My Opinion",      star: "Iota Cyg",  emoji: "💭", x: 660, y: 870,      initiallyLocked: false, status: .gap,      size: 4, mastery: 0.2),
                StarNode(id: "edit",  label: "Editing",         star: "Kappa Cyg", emoji: "🧹", x: 480, y: 1000,      initiallyLocked: false, status: .gap,      size: 4, mastery: 0.15),
            ],
            edges: [
                Edge(a:"caps",b:"noun"), Edge(a:"noun",b:"sent"),
                Edge(a:"adj",b:"noun"), Edge(a:"noun",b:"para"),
                Edge(a:"adj",b:"story"), Edge(a:"para",b:"opin"),
                Edge(a:"sent",b:"edit"),
            ]
        ),
        // Scorpius → LIFE SCIENCE
        Constellation(
            id: "life",
            name: "Critter Cove",
            realName: "Scorpius · the Scorpion",
            nickname: "Antares' Curl",
            emoji: "🦂",
            course: "Science · Grades 4–5",
            blurb: "Plants, animals, and the tiny invisible critters all sharing our world.",
            skyStory: "Scorpius is one of the few constellations that REALLY looks like the thing it's named for — a curling scorpion with a fiery red heart-star, Antares.",
            centroid: CGPoint(x: 820, y: 280),
            nodes: [
                StarNode(id: "living",  label: "Living vs Not",  star: "Graffias",    emoji: "🌱", x: 720, y: 150, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
                StarNode(id: "plant",   label: "Plant Parts",    star: "Dschubba",    emoji: "🌻", x: 780, y: 175, initiallyLocked: false, status: .mastered, size: 6, mastery: nil),
                StarNode(id: "animal",  label: "Animal Groups",  star: "Pi Sco",      emoji: "🦁", x: 840, y: 165, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "habitat", label: "Habitats",       star: "Antares",     emoji: "🌳", x: 800, y: 260, initiallyLocked: false, status: .learning, size: 9, mastery: 0.7),
                // Sigma Sco sits directly below Antares in the body chain, not off to the side.
                StarNode(id: "food",    label: "Food Chains",    star: "Sigma Sco",   emoji: "🦊", x: 800, y: 310, initiallyLocked: false, status: .learning, size: 5, mastery: 0.55),
                StarNode(id: "cycle",   label: "Life Cycles",    star: "Tau Sco",     emoji: "🦋", x: 830, y: 330,      initiallyLocked: false, status: .gap,      size: 5, mastery: 0.3),
                StarNode(id: "eco",     label: "Ecosystems",     star: "Epsilon Sco", emoji: "🐝", x: 870, y: 390,      initiallyLocked: false, status: .gap,      size: 5, mastery: 0.2),
                StarNode(id: "photo",   label: "Photosynthesis", star: "Mu Sco",      emoji: "☀️", x: 900, y: 450,   initiallyLocked: true, status: .locked,   size: 4, mastery: nil),
                StarNode(id: "zeta",    label: "Cells",          star: "Zeta Sco",    emoji: "🔬", x: 880, y: 510,   initiallyLocked: true, status: .locked,   size: 5, mastery: nil),
                StarNode(id: "shaula",  label: "Adaptations",    star: "Shaula",      emoji: "🐾", x: 820, y: 540,   initiallyLocked: true, status: .locked,   size: 7, mastery: nil),
                StarNode(id: "lesath",  label: "Stinger Facts",  star: "Lesath",      emoji: "⚡", x: 800, y: 510,   initiallyLocked: true, status: .locked,   size: 4, mastery: nil),
            ],
            edges: [
                Edge(a:"living",b:"plant"), Edge(a:"plant",b:"animal"),
                Edge(a:"plant",b:"habitat"), Edge(a:"animal",b:"habitat"),
                // Single body chain: Antares → σ → τ → ε → μ → ζ → stinger
                Edge(a:"habitat",b:"food"), Edge(a:"food",b:"cycle"),
                Edge(a:"cycle",b:"eco"), Edge(a:"eco",b:"photo"),
                Edge(a:"photo",b:"zeta"), Edge(a:"zeta",b:"lesath"), Edge(a:"lesath",b:"shaula"), Edge(a:"zeta",b:"shaula"),
            ]
        ),
        // Ursa Minor / Little Dipper → EARTH & SPACE
        Constellation(
            id: "earth",
            name: "Sky & Space",
            realName: "Ursa Minor · the Little Bear",
            nickname: "The Little Dipper",
            emoji: "🪐",
            course: "Science · Grades 4–5",
            blurb: "Earth, Moon, Sun, and everything that swirls in between. Buckle up!",
            skyStory: "The Little Dipper has Polaris — the North Star — at the tip of its handle. It barely moves all night, so sailors have used it to find their way for thousands of years.",
            centroid: CGPoint(x: 800, y: 1010),
            nodes: [
                StarNode(id: "sun",     label: "Sun, Earth, Moon", star: "Polaris",     emoji: "🌞", x: 720, y: 920, initiallyLocked: false, status: .mastered, size: 8, mastery: nil),
                StarNode(id: "season",  label: "Seasons",          star: "Yildun",      emoji: "🍁", x: 770, y: 950, initiallyLocked: false, status: .learning, size: 5, mastery: 0.6),
                StarNode(id: "weather", label: "Weather",          star: "Epsilon UMi", emoji: "⛅", x: 820, y: 985, initiallyLocked: false, status: .learning, size: 5, mastery: 0.65),
                StarNode(id: "water",   label: "Water Cycle",      star: "Zeta UMi",    emoji: "💧", x: 840, y: 1030,      initiallyLocked: false, status: .gap,      size: 5, mastery: 0.3),
                StarNode(id: "rocks",   label: "Rocks & Minerals", star: "Eta UMi",     emoji: "🪨", x: 900, y: 1040,      initiallyLocked: false, status: .gap,      size: 4, mastery: 0.2),
                StarNode(id: "planet",  label: "Planets",          star: "Pherkad",     emoji: "🪐", x: 920, y: 1100,      initiallyLocked: false, status: .gap,      size: 6, mastery: 0.25),
                StarNode(id: "gravity", label: "Gravity",          star: "Kochab",      emoji: "🍎", x: 850, y: 1140,   initiallyLocked: true, status: .locked,   size: 7, mastery: nil),
                StarNode(id: "galaxy",  label: "Stars & Galaxies", star: "Zeta UMi B",  emoji: "🌌", x: 780, y: 1080,   initiallyLocked: true, status: .locked,   size: 4, mastery: nil),
            ],
            edges: [
                Edge(a:"sun",b:"season"), Edge(a:"season",b:"weather"), Edge(a:"weather",b:"water"),
                Edge(a:"water",b:"rocks"), Edge(a:"rocks",b:"planet"), Edge(a:"planet",b:"gravity"),
                Edge(a:"gravity",b:"galaxy"), Edge(a:"galaxy",b:"water"),
            ]
        ),
        // Draco → HISTORY
        Constellation(
            id: "history",
            name: "Time Travel Trail",
            realName: "Draco · the Dragon",
            nickname: "The Dragon's Tail",
            emoji: "🐉",
            course: "Social Studies · Grades 4–5",
            blurb: "How people lived long ago, and how their stories shaped our own.",
            skyStory: "Draco the Dragon coils its long tail right between the two Dippers. 5,000 years ago its star Thuban was the North Star — the one Egyptian pyramid builders pointed to.",
            centroid: CGPoint(x: 470, y: 1240),
            nodes: [
                StarNode(id: "ancient",  label: "Ancient Peoples",  star: "Eltanin",      emoji: "🏛️", x: 350, y: 1100, initiallyLocked: false, status: .mastered, size: 7, mastery: nil),
                StarNode(id: "rastaban", label: "Sky Stories",      star: "Rastaban",     emoji: "✨",  x: 320, y: 1140, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "maps",     label: "Reading Maps",     star: "Grumium",      emoji: "🧭", x: 380, y: 1140, initiallyLocked: false, status: .mastered, size: 5, mastery: nil),
                StarNode(id: "nu",       label: "Time Lines",       star: "Nu Draconis",  emoji: "📜", x: 350, y: 1160, initiallyLocked: false, status: .mastered, size: 4, mastery: nil),
                StarNode(id: "native",   label: "Native Peoples",   star: "Altais",       emoji: "🪶", x: 420, y: 1190, initiallyLocked: false, status: .learning, size: 6, mastery: 0.6),
                StarNode(id: "explor",   label: "Explorers",        star: "Aldhibah",     emoji: "⛵", x: 480, y: 1230, initiallyLocked: false, status: .learning, size: 5, mastery: 0.55),
                StarNode(id: "colony",   label: "Long-Ago Towns",   star: "Edasich",      emoji: "🏘️", x: 540, y: 1260,      initiallyLocked: false, status: .gap,      size: 5, mastery: 0.3),
                StarNode(id: "rev",      label: "Big Changes",      star: "Thuban",       emoji: "🔔", x: 580, y: 1310,      initiallyLocked: false, status: .gap,      size: 6, mastery: 0.2),
                StarNode(id: "gov",      label: "How Gov Works",    star: "Kappa Dra",    emoji: "🏛️", x: 540, y: 1360,      initiallyLocked: false, status: .gap,      size: 4, mastery: 0.25),
                StarNode(id: "civil",    label: "Fairness for All", star: "Giausar",      emoji: "🤝", x: 460, y: 1380,   initiallyLocked: true, status: .locked,   size: 4, mastery: nil),
                StarNode(id: "tail",     label: "Stories Today",    star: "Tail of Draco",emoji: "📰", x: 400, y: 1340,   initiallyLocked: true, status: .locked,   size: 4, mastery: nil),
            ],
            edges: [
                Edge(a:"ancient",b:"rastaban"), Edge(a:"ancient",b:"maps"), Edge(a:"rastaban",b:"nu"), Edge(a:"maps",b:"nu"),
                Edge(a:"nu",b:"native"), Edge(a:"native",b:"explor"), Edge(a:"explor",b:"colony"), Edge(a:"colony",b:"rev"),
                Edge(a:"rev",b:"gov"), Edge(a:"gov",b:"civil"), Edge(a:"civil",b:"tail"),
            ]
        ),
    ]

    static let bridges: [Edge] = [
        Edge(a:"mul",b:"area"), Edge(a:"div",b:"equiv"), Edge(a:"add",b:"coins"), Edge(a:"sub",b:"change"),
        Edge(a:"frac",b:"dollar"), Edge(a:"poly",b:"habitat"), Edge(a:"main",b:"story"), Edge(a:"detail",b:"para"),
        Edge(a:"weather",b:"habitat"), Edge(a:"sun",b:"season"), Edge(a:"maps",b:"habitat"), Edge(a:"ancient",b:"story"),
    ]

    /// All nodes flattened by id, with constellation info attached.
    static let nodesById: [String: (node: StarNode, constellationId: String, constellationName: String, constellationEmoji: String)] = {
        var out: [String: (StarNode, String, String, String)] = [:]
        for c in constellations {
            for n in c.nodes {
                out[n.id] = (n, c.id, c.name, c.emoji)
            }
        }
        return out
    }()

    /// Distant background dust — deterministic LCG so rebuilds match.
    static let backdropStars: [(x: CGFloat, y: CGFloat, r: CGFloat, o: Double, tw: Double, td: Double)] = {
        var seed: UInt64 = 7
        func rand() -> Double {
            seed = (seed &* 9301 &+ 49297) % 233280
            return Double(seed) / 233280.0
        }
        var out: [(CGFloat, CGFloat, CGFloat, Double, Double, Double)] = []
        out.reserveCapacity(320)
        for _ in 0..<320 {
            let x = CGFloat(rand()) * SKY_W
            let y = CGFloat(rand()) * SKY_H
            let r = CGFloat(rand() * 1.2 + 0.3)
            let o = rand() * 0.6 + 0.2
            let tw = rand() * 4 + 2
            let td = rand() * 4
            out.append((x, y, r, o, tw, td))
        }
        return out
    }()

    /// Three-layer parallax star field matching design's STAR_LAYERS.
    static let starLayers: (far: [StarParticle], mid: [StarParticle], near: [StarParticle]) = {
        var seed: UInt64 = 13
        func rand() -> Double {
            seed = (seed &* 9301 &+ 49297) % 233280
            return Double(seed) / 233280.0
        }
        func make(_ count: Int, rMin: Double, rMax: Double, oMin: Double, oMax: Double, animate: Bool) -> [StarParticle] {
            var arr = [StarParticle]()
            arr.reserveCapacity(count)
            for _ in 0..<count {
                arr.append(StarParticle(
                    x: CGFloat(rand() * 1600 - 300),
                    y: CGFloat(rand() * 2600 - 500),
                    r: CGFloat(rand() * (rMax - rMin) + rMin),
                    o: rand() * (oMax - oMin) + oMin,
                    tw: rand() * 5 + 2,
                    td: rand() * 6,
                    warm: rand() > 0.7,
                    animate: animate
                ))
            }
            return arr
        }
        return (
            far:  make(1200, rMin: 0.12, rMax: 0.55, oMin: 0.10, oMax: 0.38, animate: false),
            mid:  make(500,  rMin: 0.4,  rMax: 1.1,  oMin: 0.38, oMax: 0.68, animate: true),
            near: make(140,  rMin: 1.1,  rMax: 2.4,  oMin: 0.65, oMax: 1.0,  animate: true)
        )
    }()

}
