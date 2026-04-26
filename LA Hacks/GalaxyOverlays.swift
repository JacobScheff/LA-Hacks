//
//  GalaxyOverlays.swift
//  LA Hacks
//
//  Star Hop! TrainingOverlay (Quest start) + ConstellationModal.
//  Ported from project/galaxy-ui.jsx.
//

import SwiftUI

// MARK: - Quest data

private struct QuestEntry {
    let objectives: [String]
    let nova: String
    let xp: Int
    let time: Int
}

private enum QuestData {
    static func entry(for id: String) -> QuestEntry {
        return lookup[id] ?? QuestEntry(
            objectives: ["Explore this topic", "Answer practice questions", "Earn XP"],
            nova: "Let's dive in together — I'll guide you every step of the way!",
            xp: 80, time: 10
        )
    }

    // swiftlint:disable line_length
    private static let lookup: [String: QuestEntry] = [
        "count":   QuestEntry(objectives: ["Count objects up to 100", "Skip-count by 2s, 5s & 10s", "Find the missing number in a sequence"], nova: "Counting is your very first superpower. Once you nail it, ALL of maths clicks into place!", xp: 80, time: 10),
        "place":   QuestEntry(objectives: ["Know what each digit means", "Build numbers using hundreds, tens & ones", "Compare big numbers using place value"], nova: "Place value is like a secret address for every digit. The 3 in 307 means 300, not 3!", xp: 85, time: 10),
        "add":     QuestEntry(objectives: ["Add two 2-digit numbers together", "Carry (regroup) when the ones add past 9", "Solve addition word problems"], nova: "Adding is like packing your spaceship — the more you load in, the bigger the total!", xp: 90, time: 12),
        "sub":     QuestEntry(objectives: ["Subtract with and without borrowing", "Solve take-away word problems", "Check answers by adding back"], nova: "Subtraction is just addition in reverse! If you know 4 + 5 = 9, then 9 − 5 = 4 too!", xp: 90, time: 12),
        "mul":     QuestEntry(objectives: ["Recite times tables up to 12×12", "Use skip-counting to multiply fast", "Solve multiplication word problems"], nova: "Times tables are the rocket fuel of maths. Memorise them once and they power EVERYTHING!", xp: 100, time: 14),
        "div":     QuestEntry(objectives: ["Divide by sharing into equal groups", "Link division to multiplication facts", "Deal with remainders"], nova: "Division is just multiplication backwards. 42 ÷ 6? Just ask: what times 6 makes 42?", xp: 100, time: 12),
        "odd":     QuestEntry(objectives: ["Tell odd numbers from even numbers", "Use patterns to predict odd/even", "Apply rules to big numbers"], nova: "Even numbers can always be split into TWO equal groups. Odd ones always have a leftover!", xp: 60, time: 8),
        "half":    QuestEntry(objectives: ["Identify halves and quarters of shapes", "Split objects into equal parts", "Write ½ and ¼ correctly"], nova: "A fraction is just a fair share! ½ means you and a friend split something perfectly equally.", xp: 75, time: 10),
        "frac":    QuestEntry(objectives: ["Read fractions like 3/5 out loud", "Identify the numerator and denominator", "Shade fractions of shapes"], nova: "The bottom number (denominator) says how many slices. The top (numerator) says how many you get!", xp: 75, time: 10),
        "equiv":   QuestEntry(objectives: ["Find equivalent fractions by multiplying", "Simplify fractions by dividing", "Spot equivalents on a number line"], nova: "½ = 2/4 = 4/8 — they look different but they're the SAME slice of the same pizza. Mind = blown!", xp: 90, time: 12),
        "compare": QuestEntry(objectives: ["Compare fractions with the same denominator", "Order fractions smallest to biggest", "Use < > = between fractions"], nova: "When the bottom numbers match, more slices always wins. 5/8 beats 3/8 — easy!", xp: 85, time: 10),
        "addfrac": QuestEntry(objectives: ["Add fractions with matching denominators", "Simplify fraction answers", "Solve fraction word problems"], nova: "Same denominators? Just add the tops and keep the bottom. 2/7 + 3/7 = 5/7. Done!", xp: 90, time: 12),
        "mixed":   QuestEntry(objectives: ["Convert between mixed numbers and improper fractions", "Add mixed numbers", "Spot mixed numbers in the real world"], nova: "1¾ is a mixed number — a whole number AND a fraction living together in harmony!", xp: 95, time: 14),
        "simplify":QuestEntry(objectives: ["Find the GCF of numerator and denominator", "Simplify fractions to lowest terms", "Check if a fraction is already simplified"], nova: "Simplifying is like tidying your room — same amount of stuff, just neater. 4/8 → 1/2 ✨", xp: 90, time: 12),
        "word":    QuestEntry(objectives: ["Identify what a fraction problem is asking", "Choose the right operation", "Check answers make sense"], nova: "Word problems are just maths wearing a disguise. Read slowly and the numbers will appear!", xp: 110, time: 16),
        "tri":     QuestEntry(objectives: ["Name and classify triangles by sides", "Count angles and vertices", "Calculate the perimeter of a triangle"], nova: "Triangles are the STRONGEST shape in nature — bridges, rooftops and pyramids all use them!", xp: 75, time: 10),
        "sq":      QuestEntry(objectives: ["Identify squares and their properties", "Calculate perimeter using side length", "Tell squares from rectangles"], nova: "A square is a very special rectangle — all four sides are EXACTLY the same length. Perfect!", xp: 70, time: 8),
        "circ":    QuestEntry(objectives: ["Name radius, diameter and circumference", "Understand π (pi) roughly", "Identify circles in real life"], nova: "Every point on a circle's edge is EXACTLY the same distance from the centre. Pretty magical!", xp: 75, time: 10),
        "poly":    QuestEntry(objectives: ["Name polygons up to 10 sides", "Count vertices and sides", "Classify regular vs irregular"], nova: "Hexa means 6, Octo means 8 — knowing Greek prefixes lets you name ANY polygon instantly!", xp: 80, time: 10),
        "sym":     QuestEntry(objectives: ["Identify lines of symmetry", "Reflect shapes across an axis", "Count symmetry lines in regular polygons"], nova: "Symmetry is everywhere — butterfly wings, faces, snowflakes. Maths is just describing nature!", xp: 70, time: 8),
        "angle":   QuestEntry(objectives: ["Classify right, acute and obtuse angles", "Measure angles with a protractor", "Spot angles inside shapes"], nova: "A right angle is EXACTLY 90°. Acute is smaller (sharp!), obtuse is bigger (wide and relaxed).", xp: 85, time: 12),
        "area":    QuestEntry(objectives: ["Count square units inside shapes", "Use the length × width formula", "Solve real-world area problems"], nova: "Area answers: how much carpet do I need? How much paint? It's maths that helps you decorate!", xp: 90, time: 12),
        "vol":     QuestEntry(objectives: ["Count unit cubes in a 3D shape", "Use length × width × height", "Compare volumes of different shapes"], nova: "Volume is area's 3D cousin. How much fits INSIDE the box? That's volume!", xp: 95, time: 12),
        "clock":   QuestEntry(objectives: ["Read analogue clocks to the minute", "Write times in digital format", "Draw hands on a blank clock face"], nova: "The short hand points to the hour, the long hand counts the minutes. Together they rule time!", xp: 70, time: 10),
        "min":     QuestEntry(objectives: ["Convert between hours and minutes", "Calculate time differences", "Add and subtract time amounts"], nova: "60 minutes = 1 hour. Once you know that, you can jump between any units of time!", xp: 75, time: 10),
        "cal":     QuestEntry(objectives: ["Read a monthly calendar", "Calculate days between two dates", "Name months and their days in order"], nova: "Calendars are just number grids with personality. Maths helps you plan your whole year!", xp: 65, time: 8),
        "elapsed": QuestEntry(objectives: ["Find how long something took", "Count forward or backward on a timeline", "Solve 'how long until…' problems"], nova: "Elapsed time = end time minus start time. It's the maths of life — how long until lunch? 😄", xp: 80, time: 10),
        "coins":   QuestEntry(objectives: ["Identify every coin and its value", "Count mixed collections of coins", "Find the fewest coins for an amount"], nova: "Skip-count to count coins fast: 25, 50, 75… Quarters are your best friends!", xp: 70, time: 10),
        "change":  QuestEntry(objectives: ["Subtract to find change from a purchase", "Count up from price to amount paid", "Check change from $1, $5 and $10"], nova: "Shopkeepers count UP to give change — not down. Try it: pay $1, item costs 73¢ → 74, 75, $1!", xp: 80, time: 12),
        "dollar":  QuestEntry(objectives: ["Write amounts using $ and ¢ notation", "Convert between dollars and cents", "Add and subtract money amounts"], nova: "$1.00 = 100 cents. The decimal point separates dollars (left) from cents (right). Easy notation!", xp: 75, time: 10),
        "main":    QuestEntry(objectives: ["Find the main idea of any passage", "Tell main idea apart from supporting details", "Write a one-sentence summary"], nova: "The main idea is the BIG message. Everything else in the text is just evidence supporting it!", xp: 80, time: 12),
        "detail":  QuestEntry(objectives: ["Spot key details in a text", "Match details to the main idea", "Use details to answer questions precisely"], nova: "Details are the clues that prove the main idea. Good readers collect them like treasure! 🔍", xp: 75, time: 10),
        "infer":   QuestEntry(objectives: ["Read between the lines for meaning", "Use text clues to make predictions", "Explain your evidence from the text"], nova: "Inferring is detective work! The author doesn't always TELL you — sometimes you have to FIGURE it out.", xp: 85, time: 12),
        "caps":    QuestEntry(objectives: ["Capitalise sentence-starting words", "End sentences with . ! or ? correctly", "Fix punctuation errors in sentences"], nova: "Every sentence is like a gift: it starts with a capital bow and ends with punctuation wrapping!", xp: 60, time: 8),
        "noun":    QuestEntry(objectives: ["Identify nouns, verbs and adjectives", "Build subject-verb pairs", "Write your own descriptive sentences"], nova: "Nouns are the THINGS, verbs are the ACTIONS, adjectives paint the picture. Three tools, infinite sentences!", xp: 70, time: 10),
        "habitat": QuestEntry(objectives: ["Name six major world habitats", "Match animals to their habitats", "Explain one animal adaptation"], nova: "Every animal is PERFECTLY designed for its home. Polar bears in the Sahara? They'd melt! 🐻‍❄️", xp: 80, time: 12),
        "food":    QuestEntry(objectives: ["Build a 3-step food chain from scratch", "Identify producers, consumers and decomposers", "Explain what happens if one link disappears"], nova: "Remove any link in a food chain and everything shakes! That's why every creature — even tiny bugs — matters.", xp: 85, time: 12),
        "weather": QuestEntry(objectives: ["Name cloud types and their weather clues", "Read a simple weather chart", "Explain one step of the water cycle"], nova: "Cumulonimbus clouds are the storm giants. Cirrus are the wispy ones high up. Learn the clouds, predict the weather!", xp: 75, time: 10),
        "maps":    QuestEntry(objectives: ["Read a compass rose for N/S/E/W", "Use a map key to decode symbols", "Find places on a simple grid map"], nova: "Maps are just a bird's-eye view of the world drawn with maths! Every symbol has a meaning.", xp: 75, time: 10),
        "ancient": QuestEntry(objectives: ["Name 2 ancient civilisations and their locations", "Describe one major achievement each", "Place events on a timeline"], nova: "Ancient Egyptians, Greeks and Romans built things that have lasted 2,000+ years. Imagine what THEY thought of as modern!", xp: 85, time: 12),
        "explor":  QuestEntry(objectives: ["Name 3 famous explorers and their journeys", "Explain why exploration changed the world", "Order explorations on a timeline"], nova: "Explorers were the astronauts of their time — sailing into the unknown with no maps, no GPS, just courage!", xp: 80, time: 12),
    ]
    // swiftlint:enable line_length
}

