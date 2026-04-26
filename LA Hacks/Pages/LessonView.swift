//
//  LessonView.swift
//  LA Hacks
//
//  Star Hop! conversational tutoring view + supporting types
//  (ProblemKind, LessonProblem, LessonContent, MessageSource, LessonAction, BottomInputKind).
//

import SwiftUI
import AVFoundation

var streamedResponse: String = ""
var lastAnswerCorrect: Bool? = nil

// MARK: - Problem types (unchanged)

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

// MARK: - Lesson bank

private func lessonFor(node: StarNode) -> LessonContent {
    switch node.id {
    case "add":
        return LessonContent(
            intro: "Adding means putting groups together to make something bigger. Every adventure starts with one small step! 🌟",
            exampleQuestion: "If you have 3 star-rocks and find 4 more, how many do you have?",
            exampleAnswer: "7",
            exampleViz: "⭐⭐⭐ + ⭐⭐⭐⭐ = ?",
            problems: [
                .mc("A space dog has 5 bones and digs up 3 more. How many bones total?", choices: ["6","7","8","9"], answer: "8", hint: "Count up from 5: 6, 7, 8."),
                .input("12 + 7 = ?", answer: "19", hint: "Start at 12 and hop forward 7 times."),
                .mc("Which one equals 14?", choices: ["9 + 4","7 + 7","5 + 10","8 + 8"], answer: "7 + 7", hint: "Doubles can help! What is 7 doubled?"),
                .input("25 + 36 = ?", answer: "61", hint: "Add the tens (20+30=50), then the ones (5+6=11). 50+11=?"),
            ]
        )
    case "mul":
        return LessonContent(
            intro: "Times tables are super-speedy adding! 3 × 4 means '3 groups of 4'. ⚡",
            exampleQuestion: "3 × 4 = ? (think: 4 + 4 + 4)",
            exampleAnswer: "12",
            exampleViz: "⭐⭐⭐⭐  ⭐⭐⭐⭐  ⭐⭐⭐⭐",
            problems: [
                .mc("6 × 7 = ?", choices: ["36","42","48","49"], answer: "42", hint: "6 × 7 is the same as 7 × 6. Try counting by 6s."),
                .input("8 × 9 = ?", answer: "72", hint: "9s trick: tens digit is one less than 8, so 7_. Digits add to 9 → 72!"),
                .mc("5 spiders, each with 8 legs. How many legs total?", choices: ["35","40","45","48"], answer: "40", hint: "Count by 5s: 8, 16, 24, 32, 40."),
                .input("12 × 5 = ?", answer: "60", hint: "Half of 12 × 10. What is 12 × 10?"),
            ]
        )
    case "half":
        return LessonContent(
            intro: "A half means TWO equal pieces. A quarter means FOUR equal pieces. 🍕",
            exampleQuestion: "Which fraction means 1 out of 2 equal parts?",
            exampleAnswer: "½",
            exampleViz: "🍕",
            problems: [
                .pizza("Tap to show ½ of the pizza.", slices: 2, target: 1, hint: "Half means 1 of 2 equal pieces."),
                .mc("Which is bigger, ½ or ¼?", choices: ["½","¼","They are equal"], answer: "½", hint: "More slices cut = smaller each slice!"),
                .pizza("Tap to show ¾ of the pizza.", slices: 4, target: 3, hint: "¾ = 3 out of 4 equal pieces."),
            ]
        )
    case "addfrac":
        return LessonContent(
            intro: "When fractions have the SAME bottom number, just add the tops! The bottom stays. 🧮",
            exampleQuestion: "1/4 + 2/4 = ?",
            exampleAnswer: "3/4 (add tops: 1+2=3, keep bottom: 4)",
            exampleViz: "🍕 1/4 + 🍕🍕 2/4",
            problems: [
                .mc("2/5 + 1/5 = ?", choices: ["3/10","3/5","2/5","1/5"], answer: "3/5", hint: "Tops add: 2+1=3. Bottom stays 5."),
                .mc("3/8 + 4/8 = ?", choices: ["7/16","7/8","12/8","1/8"], answer: "7/8", hint: "Add the tops (3+4), keep the bottom (8)."),
            ]
        )
    case "tri":
        return LessonContent(
            intro: "Triangles have 3 sides and 3 corners. They're everywhere — pizza slices, yield signs! 🔺",
            exampleQuestion: "How many sides on a triangle?",
            exampleAnswer: "3",
            exampleViz: "🔺",
            problems: [
                .mc("How many corners (vertices) on a triangle?", choices: ["2","3","4","5"], answer: "3", hint: "Same as the number of sides!"),
                .mc("Which shape is NOT a triangle?", choices: ["A yield sign shape","A square","A slice of pizza","A mountain outline"], answer: "A square", hint: "A square has 4 sides."),
            ]
        )
    case "area":
        return LessonContent(
            intro: "Area is how much flat SPACE is inside a shape. Count the squares inside! 📐",
            exampleQuestion: "A 3×4 rectangle — how many squares fit inside?",
            exampleAnswer: "12 (3 × 4 = 12)",
            exampleViz: "3 rows × 4 cols",
            problems: [
                .mc("A 5 × 4 rug. What is the area in square units?", choices: ["9","18","20","24"], answer: "20", hint: "Multiply length × width."),
                .input("A square with side length 6. Area = ?", answer: "36", hint: "6 × 6."),
            ]
        )
    case "main":
        return LessonContent(
            intro: "The MAIN IDEA is what a whole story is mostly about. The big picture! 🖼️",
            exampleQuestion: "A story about a lost puppy who finds a new family. What's the main idea?",
            exampleAnswer: "A lost puppy finds a new family",
            exampleViz: "🐶❤️🏠",
            problems: [
                .mc("Rosa learns to ride a bike after many tries. Main idea?",
                    choices: ["Rosa likes ice cream","Rosa learns to ride a bike with practice","Bikes have two wheels"],
                    answer: "Rosa learns to ride a bike with practice",
                    hint: "What is the WHOLE story really about?"),
                .mc("A passage explains how bees make honey. The main idea is about…",
                    choices: ["Flowers being pretty","How bees make honey","Bears liking honey"],
                    answer: "How bees make honey", hint: "It's right there in the description!"),
            ]
        )
    case "habitat":
        return LessonContent(
            intro: "A HABITAT is where a plant or animal lives and finds everything it needs. Its home! 🌿",
            exampleQuestion: "Where does a polar bear live?",
            exampleAnswer: "The Arctic — cold, icy, perfect for polar bears!",
            exampleViz: "🐻‍❄️❄️",
            problems: [
                .mc("A cactus lives where?", choices: ["Ocean","Desert","Forest","Pond"], answer: "Desert", hint: "Cacti love hot, dry, sandy places!"),
                .mc("Which animal lives in a coral reef?", choices: ["Wolf","Camel","Clownfish","Penguin"], answer: "Clownfish", hint: "Think Finding Nemo!"),
            ]
        )
    default:
        return LessonContent(
            intro: "Let's explore \(node.label) together! I'll guide you through it step by step.",
            exampleQuestion: "Tap ready when you're set to go!",
            exampleAnswer: "Let's do this!",
            exampleViz: node.emoji,
            problems: [
                .mc("A warm-up question for \(node.label):", choices: ["Option A","Option B","Option C"], answer: "Option A", hint: "Trust your instincts!"),
            ]
        )
    }
}

