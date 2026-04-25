//
//  LessonView.swift
//  LA Hacks
//
//  Star Hop! full kid-friendly tutoring flow.
//  Welcome → Worked example → Practice problems → Celebrate.
//  Ported from project/lesson.jsx.
//

import SwiftUI

// MARK: - Problem types

enum ProblemKind {
    case multipleChoice
    case input
    case pizza
}

struct LessonProblem: Identifiable {
    let id = UUID()
    let kind: ProblemKind
    let prompt: String
    let hint: String
    let answer: String
    let choices: [String]
    /// Pizza-specific: total slices and target filled count
    let slices: Int
    let target: Int

    static func mc(_ prompt: String, choices: [String], answer: String, hint: String) -> LessonProblem {
        LessonProblem(kind: .multipleChoice, prompt: prompt, hint: hint, answer: answer, choices: choices, slices: 0, target: 0)
    }
    static func input(_ prompt: String, answer: String, hint: String) -> LessonProblem {
        LessonProblem(kind: .input, prompt: prompt, hint: hint, answer: answer, choices: [], slices: 0, target: 0)
    }
    static func pizza(_ prompt: String, slices: Int, target: Int, hint: String) -> LessonProblem {
        LessonProblem(kind: .pizza, prompt: prompt, hint: hint, answer: "correct", choices: [], slices: slices, target: target)
    }
}

struct LessonContent {
    let intro: String
    let exampleQuestion: String
    let exampleAnswer: String
    let exampleViz: String
    let problems: [LessonProblem]
}

// MARK: - Lesson bank (subset; falls back to default)

