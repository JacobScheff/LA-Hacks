//
//  CelebrationBurst.swift
//  LA Hacks
//
//  Brief star shimmer overlay shown when the student answers correctly.
//

import SwiftUI

// MARK: - Celebration burst (#7)

/// Brief star shimmer that animates whenever `trigger` increments. Sits as
/// a translucent overlay above the chat — non-blocking, ~600ms.
struct CelebrationBurst: View {
    let trigger: Int
    let palette: StarPalette
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let angle = CGFloat(i) * .pi / 3
                let r = 60 + phase * 90
                Text("⭐")
                    .font(.system(size: 22))
                    .foregroundColor(palette.mid)
                    .opacity(Double(1.0 - phase))
                    .scaleEffect(0.6 + phase * 0.7)
                    .offset(x: cos(angle) * r, y: sin(angle) * r)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            phase = 0
            withAnimation(.easeOut(duration: 0.55)) { phase = 1 }
        }
    }
}
