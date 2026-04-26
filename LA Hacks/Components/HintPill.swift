//
//  HintPill.swift
//  LA Hacks
//
//  Pulsing hint pill shown above the galaxy on first launch.
//

import SwiftUI

// MARK: - Hint pill

struct HintPill: View {
    let gaps: Int
    @State private var pulse: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: 0x5EE7FF))
                .frame(width: 7, height: 7)
                .shadow(color: Color(hex: 0x5EE7FF), radius: 3)
                .opacity(pulse ? 0.5 : 1.0)
                .scaleEffect(pulse ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(), value: pulse)
            Text("😴 Tap a sleepy star to wake it up! (\(gaps))")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color(hex: 0x1C0C3C, opacity: 0.78))
                .background(.ultraThinMaterial, in: Capsule())
        )
        .overlay(
            Capsule().stroke(Color(hex: 0x5EE7FF, opacity: 0.4), lineWidth: 1.5)
        )
        .onAppear { pulse = true }
    }
}
