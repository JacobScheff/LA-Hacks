//
//  LessonView.swift
//  LA Hacks
//
//  Star Hop! conversational tutoring — Nova chats with the student.
//  Redesigned as a chat thread matching project/lesson.jsx.
//

import SwiftUI

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

// MARK: - Lesson bank (static fallbacks for hardcoded stars)

func lessonFor(node: StarNode) -> LessonContent {
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

private enum MessageSource { case nova, student }

private struct ChatMsg: Identifiable {
    let id = UUID()
    let source: MessageSource
    let text: String
    var isHint: Bool = false
    var isStats: Bool = false
    var statsXP: Int = 0
    var statsHearts: Int = 3
    var statsHints: Int = 0
    var answerResult: AnswerResult? = nil
    enum AnswerResult { case correct, incorrect }
}

// MARK: - Input area state

private enum LessonAction { case toExample, toPractice, toDone }

private enum BottomInputKind {
    case action(label: String, kind: LessonAction)
    case mc(choices: [String], problem: LessonProblem, idx: Int)
    case text(problem: LessonProblem, idx: Int)
}

// MARK: - LessonView

struct LessonView: View {
    let node: StarNode
    let constellationName: String        // ← NEW
    let course: String                   // ← NEW
    let blurb: String?                   // ← NEW
    let siblingLabels: [String]          // ← NEW
    let onClose: () -> Void

    @StateObject private var lessonLoader = LessonLoader()  // ← NEW

    @State private var msgs: [ChatMsg] = []
    @State private var isTyping = false
    @State private var bottomInput: BottomInputKind? = nil
    @State private var hearts = 3
    @State private var xpGained = 0
    @State private var streak = 0
    @State private var hintsUsed = 0
    @State private var phase: Phase = .intro
    @State private var qIdx = 0
    @State private var hintShown = false
    @State private var questionKey = 0
    @State private var chatBreakInput: String = ""
    @State private var outcomes: [PastProblemOutcome] = []
    @FocusState private var chatBreakFocused: Bool

    @State private var stickerQueue: [StarStickerItem] = []
    @State private var currentStickerToast: StarStickerItem? = nil

    enum Phase { case intro, example, practice, chatBreak, celebrate }

    // ← REMOVED: private var lesson: LessonContent { lessonFor(node: node) }

    private var pal: StarPalette { node.status.palette }
    private var nProbs: Int { lessonLoader.lessonContent?.problems.count ?? 0 }  // ← CHANGED

    private var progress: Double {
        switch phase {
        case .intro:     return 0.02
        case .example:   return 0.10
        case .practice:  return nProbs > 0 ? 0.12 + Double(qIdx) / Double(nProbs) * 0.85 : 0.12
        case .chatBreak: return nProbs > 0 ? 0.12 + Double(qIdx) / Double(nProbs) * 0.85 : 0.12
        case .celebrate: return 1.0
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0x09041E).ignoresSafeArea()
            stardust.ignoresSafeArea()

            // ← NEW: switch on load state
            switch lessonLoader.state {

            case .idle, .generatingOpening, .generatingProblems:
                lessonLoadingView

            case .ready:
                VStack(spacing: 0) {
                    chatHeader
                    progressStrip
                    chatScroll
                    if phase == .chatBreak {
                        chatBreakInputArea
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let inp = bottomInput {
                        LessonInputArea(
                            inputKind: inp,
                            pal: pal,
                            hintShown: $hintShown,
                            questionKey: questionKey,
                            onAction: handleAction,
                            onAnswer: handleAnswer,
                            onHint: { prob in
                                withAnimation(.easeOut(duration: 0.18)) {
                                    msgs.append(ChatMsg(source: .nova, text: prob.hint, isHint: true))
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: bottomInput != nil)
                .onAppear { startIntro() }  // ← moved here from outer body

            case .failed:
                VStack(spacing: 20) {
                    Spacer()
                    Text("⚠️").font(.system(size: 48))
                    Text("Couldn't generate lesson")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Check your connection and try again.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                    Button("Try Again") {
                        lessonLoader.load(
                            node: node,
                            constellationName: constellationName,
                            course: course,
                            blurb: blurb,
                            siblingLabels: siblingLabels
                        )
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: 0x3A2A00))
                    .padding(.horizontal, 28).padding(.vertical, 12)
                    .background(Color(hex: 0xFFE066))
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // ← NEW: .task instead of .onAppear
        .task {
            lessonLoader.load(
                node: node,
                constellationName: constellationName,
                course: course,
                blurb: blurb,
                siblingLabels: siblingLabels
            )
        }
    }

    // MARK: - Loading view (NEW)

    private var lessonLoadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(node.emoji)
                .font(.system(size: 64))
            Text(lessonLoader.progressLabel)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: 0xFFE066))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if !lessonLoader.streamPreview.isEmpty {
                Text(lessonLoader.streamPreview)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(hex: 0x5EE7FF, opacity: 0.55))
                    .lineLimit(3)
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dismissesKeyboard()
        .onAppear { startIntro() }
        .overlay {
            if let sticker = currentStickerToast {
                StickerEarnedToast(sticker: sticker) {
                    currentStickerToast = nil
                    if !stickerQueue.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            currentStickerToast = stickerQueue.removeFirst()
                        }
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: currentStickerToast != nil)
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
                    if phase == .practice || phase == .chatBreak {
                        Text(" · Q\(qIdx+1)/\(nProbs)")
                            .foregroundColor(Color(hex: 0xFFCC50, opacity: 0.6))
                    }
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                if xpGained > 0 {
                    Text("+\(xpGained) XP")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFD044))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: 0xFFD044, opacity: 0.15)))
                        .overlay(Capsule().stroke(Color(hex: 0xFFD044, opacity: 0.3), lineWidth: 1))
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

    // MARK: - Progress strip

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
                    Color.clear.frame(height: 6).id("__end")
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.visible)
            .onAppear {
                proxy.scrollTo("__end", anchor: .bottom)
            }
            .onChange(of: msgs.count) {
                withAnimation { proxy.scrollTo("__end", anchor: .bottom) }
            }
            .onChange(of: isTyping) {
                withAnimation { proxy.scrollTo("__end", anchor: .bottom) }
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

    private func sendNovaAI(userQuery: String, then: (() -> Void)? = nil) {
        bottomInput = nil
        withAnimation(.easeOut(duration: 0.18)) { isTyping = true }

        let context = PipelineContext(
            activeConstellationID: GalaxyData.nodesById[node.id]?.constellationId,
            activeStarID: node.id,
            studentName: "Explorer",
            history: msgs.compactMap { m in
                guard !m.isHint && !m.isStats else { return nil }
                return ChatMessage(
                    role: m.source == .student ? .user : .assistant,
                    content: m.text
                )
            }
        )

        RAGPipeline.run(
            userQuery: userQuery,
            context: context,
            onDownload: { _ in },
            onStream: { _ in },
            onComplete: { result in
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isTyping = false
                        msgs.append(ChatMsg(source: .nova, text: result.text))
                    }
                    then?()
                }
            }
        )
    }

    // MARK: - Lesson flow

    private func startIntro() {
        // ← CHANGED: read from lessonLoader
        let intro = lessonLoader.lessonContent?.intro ?? ""
        sendNova([
            "Hey, space explorer! 🚀",
            "Today we're tackling \(node.label).",
            intro,
        ]) {
            bottomInput = .action(label: "Let's go! 🚀", kind: .toExample)
        }
    }

    private func startExample() {
        phase = .example
        // ← CHANGED: read from lessonLoader
        let exQ = lessonLoader.lessonContent?.exampleQuestion ?? ""
        let exA = lessonLoader.lessonContent?.exampleAnswer ?? ""
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
        askQ(0)
    }

    private func askQ(_ idx: Int) {
        qIdx = idx
        hintShown = false
        questionKey += 1

        // ← CHANGED: read from lessonLoader
        let problems = lessonLoader.lessonContent?.problems ?? []
        guard idx < problems.count else { celebrate(); return }
        var p = problems[idx]

        // Convert pizza → MC
        if p.kind == .pizza {
            let choices = (1...max(1, p.slices)).map { "\($0)/\(p.slices)" }
            let answer = "\(p.target)/\(p.slices)"
            let prompt = p.prompt
                .replacingOccurrences(of: "Tap to color in", with: "How many slices for")
                .replacingOccurrences(of: "Tap to show", with: "How many slices for")
            p = LessonProblem.mc(prompt, choices: choices, answer: answer, hint: p.hint)
        }

        sendNova(["Q\(idx+1)/\(nProbs) · \(p.prompt)"]) {
            switch p.kind {
            case .multipleChoice:
                bottomInput = .mc(choices: p.choices, problem: p, idx: idx)
            case .input, .pizza:
                bottomInput = .text(problem: p, idx: idx)
            }
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

        withAnimation(.easeOut(duration: 0.18)) {
            msgs.append(ChatMsg(
                source: .student,
                text: val,
                answerResult: correct ? .correct : .incorrect
            ))
        }
        bottomInput = nil

        outcomes.append(PastProblemOutcome(
            prompt: problem.prompt,
            correctAnswer: problem.answer,
            studentAnswer: val,
            correct: correct,
            attempts: 1,
            hintUsed: usedHint
        ))

        if correct {
            streak += 1
            xpGained += (usedHint ? 8 : 15) + (streak >= 2 ? 5 : 0)
        } else {
            streak = 0
            hearts = max(0, hearts - 1)
        }
        if usedHint { hintsUsed += 1 }

        let next = idx + 1
        let done = next >= nProbs

        let feedbackQuery = correct
            ? "The student answered '\(val)' which is correct for the question: '\(problem.prompt)'. Give a short encouraging response\(streak >= 3 ? " and mention their \(streak)-answer streak" : "")."
            : "The student answered '\(val)' but the correct answer is '\(problem.answer)' for the question: '\(problem.prompt)'. Gently explain why and offer to answer any questions they have."

        sendNovaAI(userQuery: feedbackQuery) {
            if done { self.celebrate() } else {
                self.phase = .chatBreak
                self.qIdx = next
            }
        }
    }

    private func celebrate() {
        phase = .celebrate
        let capXP = xpGained; let capH = hearts; let capHints = hintsUsed
        let capOutcomes = outcomes
        let correctCount = capOutcomes.filter { $0.correct }.count
        let constellationId = GalaxyData.nodesById[node.id]?.constellationId

        Task {
            await MemoryStore.shared.recordLesson(
                node: node,
                constellationName: GalaxyData.nodesById[node.id]?.constellationName,
                outcomes: capOutcomes,
                xpGained: capXP,
                heartsLeft: capH,
                hintsUsed: capHints
            )
        }
        UserSettings.shared.recordStudySession(
            xpEarned: capXP,
            nodeId: node.id,
            correctCount: correctCount,
            totalCount: capOutcomes.count,
            hintsUsed: capHints,
            constellationId: constellationId
        )

        // Show celebration overlay for each newly earned sticker
        let newIds = UserSettings.shared.recentlyUnlocked
        if !newIds.isEmpty {
            let allStickers = StarStickerData.items(
                unlocked: UserSettings.shared.unlockedStickers,
                dates: UserSettings.shared.stickerEarnedDates
            )
            let newStickers = newIds.compactMap { id in allStickers.first { $0.id == id } }
            if let first = newStickers.first {
                NotificationManager.shared.scheduleStickerEarnedNotification(
                    name: UserSettings.shared.explorerName,
                    stickerName: first.label,
                    emoji: first.emoji
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    stickerQueue = Array(newStickers.dropFirst())
                    currentStickerToast = first
                }
            }
        }

        sendNova([
            "🎉 Lesson complete, superstar!",
            "You answered all \(nProbs) questions. Here's how you did:",
        ]) {
            var sm = ChatMsg(source: .nova, text: "")
            sm.isStats = true
            sm.statsXP = capXP
            sm.statsHearts = capH
            sm.statsHints = capHints
            withAnimation(.easeOut(duration: 0.2)) { self.msgs.append(sm) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { self.bottomInput = .action(label: "Back to galaxy 🌌", kind: .toDone) }
            }
        }
    }

    // MARK: - Chat break

    private var chatBreakInputArea: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField("", text: $chatBreakInput,
                              prompt: Text("Ask Nova more about this…")
                                  .foregroundColor(.white.opacity(0.4)))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1.5))
                        .focused($chatBreakFocused)
                        .onSubmit { sendChatBreakMessage() }

                    Button(action: sendChatBreakMessage) {
                        Text("→")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(chatBreakInput.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? .white.opacity(0.25) : Color(hex: 0x1A0B40))
                            .frame(width: 48, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(chatBreakInput.trimmingCharacters(in: .whitespaces).isEmpty
                                          ? AnyShapeStyle(Color.white.opacity(0.07))
                                          : AnyShapeStyle(LinearGradient(
                                                colors: [pal.mid, pal.halo],
                                                startPoint: .topLeading, endPoint: .bottomTrailing)))
                            )
                            .shadow(color: chatBreakInput.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? .clear : pal.glow.opacity(0.6), radius: 10)
                    }
                    .buttonStyle(.plain)
                    .disabled(chatBreakInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Button(action: resumeAfterChatBreak) {
                    Text(qIdx >= nProbs ? "🎉 Finish lesson!" : "Next question →")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0x1A0B40))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(LinearGradient(colors: [pal.mid, pal.halo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: pal.glow.opacity(0.5), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(EdgeInsets(top: 12, leading: 14, bottom: 28, trailing: 14))
        }
        .background(Color(hex: 0x09041E))
    }

    private func sendChatBreakMessage() {
        let q = chatBreakInput.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        chatBreakInput = ""
        chatBreakFocused = false
        withAnimation(.easeOut(duration: 0.18)) {
            msgs.append(ChatMsg(source: .student, text: q))
        }
        sendNovaAI(userQuery: q)
    }

    private func resumeAfterChatBreak() {
        phase = .practice
        if qIdx >= nProbs { celebrate() } else { askQ(qIdx) }
    }
}