private func lessonFor(node: StarNode) -> LessonContent {
    switch node.id {
    case "add":
        return LessonContent(
            intro: "Adding is putting groups together to make a bigger group. Let's count some star-rocks!",
            exampleQuestion: "If you have 3 star-rocks and find 4 more, how many do you have?",
            exampleAnswer: "7",
            exampleViz: "⭐⭐⭐ + ⭐⭐⭐⭐ = ?",
            problems: [
                .mc("A space dog has 5 bones. It digs up 3 more. How many bones?", choices: ["6","7","8","9"], answer: "8", hint: "Count up: 5… then 6, 7, 8."),
                .input("12 + 7 = ?", answer: "19", hint: "Start at 12 and hop forward 7 times."),
                .mc("Which equals 14?", choices: ["9 + 4","7 + 7","5 + 10","8 + 8"], answer: "7 + 7", hint: "Doubles can help! What is 7 doubled?"),
                .input("25 + 36 = ?", answer: "61", hint: "Add the tens (20+30=50), then the ones (5+6=11). 50+11=…"),
            ]
        )
    case "mul":
        return LessonContent(
            intro: "Times tables are super-speedy adding! 3 × 4 means '3 groups of 4'.",
            exampleQuestion: "3 × 4 = ?",
            exampleAnswer: "12",
            exampleViz: "⭐⭐⭐⭐  ⭐⭐⭐⭐  ⭐⭐⭐⭐",
            problems: [
                .mc("6 × 7 = ?", choices: ["36","42","48","49"], answer: "42", hint: "6 × 7 is the same as 7 × 6."),
                .input("8 × 9 = ?", answer: "72", hint: "9s trick: 9 × 8 has tens that are one less than 8."),
                .mc("Five spider legs each. 4 spiders. Legs?", choices: ["16","20","24","28"], answer: "20", hint: "Count by 5s: 5, 10, 15, 20."),
                .input("12 × 5 = ?", answer: "60", hint: "Half of 12 × 10."),
            ]
        )
    case "half":
        return LessonContent(
            intro: "A half means TWO equal pieces. A quarter means FOUR.",
            exampleQuestion: "Which pizza shows ½?",
            exampleAnswer: "1 of 2 slices",
            exampleViz: "🍕",
            problems: [
                .pizza("Tap to color in ½ of the pizza.", slices: 2, target: 1, hint: "Half means 1 of 2 equal pieces."),
                .pizza("Tap to color in ¾ of the pizza.", slices: 4, target: 3, hint: "¾ means 3 of 4 equal slices."),
                .mc("Which is bigger, ½ or ¼?", choices: ["½","¼","They are equal"], answer: "½", hint: "A half pizza is bigger than a quarter pizza!"),
            ]
        )
    case "addfrac":
        return LessonContent(
            intro: "When fractions have the SAME bottom number, we just add the tops!",
            exampleQuestion: "1/4 + 2/4 = ?",
            exampleAnswer: "3/4",
            exampleViz: "🍕 1/4 + 🍕🍕 2/4",
            problems: [
                .mc("2/5 + 1/5 = ?", choices: ["3/10","3/5","2/5","1/5"], answer: "3/5", hint: "Tops add: 2+1=3. Bottom stays 5."),
                .mc("3/8 + 4/8 = ?", choices: ["7/16","7/8","12/8","1/8"], answer: "7/8", hint: "Add the tops, keep the bottom."),
            ]
        )
    case "tri":
        return LessonContent(
            intro: "Triangles have 3 sides and 3 corners. Let's spot some.",
            exampleQuestion: "How many sides on a triangle?",
            exampleAnswer: "3",
            exampleViz: "🔺",
            problems: [
                .mc("How many corners on a triangle?", choices: ["2","3","4","5"], answer: "3", hint: "Same as the number of sides!"),
                .mc("Which is NOT a triangle?", choices: ["🔺","🟦","🛑","Yield sign"], answer: "🟦", hint: "A square has 4 sides."),
            ]
        )
    case "area":
        return LessonContent(
            intro: "Area is how much SPACE is inside a shape. Count the squares!",
            exampleQuestion: "A 3×4 rectangle has area...",
            exampleAnswer: "12",
            exampleViz: "3 rows × 4 cols",
            problems: [
                .mc("A 5 × 4 rug. What is the area?", choices: ["9","18","20","24"], answer: "20", hint: "Multiply length × width."),
                .input("A square with side 6. Area = ?", answer: "36", hint: "6 × 6."),
            ]
        )
    case "main":
        return LessonContent(
            intro: "The MAIN IDEA is what a story is mostly about. Big picture!",
            exampleQuestion: "A story about a lost puppy who finds a new family. Main idea?",
            exampleAnswer: "A lost puppy finds a new family",
            exampleViz: "🐶❤️🏠",
            problems: [
                .mc("Main idea of a story about Rosa learning to ride a bike?",
                    choices: ["Rosa likes ice cream","Rosa learns to ride a bike with practice","Bikes have two wheels"],
                    answer: "Rosa learns to ride a bike with practice",
                    hint: "What is the WHOLE story really about?"),
                .mc("A story tells how bees make honey. The main idea is about...",
                    choices: ["Flowers being pretty","How bees make honey","Bears liking honey"],
                    answer: "How bees make honey", hint: "It is right in the description!"),
            ]
        )
    case "habitat":
        return LessonContent(
            intro: "A HABITAT is where a plant or animal lives — its home!",
            exampleQuestion: "Where does a polar bear live?",
            exampleAnswer: "Arctic",
            exampleViz: "🐻‍❄️❄️",
            problems: [
                .mc("A cactus lives where?", choices: ["Ocean","Desert","Forest","Pond"], answer: "Desert", hint: "Cacti love hot, dry places!"),
                .mc("Which animal lives in a coral reef?", choices: ["Wolf","Camel","Clownfish","Penguin"], answer: "Clownfish", hint: "Think Finding Nemo!"),
            ]
        )
    default:
        return LessonContent(
            intro: "Let's practice \(node.label)! I'll start easy and we'll level up.",
            exampleQuestion: "Quick warm-up: tap 'Got it!' when you're ready.",
            exampleAnswer: "ready",
            exampleViz: node.emoji,
            problems: [
                .mc("Pick the answer that fits \(node.label) best.", choices: ["A","B","C","D"], answer: "A", hint: "Trust your first thought!"),
                .mc("One more for \(node.label)…", choices: ["Yes","No","Maybe"], answer: "Yes", hint: "You got this!"),
            ]
        )
    }
}

