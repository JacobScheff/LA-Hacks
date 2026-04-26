//
//  MinigameView.swift
//  LA Hacks
//
//  Star Hop! Asteroid Dodger waiting minigame shown while the model downloads.
//

import SwiftUI

// MARK: - Waiting Minigame

struct MinigameView: View {
    let progress: Float
    let onStartAdventure: () -> Void

    @StateObject private var engine = GameEngine()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Game Canvas
                Canvas { ctx, size in
                    // Draw Stars (parallax background)
                    for star in engine.stars {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: star.x, y: star.y, width: star.size, height: star.size)),
                            with: .color(.white.opacity(star.opacity))
                        )
                    }

                    // Draw Asteroids
                    for ast in engine.asteroids {
                        let text = Text(ast.emoji).font(.system(size: ast.size))
                        ctx.draw(text, at: CGPoint(x: ast.x, y: ast.y))
                    }

                    // Draw Rocket
                    if !engine.isGameOver {
                        let rocket = Text("🚀").font(.system(size: 40))
                        ctx.draw(rocket, at: CGPoint(x: engine.rocketX, y: size.height - 100))
                    } else {
                        let boom = Text("💥").font(.system(size: 50))
                        ctx.draw(boom, at: CGPoint(x: engine.rocketX, y: size.height - 100))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))

                // Interaction Layer
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                if !engine.isGameOver {
                                    engine.rocketX = min(max(20, engine.dragStartX + v.translation.width), geo.size.width - 20)
                                }
                            }
                            .onEnded { _ in
                                engine.dragStartX = engine.rocketX
                            }
                    )

                // Top HUD
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("ASTEROID DODGER")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0xFFE066))
                            Text("Score: \(engine.score)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()

                        // Download Status Pill
                        HStack(spacing: 6) {
                            if progress >= 1.0 {
                                Text("✅").font(.system(size: 12))
                                Text("Brain Downloaded!")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: 0xA0F0A0))
                            } else {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.7)
                                Text(String(format: "Downloading... %.0f%%", progress * 100))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    Spacer()
                }

                // Game Over Overlay
                if engine.isGameOver {
                    VStack(spacing: 20) {
                        Text("💥 CRASHED!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 20)

                        Text("Final Score: \(engine.score)")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: 0xFFE066))

                        if progress >= 1.0 {
                            Button(action: onStartAdventure) {
                                Text("🚀 Start Adventure!")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: 0x1A0B40))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors:[Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .shadow(color: Color(hex: 0x5EE7FF, opacity: 0.5), radius: 16, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 10)

                            Button(action: { engine.reset(width: geo.size.width) }) {
                                Text("Play Again")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                        } else {
                            Text("Nova is still downloading...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 10)

                            Button(action: { engine.reset(width: geo.size.width) }) {
                                Text("Play Again 🔄")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(hex: 0x140A32, opacity: 0.95))
                            .shadow(color: .black.opacity(0.5), radius: 20)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(hex: 0xFFE066, opacity: 0.3), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 40)
                }
            }
            .onAppear {
                engine.setup(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}