// MARK: - Copy lines

private func randomCheer() -> String {
    ["You got it! ⭐","Stellar! 🚀","Nailed it! ✨","Bingo! 🎯","That's the one! 💫","Cosmic! Keep going!","Wow, nice work! 🌟"].randomElement() ?? "Nice!"
}
private func randomEncourage() -> String {
    ["No worries — let's keep going!","Every explorer gets it on the next try.","Mistakes are how we grow 🌱","Onwards and upwards!"].randomElement() ?? "Keep going!"
}

// MARK: - Nova avatar

struct NovaAvatarView: View {
    let size: CGFloat
    let pal: StarPalette

    var body: some View {
        Image("Nova Image")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: pal.glow, radius: size * 0.3)
    }
}

// MARK: - Markdown-aware text renderer
//
// Uses AttributedString(markdown:) so Nova's messages can contain:
//   **bold**  *italic*  `code`  ~~strikethrough~~  [link](url)
// Falls back to plain Text if the string fails to parse (shouldn't happen in practice).
// .inlineOnlyPreservingWhitespace keeps newlines but skips block-level syntax
// (headers, HR, fenced code blocks) which would look wrong in a chat bubble.

private struct MarkdownText: View {
    let text: String
    var fontSize: CGFloat = 14.5
    var weight: Font.Weight = .regular
    var color: Color = Color(hex: 0xE8D8FF)
    var lineSpacing: CGFloat = 2