// MARK: - LessonView

struct LessonView: View {
    let node: StarNode
    let onClose: () -> Void

    @State private var stage: LessonStage = .welcome
    @State private var problemIdx: Int = 0
    @State private var streak: Int = 0
    @State private var xpGained: Int = 0
    @State private var hearts: Int = 3
    @State private var hintsUsed: Int = 0

    enum LessonStage { case welcome, example, practice, celebrate }

    private var lesson: LessonContent { lessonFor(node: node) }
    private var palette: StarPalette { node.status.palette }
    private var totalProblems: Int { lesson.problems.count }
    private var progress: Double {
        switch stage {
        case .welcome: return 0
        case .example: return 0.1
        case .practice: return 0.1 + Double(problemIdx) / Double(totalProblems) * 0.85
        case .celebrate: return 1
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1B0B40), Color(hex: 0x2A1066), Color(hex: 0x0F0628)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // faint stars decoration
            Canvas { ctx, size in
                let pts: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.14, 0.12, 0.8), (0.78, 0.22, 0.6),
                    (0.32, 0.84, 0.6), (0.84, 0.70, 0.7),
                    (0.10, 0.55, 0.5), (0.55, 0.40, 0.4),
                ]
                for (px, py, pr) in pts {
                    let x = px * size.width, y = py * size.height
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - pr, y: y - pr, width: pr * 2, height: pr * 2)),
                        with: .color(.white.opacity(0.6))
                    )
                }
            }
            .opacity(0.5)
            .allowsHitTesting(false)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                progressBar
                content
            }
        }
    }

    // MARK: Header / progress

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Text("✕")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.12)))
                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                if let info = GalaxyData.nodesById[node.id] {
                    Text("LESSON · \(info.constellationName)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(0.5)
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("LESSON")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(0.5)
                        .foregroundColor(.white.opacity(0.6))
                }
                Text("\(node.emoji) \(node.label)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Text("❤️")
                        .font(.system(size: 14))
                        .opacity(i < hearts ? 1 : 0.25)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(hex: 0xFF5078, opacity: 0.15)))
            .overlay(Capsule().stroke(Color(hex: 0xFF5078, opacity: 0.4), lineWidth: 1.5))
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .padding(.bottom, 12)
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [palette.mid, Color(hex: 0xFFE066)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: g.size.width * CGFloat(progress))
                        .shadow(color: palette.glow, radius: 8)
                }
            }
            .frame(height: 8)
            HStack {
                Text(progressLabel)
                Spacer()
                Text("+\(xpGained) XP\(streak >= 2 ? " · 🔥 \(streak)" : "")")
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.55))
            .tracking(0.4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var progressLabel: String {
        switch stage {
        case .practice: return "Q \(problemIdx + 1) of \(totalProblems)"
        case .celebrate: return "Done!"
        default: return "Warm-up"
        }
    }

    // MARK: Content stages

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                switch stage {
                case .welcome:
                    welcomeView
                case .example:
                    exampleView
                case .practice:
                    ProblemView(
                        problem: lesson.problems[problemIdx],
                        palette: palette,
                        onDone: handleProblemDone
                    )
                    .id(problemIdx)
                case .celebrate:
                    celebrateView
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
    }

    private var welcomeView: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 12) {
                Text("🦊").font(.system(size: 70))
                NovaBubble(text: "Hi there! I'm Nova. Today we're going to explore \(node.label)! 🚀", color: Color(hex: 0xFFE066))
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text("📘 THE BIG IDEA")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: 0xFFE066))
                Text(lesson.intro)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(3)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: 0xFFE066, opacity: 0.3), lineWidth: 1.5)
            )

            HStack(spacing: 8) {
                statBlock(icon: "🎯", n: "\(lesson.problems.count)", label: "Questions")
                statBlock(icon: "⏱️", n: "~5", label: "Minutes")
                statBlock(icon: "⭐", n: "\(lesson.problems.count * 15)", label: "Max XP")
            }

            BigButton(label: "Let's go! 🚀") {
                withAnimation { stage = .example }
            }
        }
    }

    private func statBlock(icon: String, n: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 22))
            Text(n).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.6))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    @State private var exampleRevealed = false

    private var exampleView: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text("🦊").font(.system(size: 64))
                NovaBubble(text: "Watch me solve one first. Then it's your turn!", color: Color(hex: 0x5EE7FF))
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 14) {
                Text("👀 WORKED EXAMPLE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: 0x5EE7FF))
                Text(lesson.exampleQuestion)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(3)

                Text(lesson.exampleViz)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )

                if exampleRevealed {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("✨ ANSWER")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(0.5)
                            .foregroundColor(Color(hex: 0x2A1A0A))
                        Text(lesson.exampleAnswer)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x2A1A0A))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8AD8)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    )
                } else {
                    Button(action: { withAnimation { exampleRevealed = true } }) {
                        Text("🔍 Show me the answer")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.5),
                                                  style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: 0x5EE7FF, opacity: 0.15), Color(hex: 0xA855F7, opacity: 0.12)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(hex: 0x5EE7FF, opacity: 0.4), lineWidth: 2)
            )

            if exampleRevealed {
                BigButton(label: "I'm ready! Try me 💪") {
                    withAnimation { stage = .practice }
                }
            }
        }
    }

    private func handleProblemDone(correct: Bool, usedHint: Bool) {
        if correct {
            streak += 1
            xpGained += (usedHint ? 8 : 15) + (streak >= 2 ? 5 : 0)
        } else {
            streak = 0
            hearts = max(0, hearts - 1)
        }
        if usedHint { hintsUsed += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + (correct ? 0.85 : 1.3)) {
            if problemIdx + 1 >= totalProblems {
                withAnimation { stage = .celebrate }
            } else {
                problemIdx += 1
            }
        }
    }

    private var celebrateView: some View {
        let stars = hearts >= 3 && hintsUsed == 0 ? 3 : hearts >= 2 ? 2 : 1
        return VStack(spacing: 16) {
            Text("🦊").font(.system(size: 100))
                .padding(.top, 12)
            Text("🎉 LESSON COMPLETE!")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundColor(palette.mid)
            Text("You did it!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .foregroundColor(.white)
            Text("That star is shining a little brighter ⭐")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    Text(i < stars ? "⭐" : "☆")
                        .font(.system(size: 28))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle().fill(
                                i < stars
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: 0xFFE066), Color(hex: 0xFFB300)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(Color.white.opacity(0.08))
                            )
                        )
                        .overlay(
                            Circle().stroke(
                                i < stars ? Color(hex: 0xFFE066) : Color.white.opacity(0.15),
                                lineWidth: 2
                            )
                        )
                        .shadow(color: i < stars ? Color(hex: 0xFFB300, opacity: 0.5) : .clear, radius: 14, x: 0, y: 4)
                }
            }
            .padding(.vertical, 8)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                celebrateStat(icon: "✨", label: "XP earned", value: "+\(xpGained)", color: Color(hex: 0xFFE066))
                celebrateStat(icon: "❤️", label: "Hearts left", value: "\(hearts)/3", color: Color(hex: 0xFF8AD8))
                celebrateStat(icon: "💡", label: "Hints used", value: "\(hintsUsed)", color: Color(hex: 0x5EE7FF))
                celebrateStat(icon: "🔥", label: "New streak", value: "+1 day", color: Color(hex: 0xFF8A4C))
            }

            BigButton(label: "Back to galaxy 🌌") { onClose() }
        }
    }

    private func celebrateStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 22))
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .tracking(0.4)
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.33), lineWidth: 1.5)
        )
    }
}

