//
//  MasteryRing.swift
//  LA Hacks
//
//  Star Hop! MasteryRing.
//  Ported from project/galaxy-ui.jsx.
//

import SwiftUI

// MARK: - Mastery ring

struct MasteryRing: View {
    let value: Double
    let color: Color
    let emoji: String
    var size: CGFloat = 78

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 4)
            Circle()
                .trim(from: 0, to: max(0.0, min(1.0, value)))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color, radius: 6)
            Text(emoji).font(.system(size: 28))
        }
        .frame(width: size, height: size)
    }
}