    private var attributed: AttributedString {
        let opts = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: text, options: opts))
            ?? AttributedString(text)
    }

    var body: some View {
        Text(attributed)
            .font(.system(size: fontSize, weight: weight, design: .rounded))
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
    }
}

// MARK: - Chat bubble

private struct MsgBubble: View {
    let msg: ChatMsg
    let pal: StarPalette

    var body: some View {
        if msg.isStats {
            statsBubble
        } else if msg.source == .nova {
            novaBubble
        } else {
            studentBubble
        }
    }

    private var novaBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            MarkdownText(
                text: msg.text,
                color: msg.isHint ? Color(hex: 0x5EE7FF) : Color(hex: 0xE8D8FF)
            )
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(msg.isHint ? Color(hex: 0x5EE7FF, opacity: 0.1) : Color(hex: 0x201048, opacity: 0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(msg.isHint ? Color(hex: 0x5EE7FF, opacity: 0.3) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
            Spacer(minLength: 44)
        }
    }

    private var studentBubble: some View {
        HStack {
            Spacer(minLength: 44)
            Text(msg.text)
                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(2)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            msg.answerResult == .correct
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: 0x34C759), Color(hex: 0x30B354)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                : msg.answerResult == .incorrect
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: 0xFF3B30), Color(hex: 0xD93025)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: 0xFF8A4C), Color(hex: 0xFFCC44)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                )
                .shadow(color: msg.answerResult == .correct
                            ? Color(hex: 0x34C759, opacity: 0.4)
                            : msg.answerResult == .incorrect
                            ? Color(hex: 0xFF3B30, opacity: 0.4)
                            : Color(hex: 0xFF8A4C, opacity: 0.3),
                        radius: 8, x: 0, y: 2)
        }
    }

    private var statsBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                statTile("✨", label: "XP earned",   val: "+\(msg.statsXP)",      c: Color(hex: 0xFFE066))
                statTile("❤️", label: "Hearts left", val: "\(msg.statsHearts)/3", c: Color(hex: 0xFF8AD8))
                statTile("💡", label: "Hints used",  val: "\(msg.statsHints)",    c: Color(hex: 0x5EE7FF))
                statTile("🔥", label: "Streak",      val: "+1 day",               c: Color(hex: 0xFF8A4C))
            }
            .frame(width: 240)
            Spacer(minLength: 0)
        }
    }

    private func statTile(_ icon: String, label: String, val: String, c: Color) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 16))
            Text(val)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(c)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(0.3)
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8).padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Typing indicator