// MARK: - Problem view

private struct ProblemView: View {
    let problem: LessonProblem
    let palette: StarPalette
    let onDone: (_ correct: Bool, _ usedHint: Bool) -> Void

    @State private var picked: String?
    @State private var showHint = false
    @State private var feedback: Feedback?
    @State private var submitted = false
    @State private var textVal: String = ""
    @State private var pizzaFilled: Set<Int> = []

    enum Feedback { case good, oops }

    private static let cheers = [
        "You got it! 🎉", "Stellar work! ⭐", "Bingo! High five 🖐",
        "Cosmic! Keep going!", "You're on fire! 🔥", "Wow, that was fast!"
    ]
    private static let oopses = [
        "Close one! Let's try the next one.",
        "Mistakes help us grow 🌱 — onward!",
        "No worries. Every star takes practice.",
    ]

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Text("🦊").font(.system(size: 56))
                NovaBubble(
                    text: bubbleText,
                    color: feedback == .good ? Color(hex: 0xA0F0A0) : feedback == .oops ? Color(hex: 0xFFB0B0) : Color(hex: 0xFFE066)
                )
            }
            .padding(.top, 12)

            if feedback == nil {
                problemBody
                hintBlock
            } else {
                feedbackBlock
            }
        }
    }

    private var bubbleText: String {
        switch feedback {
        case .good: return Self.cheers.randomElement() ?? "Nice!"
        case .oops: return "The answer was: \(problem.answer)"
        case .none: return problem.prompt
        }
    }

    @ViewBuilder
    private var problemBody: some View {
        switch problem.kind {
        case .multipleChoice: mcView
        case .input: inputView
        case .pizza: pizzaView
        }
    }

    private var mcView: some View {
        VStack(spacing: 10) {
            ForEach(Array(problem.choices.enumerated()), id: \.offset) { i, ch in
                Button(action: {
                    picked = ch
                    submit(value: ch)
                }) {
                    HStack(spacing: 12) {
                        Text(String(UnicodeScalar(65 + i)!))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                        Text(ch)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(picked == ch
                                  ? AnyShapeStyle(LinearGradient(
                                        colors: [palette.mid, palette.halo],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color.white.opacity(0.08)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(picked == ch ? palette.mid : Color.white.opacity(0.18), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var inputView: some View {
        VStack(spacing: 10) {
            TextField("", text: $textVal, prompt: Text("Type your answer…")
                .foregroundColor(.white.opacity(0.4)))
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: 0xFFE066, opacity: 0.3), lineWidth: 2)
                )

            Button(action: { submit(value: textVal) }) {
                Text("Check ✓")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(textVal.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.4) : Color(hex: 0x1A0B40))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(textVal.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? AnyShapeStyle(Color.white.opacity(0.1))
                                  : AnyShapeStyle(LinearGradient(
                                        colors: [palette.mid, palette.halo],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
                    .shadow(color: textVal.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : palette.glow, radius: 16, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(textVal.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 2)
        )
    }

    private var pizzaView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xC97A3F))
                    .frame(width: 200, height: 200)
                Circle()
                    .fill(Color(hex: 0xFFE0A0))
                    .frame(width: 188, height: 188)
                ForEach(0..<problem.slices, id: \.self) { i in
                    PizzaSlice(index: i, total: problem.slices, radius: 90)
                        .fill(pizzaFilled.contains(i) ? Color(hex: 0xFF7A4C) : .clear)
                        .overlay(
                            PizzaSlice(index: i, total: problem.slices, radius: 90)
                                .stroke(Color(hex: 0xC97A3F), lineWidth: 2)
                        )
                        .frame(width: 200, height: 200)
                        .onTapGesture {
                            if pizzaFilled.contains(i) { pizzaFilled.remove(i) } else { pizzaFilled.insert(i) }
                        }
                }
            }
            .frame(width: 220, height: 220)

            (Text("You filled ").foregroundColor(.white.opacity(0.75))
             + Text("\(pizzaFilled.count)/\(problem.slices)").foregroundColor(Color(hex: 0xFFE066)).bold()
             + Text(" · Goal: ").foregroundColor(.white.opacity(0.75))
             + Text("\(problem.target)/\(problem.slices)").foregroundColor(Color(hex: 0xFFE066)).bold())
                .font(.system(size: 13, weight: .medium, design: .rounded))

            Button(action: {
                submit(value: pizzaFilled.count == problem.target ? "correct" : "wrong")
            }) {
                Text("Check pizza ✓")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(pizzaFilled.isEmpty ? .white.opacity(0.4) : Color(hex: 0x1A0B40))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(pizzaFilled.isEmpty
                                  ? AnyShapeStyle(Color.white.opacity(0.1))
                                  : AnyShapeStyle(LinearGradient(
                                        colors: [palette.mid, palette.halo],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
            }
            .buttonStyle(.plain)
            .disabled(pizzaFilled.isEmpty)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 2)
        )
    }

    private var hintBlock: some View {
        Group {
            if !showHint {
                Button(action: { showHint = true }) {
                    Text("💡 Hint? (small XP penalty)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: 0x5EE7FF))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hex: 0x5EE7FF, opacity: 0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(hex: 0x5EE7FF, opacity: 0.45),
                                              style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        )
                }
                .buttonStyle(.plain)
            } else {
                (Text("💡 Hint: ").foregroundColor(Color(hex: 0x5EE7FF)).bold()
                 + Text(problem.hint).foregroundColor(.white))
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: 0x5EE7FF, opacity: 0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: 0x5EE7FF, opacity: 0.4), lineWidth: 1.5)
                    )
            }
        }
    }

    private var feedbackBlock: some View {
        let isGood = feedback == .good
        return VStack(alignment: .leading, spacing: 4) {
            Text(isGood ? "✨ CORRECT!" : "🤔 NOT QUITE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundColor(.white)
            Text(isGood ? "+\(showHint ? 8 : 15) XP earned!" : "The answer was: \(problem.answer)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(
                    colors: isGood
                    ? [Color(hex: 0xA0F0A0, opacity: 0.25), Color(hex: 0x5EE7FF, opacity: 0.2)]
                    : [Color(hex: 0xFFB4B4, opacity: 0.2), Color(hex: 0xFF8AD8, opacity: 0.15)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isGood ? Color(hex: 0xA0F0A0) : Color(hex: 0xFFB0B0), lineWidth: 2)
        )
    }

    private func submit(value: String) {
        guard !submitted else { return }
        submitted = true
        let correct = value.trimmingCharacters(in: .whitespaces).lowercased()
                       == problem.answer.trimmingCharacters(in: .whitespaces).lowercased()
        feedback = correct ? .good : .oops
        onDone(correct, showHint)
    }
}

// MARK: - Pizza slice shape

private struct PizzaSlice: Shape {
    let index: Int
    let total: Int
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let a0 = Double(index) / Double(total) * .pi * 2 - .pi / 2
        let a1 = Double(index + 1) / Double(total) * .pi * 2 - .pi / 2
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy))
        p.addLine(to: CGPoint(x: cx + CGFloat(cos(a0)) * radius, y: cy + CGFloat(sin(a0)) * radius))
        p.addArc(
            center: CGPoint(x: cx, y: cy),
            radius: radius,
            startAngle: .radians(a0),
            endAngle: .radians(a1),
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Bubbles & buttons

private struct NovaBubble: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(Color(hex: 0x2A1A0A))
            .lineSpacing(2)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: 280, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.97))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(color, lineWidth: 2)
            )
    }
}

private struct BigButton: View {
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x1A0B40))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8AD8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: 0xFFE066, opacity: 0.4), radius: 16, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