// MARK: - Chat message model


// MARK: - Chat message source

enum MessageSource { case nova, student }

// MARK: - Input area state

enum LessonAction { case toExample, toPractice, toDone }

enum BottomInputKind {
    case action(label: String, kind: LessonAction)
    case mc(choices: [String], problem: LessonProblem, idx: Int)
    case text(problem: LessonProblem, idx: Int)
}


// MARK: - LessonView

struct LessonView: View {
    let node: StarNode
    let onClose: () -> Void

    @State private var msgs: [ChatMsg] = []
    @State private var isTyping = false
    @State private var bottomInput: BottomInputKind? = nil
    @State private var hearts = 3
    @State private var xpGained = 0
    @State private var streak = 0
    @State private var hintsUsed = 0
    @State private var phase: Phase = .intro
    @State private var questionKey = 0

    // Adaptive flow state.
    @State private var opening: LessonOpening?
    @State private var currentProblem: LessonProblem?
    @State private var pastOutcomes: [PastProblemOutcome] = []
    @State private var attempts: Int = 0
    @State private var isThinking = false
    @State private var thinkingCaption: String = "Thinking…"
    @State private var didKickoffGeneration = false

    // #3 Voice mode — Nova reads her lines aloud when on.
    @AppStorage("lesson.voiceMode") private var voiceMode: Bool = false