private struct TypingBubble: View {
    let pal: StarPalette
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            BouncingDots()
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0x201048, opacity: 0.9)))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        }
    }
}

private struct BouncingDots: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate * 4.5
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 6, height: 6)
                        .offset(y: CGFloat(sin(t + Double(i) * 0.7) * -3.5))
                }
            }
        }
    }
}

// MARK: - Bottom input area

private struct LessonInputArea: View {
    let inputKind: BottomInputKind
    let pal: StarPalette
    @Binding var hintShown: Bool
    let questionKey: Int
    let onAction: (LessonAction) -> Void
    let onAnswer: (String, LessonProblem, Int, Bool) -> Void
    let onHint: (LessonProblem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            Group {
                switch inputKind {
                case .action(let label, let kind):
                    actionView(label: label, kind: kind)
                case .mc(let choices, let problem, let idx):
                    MCChoicesView(choices: choices, problem: problem, idx: idx, pal: pal, hintShown: $hintShown, onAnswer: onAnswer, onHint: onHint)
                        .id(questionKey)
                case .text(let problem, let idx):
                    TextInputView(problem: problem, idx: idx, pal: pal, hintShown: $hintShown, onAnswer: onAnswer, onHint: onHint)
                        .id(questionKey)
                }
            }
            .padding(EdgeInsets(top: 12, leading: 14, bottom: 28, trailing: 14))
        }
        .background(Color(hex: 0x09041E))
    }

    private func actionView(label: String, kind: LessonAction) -> some View {
        Button(action: { onAction(kind) }) {
            Text(label)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x1A0B40))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: [pal.mid, pal.halo], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: pal.glow, radius: 16, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MC choices