private struct QuestStageInfo {
    let icon: String
    let label: String
    let desc: String
}

private let questStages: [QuestStageInfo] = [
    QuestStageInfo(icon: "📖", label: "Learn It",   desc: "Nova walks you through the concept with clear examples"),
    QuestStageInfo(icon: "💡", label: "Try One",    desc: "Have a guided go with Nova right beside you"),
    QuestStageInfo(icon: "⚡", label: "Practice",   desc: "3–5 questions at your own pace — hints available"),
    QuestStageInfo(icon: "🏆", label: "Boss Round", desc: "Final challenge question for bonus XP"),
]

private struct StatusFlavour {
    let badge: String
    let tagline: String
    let accent: Color

    static func forStatus(_ s: StarStatus) -> StatusFlavour {
        switch s {
        case .gap:      return StatusFlavour(badge: "😴 Sleepy Star",  tagline: "Wake it up and earn big XP!",   accent: Color(hex: 0x5EE7FF))
        case .learning: return StatusFlavour(badge: "🌱 In Progress",  tagline: "Pick up where you left off!",   accent: Color(hex: 0xFF8AD8))
        case .mastered: return StatusFlavour(badge: "⭐ Mastered",      tagline: "Practice keeps it shining!",   accent: Color(hex: 0xFFE066))
        case .locked:   return StatusFlavour(badge: "🔒 Locked",        tagline: "Unlock prerequisites first.",  accent: Color(hex: 0x7B8294))
        }
    }
}