    // #2 Tiered hints — track which tier of hint the kid has unlocked on
    // the current problem (0 = none, 1 = static hint, 2 = LLM half-answer).
    @State private var hintTier: Int = 0
    @State private var pendingDeeperHint: String? = nil

    // #7 Mini-celebration trigger — bumped on each correct answer.
    @State private var celebratePulse: Int = 0

    enum Phase { case intro, example, practice, celebrate }

    private var pal: StarPalette { node.status.palette }
    private var nProbs: Int { LessonConfig.problemCount }
    private var qIdx: Int { pastOutcomes.count }

    /// Live lesson context fed to every LLM call — pulled from GalaxyData
    /// plus the persistent MemoryStore (`memory.md`) so Nova "remembers" the
    /// kid across sessions.
    private var ctx: LessonContext {
        let info = GalaxyData.nodesById[node.id]
        var constellation: Constellation? = nil
        if let cid = info?.constellationId {
            constellation = GalaxyData.constellations.first(where: { $0.id == cid })
        }
        let siblings: [String] = constellation
            .map { c in c.nodes.filter { $0.id != node.id }.map { $0.label } }
            ?? []
        return LessonContext(
            node: node,
            constellationName: info?.constellationName,
            course: constellation?.course,
            blurb: constellation?.blurb,
            siblingLabels: siblings,
            memory: MemoryStore.shared.contextForPrompt()
        )
    }

    /// Static fallback content used when an LLM call returns nil.
    private var fallback: LessonContent { lessonFor(node: node) }

    private var progress: Double {
        switch phase {
        case .intro:     return 0.02
        case .example:   return 0.10
        case .practice:  return nProbs > 0 ? 0.12 + Double(qIdx) / Double(nProbs) * 0.85 : 0.12
        case .celebrate: return 1.0
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0x09041E).ignoresSafeArea()
            stardust.ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader
                progressStrip
                chatScroll
                if let inp = bottomInput {
                    LessonInputArea(
                        inputKind: inp,
                        pal: pal,
                        hintTier: $hintTier,
                        questionKey: questionKey,
                        onAction: handleAction,
                        onAnswer: handleAnswer,
                        onHint: handleHintRequest
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: bottomInput != nil)

            // #7 — transient star burst on each correct answer.
            CelebrationBurst(trigger: celebratePulse, palette: pal)
                .allowsHitTesting(false)
        }
        .onAppear {
            if !didKickoffGeneration {
                didKickoffGeneration = true
                kickoffOpening()
            }
        }
    }

    // MARK: - Adaptive LLM kickoffs

    /// First call: intro + worked example. n-body shows during the wait.
    private func kickoffOpening() {
        startThinking("Putting together a fresh \(node.emoji) \(node.label) lesson…")
        let context = ctx
        Task {
            let result = await LessonGenerator.generateOpening(context)
            await MainActor.run {
                if let result = result { self.opening = result }
                self.stopThinking()
                self.startIntro()
            }
        }
    }

    /// Generates the next problem, conditioned on the kid's prior performance.
    private func kickoffNextProblem() {
        guard pastOutcomes.count < nProbs else {
            celebrate()
            return
        }
        startThinking("Picking your next \(node.emoji) question…")
        let context = ctx
        let history = pastOutcomes
        let index = pastOutcomes.count
        let total = nProbs
        Task {
            let prob = await LessonGenerator.generateProblem(
                context, history: history, index: index, total: total
            )
            await MainActor.run {
                self.stopThinking()
                let resolved = prob ?? self.staticFallbackProblem(at: index)
                self.currentProblem = resolved
                self.attempts = 0
                self.questionKey += 1
                self.askCurrent()
            }
        }
    }