private struct MCChoicesView: View {
    let choices: [String]
    let problem: LessonProblem
    let idx: Int
    let pal: StarPalette
    @Binding var hintShown: Bool
    let onAnswer: (String, LessonProblem, Int, Bool) -> Void
    let onHint: (LessonProblem) -> Void
    @State private var tapped: String? = nil

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(choices.enumerated()), id: \.offset) { i, ch in
                let isTapped = tapped == ch
                Button(action: {
                    guard tapped == nil else { return }
                    tapped = ch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                        onAnswer(ch, problem, idx, hintShown)
                    }
                }) {
                    HStack(spacing: 10) {
                        Text(String(UnicodeScalar(65 + i)!))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(isTapped ? .white : Color(hex: 0xC8AAF0, opacity: 0.8))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(isTapped ? Color.white.opacity(0.25) : Color.white.opacity(0.08)))
                        Text(ch)
                            .font(.system(size: 14, weight: isTapped ? .bold : .medium, design: .rounded))
                            .foregroundColor(isTapped ? .white : Color(hex: 0xE6D2FF, opacity: 0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isTapped
                                  ? AnyShapeStyle(LinearGradient(colors: [pal.mid.opacity(0.8), pal.halo.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color.white.opacity(0.055)))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isTapped ? pal.mid : Color.white.opacity(0.12), lineWidth: 1.5))
                    .shadow(color: isTapped ? pal.glow.opacity(0.5) : .clear, radius: 8)
                    .animation(.easeOut(duration: 0.15), value: isTapped)
                }
                .buttonStyle(.plain)
                .disabled(tapped != nil)
            }
            HintButton(problem: problem, hintShown: $hintShown, onHint: onHint)
        }
    }
}

