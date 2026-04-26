//
//  ReadingScreen.swift
//  LA Hacks
//
//  Star Hop! analysis-animation screen between upload and reveal.
//  Ported from project/galaxy-upload.jsx.
//

import SwiftUI

// MARK: - ReadingScreen

struct ReadingScreen: View {
    let stage: Int

    private let messages = [
        "Nova is squinting at every word…",
        "Spotting big ideas…",
        "Sorting them into stars…",
        "Almost ready! ✨",
    ]

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x2A0F5C), Color(hex: 0x0E0626)],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0, endRadius: 700
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()
                hero
                Text("✨ READING YOUR DOC")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundColor(Color(hex: 0xFFE066))
                Text("Nova is investigating…")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(messages[min(stage, messages.count - 1)])
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(minHeight: 22)

                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(i <= stage ? Color(hex: 0xFFE066) : Color.white.opacity(0.15))
                            .frame(width: i <= stage ? 24 : 8, height: 8)
                            .shadow(color: i <= stage ? Color(hex: 0xFFE066, opacity: 0.7) : .clear, radius: 4)
                            .animation(.easeOut(duration: 0.3), value: stage)
                    }
                }
                .padding(.top, 6)
                Spacer()
            }
        }
    }

    private var hero: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                // Pulsing rings
                ForEach(0..<3, id: \.self) { i in
                    let phase = (t + Double(i) * 0.6).truncatingRemainder(dividingBy: 2.4) / 2.4
                    Circle()
                        .stroke(Color(hex: 0xFFE066, opacity: 0.5 * (1 - phase)), lineWidth: 2)
                        .scaleEffect(0.8 + 0.8 * phase)
                }
                .frame(width: 200, height: 200)

                // Flying docs around
                ForEach(0..<5, id: \.self) { i in
                    let dur = 2.6
                    let phase = (t + Double(i) * 0.3).truncatingRemainder(dividingBy: dur) / dur
                    let p = 1.0 - phase
                    let starts: [CGSize] = [
                        CGSize(width: -110, height: -80),
                        CGSize(width:  120, height: -90),
                        CGSize(width: -130, height:  60),
                        CGSize(width:  110, height:  70),
                        CGSize(width:    0, height: -130),
                    ]
                    let st = starts[i]
                    let alpha = phase < 0.15 ? phase / 0.15 : phase > 0.9 ? (1 - phase) / 0.1 * 0.6 : 1.0
                    Text("📄")
                        .font(.system(size: 30))
                        .offset(x: CGFloat(p) * st.width, y: CGFloat(p) * st.height)
                        .scaleEffect(0.4 + 0.6 * phase)
                        .opacity(alpha)
                }

                // Center: Nova with magnifier
                ZStack {
                    Image("Nova Image")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                    Text("🔍")
                        .font(.system(size: 40))
                        .offset(x: 28, y: 30 + CGFloat(sin(t * 1.8)) * 4)
                }

                // Sparkles around the edge
                Group {
                    Text("✨").position(x: 30, y: 30)
                    Text("⭐").position(x: 180, y: 50)
                    Text("💫").position(x: 30, y: 180)
                    Text("✨").position(x: 180, y: 180)
                }
                .font(.system(size: 18))
                .scaleEffect(1.0 + 0.2 * CGFloat(sin(t * 3.5)))
            }
            .frame(width: 220, height: 220)
        }
    }
}