    /// After a wrong answer, ask Nova for a kind nudge and re-open the input.
    private func kickoffCoaching(problem: LessonProblem, studentAnswer: String) {
        startThinking("\(node.emoji) Helping you think it through…")
        let context = ctx
        let attemptNum = attempts
        Task {
            let coaching = await LessonGenerator.coach(
                context,
                problem: problem,
                studentAnswer: studentAnswer,
                attempt: attemptNum
            )
            await MainActor.run {
                self.stopThinking()
                let line = coaching ?? "Hmm, not quite — try once more. \(problem.hint)"
                self.sendNova([line]) {
                    // Re-open the SAME problem for another attempt.
                    self.bottomInput = .text(problem: problem, idx: self.qIdx)
                }
            }
        }
    }

    /// Final attempt exhausted: walk through the answer, log it, advance.
    private func kickoffWalkThrough(problem: LessonProblem, studentAnswer: String, hintUsed: Bool) {
        startThinking("\(node.emoji) Let me walk you through it…")
        let context = ctx
        Task {
            let walk = await LessonGenerator.walkThrough(
                context, problem: problem, studentAnswer: studentAnswer
            )
            await MainActor.run {
                self.stopThinking()
                let line = walk ?? "The answer was \(problem.answer). \(problem.hint) Let's try the next one!"
                self.sendNova([line]) {
                    self.recordOutcome(
                        problem: problem,
                        studentAnswer: studentAnswer,
                        correct: false,
                        hintUsed: hintUsed
                    )
                    self.streak = 0
                    self.hearts = max(0, self.hearts - 1)
                    self.kickoffNextProblem()
                }
            }
        }
    }

    private func startThinking(_ caption: String) {
        thinkingCaption = caption
        bottomInput = nil
        withAnimation(.easeOut(duration: 0.18)) { isThinking = true }
    }

    private func stopThinking() {
        withAnimation(.easeOut(duration: 0.25)) { isThinking = false }
    }

    private func staticFallbackProblem(at index: Int) -> LessonProblem {
        let bank = fallback.problems
        guard !bank.isEmpty else {
            return .input("What is \(node.label)?", answer: node.label.lowercased(), hint: "Just type the topic name.")
        }
        var p = bank[index % bank.count]
        // Pizza visuals don't fit the chat input — paraphrase to a typed fraction.
        if p.kind == .pizza {
            let answer = "\(p.target)/\(p.slices)"
            let prompt = p.prompt.replacingOccurrences(of: "Tap to color in", with: "Type the fraction for")
                                  .replacingOccurrences(of: "Tap to show", with: "Type the fraction for")
            p = LessonProblem.input(prompt, answer: answer, hint: p.hint)
        }
        return p
    }