// MARK: - Text input

private struct TextInputView: View {
    let problem: LessonProblem
    let idx: Int
    let pal: StarPalette
    @Binding var hintShown: Bool
    let onAnswer: (String, LessonProblem, Int, Bool) -> Void
    let onHint: (LessonProblem) -> Void
    @State private var textVal = ""

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("", text: $textVal, prompt: Text("Your answer…").foregroundColor(.white.opacity(0.4)))
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1.5))
                    .onSubmit { submit() }
                Button(action: submit) {
                    Text("→")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(textVal.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.25) : Color(hex: 0x1A0B40))
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(textVal.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? AnyShapeStyle(Color.white.opacity(0.07))
                                      : AnyShapeStyle(LinearGradient(colors: [pal.mid, pal.halo], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        )
                        .shadow(color: textVal.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : pal.glow.opacity(0.6), radius: 10)
                }
                .buttonStyle(.plain)
                .disabled(textVal.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            HintButton(problem: problem, hintShown: $hintShown, onHint: onHint)
        }
    }

    private func submit() {
        let v = textVal.trimmingCharacters(in: .whitespaces)
        guard !v.isEmpty else { return }
        onAnswer(v, problem, idx, hintShown)
    }
}

// MARK: - Hint button

private struct HintButton: View {
    let problem: LessonProblem
    @Binding var hintShown: Bool
    let onHint: (LessonProblem) -> Void

    var body: some View {
        if !hintShown && !problem.hint.isEmpty {
            Button(action: { hintShown = true; onHint(problem) }) {
                HStack(spacing: 6) {
                    Text("💡 Show hint")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: 0x5EE7FF))
                    Text("(−7 XP)")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: 0x5EE7FF, opacity: 0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(hex: 0x5EE7FF, opacity: 0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            }
            .buttonStyle(.plain)
        }
    }
}