// MARK: - Training overlay (Quest Briefing)

struct TrainingOverlay: View {
    let node: StarNode
    let onClose: () -> Void
    let onStart: (StarNode) -> Void

    @State private var launched = false

    private var palette: StarPalette  { node.status.palette }
    private var questEntry: QuestEntry { QuestData.entry(for: node.id) }
    private var flavour: StatusFlavour { StatusFlavour.forStatus(node.status) }
    private var masteryPct: Int {
        switch node.status {
        case .mastered: return 100
        case .locked:   return 0
        default:        return Int(((node.mastery ?? 0.25) * 100).rounded())
        }
    }

    var body: some View {
        ZStack {
            Color(hex: 0x09041E).ignoresSafeArea()
            nebulaBackground.ignoresSafeArea()
            starDust.ignoresSafeArea()

            if launched {
                palette.mid
                    .ignoresSafeArea()
                    .opacity(0.85)
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 50)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        heroSection
                        novaBubble
                        objectivesSection
                        stagesSection
                        rewardsSection
                        acceptButton
                        footerNote
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeOut(duration: 0.25), value: launched)
    }

    // MARK: Background layers

    private var nebulaBackground: some View {
        ZStack {
            RadialGradient(
                colors: [palette.mid.opacity(0.18), .clear],
                center: UnitPoint(x: 0.55, y: 0.28),
                startRadius: 0, endRadius: 300
            )
            RadialGradient(
                colors: [Color(hex: 0xA855F7, opacity: 0.13), .clear],
                center: UnitPoint(x: 0.2, y: 0.8),
                startRadius: 0, endRadius: 250
            )
        }
    }