    /// Lowercase, collapse internal whitespace, strip surrounding/trailing
    /// punctuation. Lets "7+7" match "7 + 7", "Desert." match "desert", etc.
    static func normalizeAnswer(_ s: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "+-*/×÷=.,/"))
        let lowered = s.lowercased()
        let stripped = lowered.unicodeScalars.filter { allowed.contains($0) || $0 == " " }
        let collapsed = String(String.UnicodeScalarView(stripped))
            .split(whereSeparator: { $0 == " " })
            .joined()
        return collapsed
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Text("←")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.07)))
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)

            NovaAvatarView(size: 30, pal: pal)

            VStack(alignment: .leading, spacing: 1) {
                Text("Nova")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 0) {
                    Text("\(node.emoji) \(node.label)")
                        .foregroundColor(.white.opacity(0.5))
                    if phase == .practice {
                        Text(" · Q\(qIdx+1)/\(nProbs)")
                            .foregroundColor(Color(hex: 0xFFCC50, opacity: 0.6))
                    }
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                // #3 Voice toggle — taps a speaker icon to read Nova aloud.
                Button(action: {
                    voiceMode.toggle()
                    if !voiceMode { synthesizer.stopSpeaking(at: .immediate) }
                }) {
                    Image(systemName: voiceMode ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(voiceMode ? Color(hex: 0xFFD044) : .white.opacity(0.55))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(voiceMode ? Color(hex: 0xFFD044, opacity: 0.18) : Color.white.opacity(0.07)))
                        .overlay(Circle().stroke(voiceMode ? Color(hex: 0xFFD044, opacity: 0.45) : Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)

                if xpGained > 0 {
                    Text("+\(xpGained) XP")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFD044))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: 0xFFD044, opacity: 0.15)))
                        .overlay(Capsule().stroke(Color(hex: 0xFFD044, opacity: 0.3), lineWidth: 1))
                        .scaleEffect(celebratePulse > 0 ? 1.15 : 1.0)
                        .animation(.spring(response: 0.32, dampingFraction: 0.55), value: celebratePulse)
                }
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Text("❤️").font(.system(size: 12))
                            .opacity(i < hearts ? 1.0 : 0.18)
                            .animation(.easeOut(duration: 0.3), value: hearts)
                    }
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.top, 50)
        .padding(.bottom, 10)
        .background(
            Color(hex: 0x09041E)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(Rectangle().fill(Color.white.opacity(0.055)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Progress strip (3 px)

    private var progressStrip: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(LinearGradient(colors: [pal.mid, Color(hex: 0xFFD044)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: g.size.width * max(0, CGFloat(progress)))
                    .shadow(color: pal.glow, radius: 4)
            }
            .animation(.easeInOut(duration: 0.55), value: progress)
        }
        .frame(height: 3)
    }

    // MARK: - Chat scroll

    private var chatScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(msgs) { m in
                        MsgBubble(msg: m, pal: pal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    if isTyping {
                        TypingBubble(pal: pal).id("typing")
                    }
                    if isThinking {
                        LessonThinkingBubble(pal: pal, caption: thinkingCaption)
                            .id("thinking")
                            .transition(.opacity)
                    }
                    Color.clear.frame(height: 6).id("__end")
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .onChange(of: msgs.count) {
                withAnimation { proxy.scrollTo("__end") }
            }
            .onChange(of: isTyping) {
                if isTyping { withAnimation { proxy.scrollTo("__end") } }
            }
            .onChange(of: isThinking) {
                if isThinking { withAnimation { proxy.scrollTo("__end") } }
            }
        }
    }

    // MARK: - Stardust bg

    private var stardust: some View {
        Canvas { ctx, sz in
            for (px, py, pr): (Double, Double, Double) in [
                (0.12, 0.18, 0.7), (0.88, 0.08, 0.5),
                (0.42, 0.88, 0.5), (0.76, 0.72, 0.45),
                (0.22, 0.55, 0.4), (0.60, 0.35, 0.35),
            ] {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: px * sz.width - pr, y: py * sz.height - pr, width: pr * 2, height: pr * 2)),
                    with: .color(.white.opacity(0.55))
                )
            }
        }
        .opacity(0.5)
        .allowsHitTesting(false)
    }

    // MARK: - Nova message queue

    private func sendNova(_ texts: [String], then: (() -> Void)? = nil) {
        bottomInput = nil
        var delay: Double = 0
        let speaking = voiceMode
        for text in texts {
            let dur = min(0.35 + Double(text.count) * 0.018, 1.1)
            let d0 = delay
            DispatchQueue.main.asyncAfter(deadline: .now() + d0) {
                withAnimation(.easeOut(duration: 0.18)) { isTyping = true }
            }
            delay += dur
            let d1 = delay; let captured = text
            DispatchQueue.main.asyncAfter(deadline: .now() + d1) {
                withAnimation(.easeOut(duration: 0.15)) {
                    isTyping = false
                    msgs.append(ChatMsg(source: .nova, text: captured))
                }
                if speaking { speak(transcript: captured) }
            }
            delay += 0.12
        }
        if let cb = then {
            let final = delay + 0.08
            DispatchQueue.main.asyncAfter(deadline: .now() + final) {
                withAnimation { cb() }
            }
        }
    }

    // MARK: - Lesson flow

    private func startIntro() {
        let introText = opening?.intro ?? fallback.intro
        sendNova([
            "Hey, space explorer! 🚀",
            "Today we're tackling \(node.label).",
            introText,
        ]) {
            bottomInput = .action(label: "Let's go! 🚀", kind: .toExample)
        }
    }

    private func startExample() {
        phase = .example
        let exQ = opening?.exampleQuestion ?? fallback.exampleQuestion
        let exA = opening?.exampleAnswer ?? fallback.exampleAnswer
        sendNova([
            "Let me show you one first. 👀",
            exQ,
            "The answer: \(exA)",
            "Got it? Now let's see what you can do! 💪",
        ]) {
            bottomInput = .action(label: "Try me! 💪", kind: .toPractice)
        }
    }

    private func startPractice() {
        phase = .practice
        kickoffNextProblem()
    }

    private func askCurrent() {
        guard let p = currentProblem else { return }
        hintTier = 0
        let i = pastOutcomes.count
        sendNova(["Q\(i + 1)/\(nProbs) · \(p.prompt)"]) {
            bottomInput = .text(problem: p, idx: i)
        }
    }

    /// #2 Tiered hint dispatcher.
    /// tier == 1: reveal the static hint immediately as a Nova hint bubble.
    /// tier == 2: ask Gemma for a deeper hint (n-body shows during the call).
    /// tier == 3: bail out — walk through the answer and advance to next.
    private func handleHintRequest(_ problem: LessonProblem, tier: Int) {
        switch tier {
        case 1:
            withAnimation(.easeOut(duration: 0.18)) {
                msgs.append(ChatMsg(source: .nova, text: problem.hint, isHint: true))
            }
        case 2:
            startThinking("\(node.emoji) Looking for a stronger nudge…")
            let context = ctx
            Task {
                let line = await LessonGenerator.deeperHint(context, problem: problem)
                await MainActor.run {
                    self.stopThinking()
                    let text = line ?? "Try thinking step by step. \(problem.hint)"
                    withAnimation(.easeOut(duration: 0.18)) {
                        self.msgs.append(ChatMsg(source: .nova, text: text, isHint: true))
                    }
                }
            }
        default:
            // Tier 3: kid is giving up — walk through and move on.
            kickoffWalkThrough(
                problem: problem,
                studentAnswer: "(skipped via Show me how)",
                hintUsed: true
            )
        }
    }

    private func handleAction(_ kind: LessonAction) {
        switch kind {
        case .toExample:  startExample()
        case .toPractice: startPractice()
        case .toDone:     onClose()
        }
    }

    private func handleAnswer(val: String, problem: LessonProblem, idx: Int, usedHint: Bool) {
        let correct = val.trimmingCharacters(in: .whitespaces).lowercased()
                      == problem.answer.trimmingCharacters(in: .whitespaces).lowercased()

        // Immediately append colored bubble — before LLM responds
        withAnimation(.easeOut(duration: 0.18)) {
            msgs.append(ChatMsg(
                source: .student,
                text: val,
                answerResult: correct ? .correct : .incorrect
            ))
        }
        bottomInput = nil

        // Fast path: trivial normalized match. Spares an LLM call when it's
        // an obvious yes (e.g. "8" == "8", "Desert" == "desert").
        if LessonView.normalizeAnswer(val) == LessonView.normalizeAnswer(problem.answer) {
            applyCorrect(val: val, problem: problem, usedHint: usedHint)
            return
        }

        // Slow path: ask Gemma to judge semantically. Handles "eight" vs "8",
        // "the desert" vs "desert", paraphrases, equivalent fractions, etc.
        startThinking("\(node.emoji) Checking your answer…")
        let context = ctx
        Task {
            let verdict = await LessonGenerator.judgeAnswer(
                context, problem: problem, studentAnswer: val
            )
            await MainActor.run {
                self.stopThinking()
                if verdict == true {
                    self.applyCorrect(val: val, problem: problem, usedHint: usedHint)
                } else {
                    // Treat nil (ambiguous) as incorrect — the kid still gets
                    // coaching, so it's a soft fail.
                    self.applyWrong(val: val, problem: problem, usedHint: usedHint)
                }
            }
        }
    }

    /// Right-answer flow: reward, mini-celebration, advance.
    private func applyCorrect(val: String, problem: LessonProblem, usedHint: Bool) {
        let bonus = (usedHint ? 8 : 15) + (streak >= 2 ? 5 : 0)
        let attemptPenalty = max(0, attempts) * 3
        streak += 1
        xpGained += max(4, bonus - attemptPenalty)
        if usedHint { hintsUsed += 1 }

        // #7 mini-celebration: pulse the XP chip and pop a star overlay.
        withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
            celebratePulse += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.25)) {
                if self.celebratePulse > 0 { self.celebratePulse -= 1 }
            }
        }

        let cheer = randomCheer() + (streak >= 3 ? " 🔥 \(streak) in a row!" : "")
        sendNova([cheer]) {
            self.recordOutcome(
                problem: problem,
                studentAnswer: val,
                correct: true,
                hintUsed: usedHint
            )
            self.kickoffNextProblem()
        }
    }

    /// Wrong-answer flow: bump attempts, escalate to coaching or walk-through.
    private func applyWrong(val: String, problem: LessonProblem, usedHint: Bool) {
        attempts += 1
        if attempts < LessonConfig.maxAttemptsPerProblem {
            kickoffCoaching(problem: problem, studentAnswer: val)
        } else {
            kickoffWalkThrough(
                problem: problem,
                studentAnswer: val,
                hintUsed: usedHint || hintTier > 0
            )
        }
    }

    private func recordOutcome(
        problem: LessonProblem,
        studentAnswer: String,
        correct: Bool,
        hintUsed: Bool
    ) {
        let outcome = PastProblemOutcome(
            prompt: problem.prompt,
            correctAnswer: problem.answer,
            studentAnswer: studentAnswer,
            correct: correct,
            attempts: max(1, attempts + (correct ? 1 : 0)),
            hintUsed: hintUsed
        )
        pastOutcomes.append(outcome)
        currentProblem = nil
        attempts = 0
    }
    
    private func celebrate() {
        phase = .celebrate
        let capXP = xpGained; let capH = hearts; let capHints = hintsUsed
        let answered = pastOutcomes.count
        let correctCount = pastOutcomes.filter { $0.correct }.count

        // #8 — unlock a piece of the constellation's skyStory as a reward,
        // scaled to performance (full lore on a clean run, a teaser otherwise).
        let info = GalaxyData.nodesById[node.id]
        var constellation: Constellation? = nil
        if let cid = info?.constellationId {
            constellation = GalaxyData.constellations.first(where: { $0.id == cid })
        }
        let skyStory: String? = constellation?.skyStory
        let unlockedLore: String? = skyStory.map { story in
            if correctCount == answered && answered > 0 {
                // Perfect run: the whole lore.
                return story
            }
            // Partial run: unlock the first sentence as a teaser.
            if let firstStop = story.firstIndex(where: { ".!?".contains($0) }) {
                return String(story[...firstStop])
            }
            return story
        }

        sendNova([
            "🎉 Lesson complete, superstar!",
            "You worked through \(answered) question\(answered == 1 ? "" : "s"). Here's how you did:",
        ]) {
            var sm = ChatMsg(source: .nova, text: "")
            sm.isStats = true
            sm.statsXP = capXP
            sm.statsHearts = capH
            sm.statsHints = capHints
            withAnimation(.easeOut(duration: 0.2)) { self.msgs.append(sm) }

            // Reveal the lore unlock (if any) shortly after stats.
            if let lore = unlockedLore, let cName = constellation?.name, let cEmoji = constellation?.emoji {
                let label = correctCount == answered
                    ? "✨ Bonus lore unlocked — \(cEmoji) \(cName):"
                    : "✨ A peek at the \(cEmoji) \(cName) story:"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.sendNova([label, lore])
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + (unlockedLore == nil ? 0.4 : 1.6)) {
                withAnimation { self.bottomInput = .action(label: "Back to galaxy 🌌", kind: .toDone) }
            }
        }

        // Persist this lesson into memory.md (and trigger compression every Nth).
        let snapshotOutcomes = pastOutcomes
        let cName = info?.constellationName
        Task {
            await MemoryStore.shared.recordLesson(
                node: node,
                constellationName: cName,
                outcomes: snapshotOutcomes,
                xpGained: capXP,
                heartsLeft: capH,
                hintsUsed: capHints
            )
        }
    }
}
// MARK: - Copy lines

private func randomCheer() -> String {
    ["You got it! ⭐","Stellar! 🚀","Nailed it! ✨","Bingo! 🎯","That's the one! 💫","Cosmic! Keep going!","Wow, nice work! 🌟"].randomElement() ?? "Nice!"
}
private func randomEncourage() -> String {
    ["No worries — let's keep going!","Every explorer gets it on the next try.","Mistakes are how we grow 🌱","Onwards and upwards!"].randomElement() ?? "Keep going!"
}

