//
//  Onboard.swift
//  LA Hacks
//
//  Star Hop! initial onboarding & background model download.
//

import SwiftUI
import ZeticMLange
import Combine

// MARK: - Onboarding Steps

enum OnboardStep {
    case intro
    case starting
    case name
    case interests
    case game
}

// MARK: - Onboard View

struct Onboard: View {
    @AppStorage("onboarded") private var onboarded: Bool = false

    @State private var step: OnboardStep = .intro
    @State private var downloadProgress: Float = 0.0
    @State private var userName: String = ""
    @State private var selectedInterests: Set<String> = []

    var body: some View {
        ZStack {
            // Shared Deep Space Backdrop
            ZStack {
                Color(hex: 0x08041A)
                RadialGradient(
                    colors:[Color(hex: 0x3C145A, opacity: 0.6), Color(hex: 0x08041A, opacity: 1)],
                    center: UnitPoint(x: 0.5, y: 0.3),
                    startRadius: 0, endRadius: 700
                )
                dustOverlay
            }
            .ignoresSafeArea()

            // Step Routing
            switch step {
            case .intro:
                introView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .starting:
                startingView
                    .transition(.opacity)
            case .name:
                nameView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .interests:
                interestsView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .game:
                MinigameView(
                    progress: downloadProgress,
                    onStartAdventure: {
                        withAnimation(.easeOut(duration: 0.5)) {
                            onboarded = true
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
        .preferredColorScheme(.dark)
    }

    // MARK: - Views

    private var introView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack(alignment: .topTrailing) {
                Image("Nova Image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .shadow(color: Color(hex: 0x5EE7FF, opacity: 0.5), radius: 30)
                Text("✨")
                    .font(.system(size: 28))
                    .offset(x: 8, y: -8)
            }

            VStack(spacing: 12) {
                Text("Welcome to Star Hop!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .tracking(-0.5)
                    .foregroundColor(.white)

                Text("Nova is your super-smart AI tutor who lives on your device. To help you learn anything, we need to download Nova's brain!")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("⚠️").font(.system(size: 14))
                    Text("Takes ~5-6GB of space. Best on Wi-Fi!")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFE066))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color(hex: 0xFFE066, opacity: 0.15)))
                .overlay(Capsule().stroke(Color(hex: 0xFFE066, opacity: 0.4), lineWidth: 1.5))
            }
            .padding(.top, 8)

            Spacer()

            Button(action: startModelDownload) {
                Text("🚀 Download Nova's Brain")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x1A0B40))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors:[Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color(hex: 0xFF8A4C, opacity: 0.5), radius: 16, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private var startingView: some View {
        VStack(spacing: 30) {
            Spacer()

            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        let phase = (t + Double(i) * 0.8).truncatingRemainder(dividingBy: 2.4) / 2.4
                        Circle()
                            .stroke(Color(hex: 0xFFE066, opacity: 0.6 * (1 - phase)), lineWidth: 3)
                            .scaleEffect(0.5 + 1.2 * phase)
                    }
                    Image("Nova Image")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(1.0 + 0.05 * sin(t * 3))
                }
                .frame(width: 200, height: 200)
            }

            VStack(spacing: 12) {
                Text("Waking up the stars...")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Warming up Nova's engines. Hold tight!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            VStack(spacing: 8) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(LinearGradient(
                                colors:[Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(10, g.size.width * CGFloat(min(1.0, downloadProgress / 0.07))))
                            .shadow(color: Color(hex: 0x5EE7FF, opacity: 0.5), radius: 6)
                    }
                }
                .frame(height: 10)

                Text(String(format: "Starting up... %.0f%%", min(100, (downloadProgress / 0.07) * 100)))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: 0x5EE7FF))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    private var nameView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer().frame(height: 60)

            Text("What's your name, Captain?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)

            TextField("", text: $userName, prompt: Text("Enter your name...").foregroundColor(.white.opacity(0.4)))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xFFE066, opacity: 0.5), lineWidth: 2)
                )
                .padding(.horizontal, 24)

            Spacer()

            Button(action: { step = .interests }) {
                Text("Next →")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(userName.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.4) : Color(hex: 0x1A0B40))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(userName.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? AnyShapeStyle(Color.white.opacity(0.1))
                                  : AnyShapeStyle(LinearGradient(
                                    colors:[Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
            }
            .buttonStyle(.plain)
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private var interestsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer().frame(height: 60)

            Text("Pick your favorite missions!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)

            Text("We'll map out stars tailored just for you.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 24)
                .padding(.top, -10)

            let chips = [
                ("Space", "🪐"), ("Dinosaurs", "🦖"), ("Math", "➗"),
                ("Reading", "📖"), ("Art", "🎨"), ("Coding", "💻"),
                ("Animals", "🦊"), ("History", "🏛️")
            ]

            LazyVGrid(columns:[GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(chips, id: \.0) { chip in
                    let isSelected = selectedInterests.contains(chip.0)
                    Button(action: {
                        if isSelected { selectedInterests.remove(chip.0) }
                        else { selectedInterests.insert(chip.0) }
                    }) {
                        HStack {
                            Text(chip.1).font(.system(size: 20))
                            Text(chip.0)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(isSelected ? Color(hex: 0x1A0B40) : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isSelected
                                      ? AnyShapeStyle(LinearGradient(colors:[Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                      : AnyShapeStyle(Color.white.opacity(0.08)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: { step = .game }) {
                Text("Let's go! 🚀")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(selectedInterests.isEmpty ? .white.opacity(0.4) : Color(hex: 0x1A0B40))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(selectedInterests.isEmpty
                                  ? AnyShapeStyle(Color.white.opacity(0.1))
                                  : AnyShapeStyle(LinearGradient(
                                    colors:[Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedInterests.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Handlers

    private func startModelDownload() {
        step = .starting

        Task.detached {
            do {
                if sharedModel == nil {
                    // Start ZeticMLangeLLMModel initialization with the download callback
                    sharedModel = try ZeticMLangeLLMModel(
                        // Assuming `personalToken` is a global config variable in your app scope
                        personalKey: Bundle.main.infoDictionary?["personalToken"] as! String,
                        name: "changgeun/gemma-4-E2B-it",
                        version: 1,
                        modelMode: .RUN_SPEED,
                        onDownload: { progress in
                            DispatchQueue.main.async {
                                self.downloadProgress = progress

                                // Reached initial threshold -> move to interactive setup
                                if self.step == .starting && progress >= 0.07 {
                                    self.step = .name
                                }
                            }
                        }
                    )
                }

                // When finished downloading and loading model (or if already fully loaded):
                DispatchQueue.main.async {
                    self.downloadProgress = 1.0

                    // Fix: If it was completely instant (already downloaded),
                    // advance the step so the user doesn't get stuck at 100%.
                    if self.step == .starting {
                        // Brief 0.8s delay to allow the user to see the successful progress bar
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            if self.step == .starting {
                                self.step = .name
                            }
                        }
                    }
                }

            } catch {
                print("Model Download/Init Failed: \(error)")
            }
        }
    }

    // Abstracted Faint Star Background
    private var dustOverlay: some View {
        Canvas { ctx, size in
            let pts: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (0.18, 0.22, 0.7, 0.50), (0.82, 0.38, 0.6, 0.40),
                (0.35, 0.78, 0.6, 0.40), (0.70, 0.92, 0.6, 0.30),
                (0.50, 0.52, 0.5, 0.22), (0.10, 0.55, 0.4, 0.30)
            ]
            for (px, py, pr, op) in pts {
                let x = px * size.width, y = py * size.height
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - pr, y: y - pr, width: pr * 2, height: pr * 2)),
                    with: .color(.white.opacity(op))
                )
            }
        }
        .allowsHitTesting(false)
        .opacity(0.6)
    }
}

// MARK: - Game Engine State

class GameEngine: ObservableObject {
    @Published var rocketX: CGFloat = 200
    @Published var isGameOver: Bool = false
    @Published var score: Int = 0

    var dragStartX: CGFloat = 200

    struct Asteroid {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var speed: CGFloat
        var size: CGFloat
        var emoji: String
    }

    struct Star {
        var x: CGFloat
        var y: CGFloat
        var speed: CGFloat
        var size: CGFloat
        var opacity: Double
    }

    @Published var asteroids: [Asteroid] = []
    @Published var stars: [Star] = []

    private var screenWidth: CGFloat = 400
    private var screenHeight: CGFloat = 800
    private var timer: Timer?
    private var frames: Int = 0

    func setup(width: CGFloat, height: CGFloat) {
        self.screenWidth = width
        self.screenHeight = height
        reset(width: width)
    }

    func reset(width: CGFloat) {
        rocketX = width / 2
        dragStartX = width / 2
        asteroids.removeAll()
        score = 0
        frames = 0
        isGameOver = false

        // Generate initial parallax stars
        stars = (0..<40).map { _ in
            Star(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: 0...screenHeight),
                speed: CGFloat.random(in: 1...4),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.2...0.8)
            )
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    private func update() {
        guard !isGameOver else { return }
        frames += 1

        // Base Speed and Spawn Rate increase over time
        let difficultyMultiplier = 1.0 + CGFloat(frames) / 1800.0 // increases slightly every 30s

        // Score updates
        if frames % 10 == 0 { score += 1 }

        // Move Stars
        for i in stars.indices {
            stars[i].y += stars[i].speed * difficultyMultiplier
            if stars[i].y > screenHeight {
                stars[i].y = -10
                stars[i].x = CGFloat.random(in: 0...screenWidth)
            }
        }

        // Move Asteroids
        for i in asteroids.indices {
            asteroids[i].y += asteroids[i].speed * difficultyMultiplier
        }

        // Cleanup offscreen Asteroids
        asteroids.removeAll { $0.y > screenHeight + 50 }

        // Spawn Asteroids
        let spawnChance = 0.03 * Double(difficultyMultiplier)
        if Double.random(in: 0...1) < spawnChance {
            let sizes: [CGFloat] = [24, 32, 40, 48]
            let emojis = ["🪨", "☄️", "🪐", "🛰️"]
            asteroids.append(Asteroid(
                x: CGFloat.random(in: 20...(screenWidth-20)),
                y: -50,
                speed: CGFloat.random(in: 4...8),
                size: sizes.randomElement()!,
                emoji: emojis.randomElement()!
            ))
        }

        // Collision Detection (Rocket Y is fixed at screenHeight - 100)
        let rocketY = screenHeight - 100
        let rocketRadius: CGFloat = 20

        for ast in asteroids {
            let hitRadius = (ast.size / 2) * 0.8 // slightly forgiving hitbox
            let dist = hypot(rocketX - ast.x, rocketY - ast.y)
            if dist < (rocketRadius + hitRadius) {
                isGameOver = true
                timer?.invalidate()
                break
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