    private var starDust: some View {
        Canvas { ctx, size in
            let pts: [(Double, Double)] = [(0.12, 0.14), (0.78, 0.09), (0.45, 0.82), (0.88, 0.65), (0.30, 0.50)]
            for (px, py) in pts {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: px * size.width - 1, y: py * size.height - 1, width: 2, height: 2)),
                    with: .color(.white.opacity(0.45))
                )
            }
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack {
            Button(action: onClose) {
                Text("←")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.07)))
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(flavour.badge)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(flavour.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(flavour.accent.opacity(0.18)))
                .overlay(Capsule().stroke(flavour.accent.opacity(0.6), lineWidth: 1.5))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: Hero

    private var heroSection: some View {
        HStack(alignment: .center, spacing: 16) {
            // Animated orbiting star
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach([1, 2], id: \.self) { i in
                        Circle()
                            .stroke(
                                palette.mid.opacity(i == 1 ? 0.35 : 0.2),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                            )
                            .scaleEffect(0.62 + CGFloat(i) * 0.24)
                            .rotationEffect(.degrees((t / Double(10 + i * 5)) * 360))
                    }
                    Text(node.emoji)
                        .font(.system(size: 44))
                        .scaleEffect(1.0 + 0.06 * CGFloat(sin(t * 2.2)))
                        .shadow(color: palette.mid.opacity(0.8), radius: 16 + 10 * CGFloat((sin(t * 2.2) + 1) / 2))
                }
                .frame(width: 88, height: 88)
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 4) {
                Text(node.label)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .tracking(-0.4)
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(flavour.tagline)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(flavour.accent)

                if node.status != .locked {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Mastery")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.45))
                            Spacer()
                            Text("\(masteryPct)%")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [palette.mid, Color(hex: 0xFFD044)],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: g.size.width * CGFloat(masteryPct) / 100)
                                    .shadow(color: palette.glow, radius: 4)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Nova bubble

    private var novaBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [palette.mid, palette.halo],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                    .shadow(color: palette.glow, radius: 10)
                Text("✦")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x1A0B40))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("NOVA SAYS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.4)
                    .foregroundColor(palette.mid)
                Text(questEntry.nova)
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .foregroundColor(Color(hex: 0xE8D8FF))
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: 0x20144C, opacity: 0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.mid.opacity(0.33), lineWidth: 1.5)
        )
    }

    // MARK: Objectives

    private var objectivesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("🎯 Quest Objectives")
            ForEach(Array(questEntry.objectives.enumerated()), id: \.offset) { idx, obj in
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(palette.mid.opacity(0.18))
                            .overlay(Circle().stroke(palette.mid.opacity(0.55), lineWidth: 1.5))
                        Text("\(idx + 1)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(palette.mid)
                    }
                    .frame(width: 22, height: 22)
                    .padding(.top, 1)

                    Text(obj)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .lineSpacing(2)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }

    // MARK: Stages

    private var stagesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("🗺️ Quest Stages")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)], spacing: 7) {
                ForEach(questStages, id: \.label) { stage in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(stage.icon).font(.system(size: 20))
                        Text(stage.label)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(stage.desc)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .lineSpacing(1.5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.09), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: Rewards

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("🎁 Quest Rewards")
            HStack(spacing: 7) {
                rewardTile(icon: "✨", label: "XP",       value: "+\(questEntry.xp)")
                rewardTile(icon: "⏱️", label: "Time",     value: "~\(questEntry.time)m")
                rewardTile(icon: "🏅", label: "Star Rank", value: node.status == .gap ? "+2 lvl" : "+1 lvl")
            }
        }
    }

    private func rewardTile(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.system(size: 18))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0xFFE066))
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.mid.opacity(0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.mid.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: CTA

    private var acceptButton: some View {
        Group {
            if node.status != .locked {
                Button(action: handleLaunch) {
                    Text(launched ? "🚀 Launching…" : "🚀 Accept Quest · +\(questEntry.xp) XP")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(launched ? .white.opacity(0.4) : Color(hex: 0x1A0B40))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            launched
                            ? AnyShapeStyle(Color.white.opacity(0.1))
                            : AnyShapeStyle(LinearGradient(
                                colors: [palette.mid, palette.halo],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: launched ? .clear : palette.glow.opacity(0.8), radius: 18, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .disabled(launched)
            } else {
                HStack {
                    Text("🔒 Master prerequisites first")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: 0xC8D2E6, opacity: 0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: 0x7B8294, opacity: 0.35), lineWidth: 1.5)
                )
            }
        }
    }

    private var footerNote: some View {
        Text("Hints available · No time pressure · Progress saved")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.35))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: Helper

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(0.5)
            .foregroundColor(.white.opacity(0.55))
            .textCase(.uppercase)
    }

    private func handleLaunch() {
        guard !launched else { return }
        withAnimation { launched = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            onStart(node)
        }
    }
}

// MARK: - Constellation modal

struct ConstellationModal: View {
    let constellation: Constellation
    let onJumpToStar: (StarNode) -> Void

    @Environment(\.dismiss) private var dismiss

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
