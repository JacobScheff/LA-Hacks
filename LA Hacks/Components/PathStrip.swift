//
//  PathStrip.swift
//  LA Hacks
//
//  Star Hop! visual progress strip used in PathsTab trip cards.
//

import SwiftUI

struct PathStrip: View {
    let stars: [String]
    let progress: Double
    let hue: Color

    var body: some View {
        let litCount = Int((Double(stars.count) * progress).rounded())
        ZStack(alignment: .top) {
            // line behind
            GeometryReader { g in
                let lit = g.size.width * CGFloat(progress)
                HStack(spacing: 0) {
                    Rectangle().fill(hue).frame(width: lit, height: 2)
                        .shadow(color: hue, radius: 4)
                    Rectangle().fill(Color.white.opacity(0.15)).frame(height: 2)
                }
            }
            .frame(height: 2)
            .padding(.top, 13)
            .padding(.horizontal, 6)

            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(stars.enumerated()), id: \.offset) { idx, s in
                    let lit = idx < litCount
                    VStack(spacing: 6) {
                        Circle()
                            .fill(lit ? hue : Color.white.opacity(0.18))
                            .frame(width: lit ? 14 : 10, height: lit ? 14 : 10)
                            .overlay(
                                Circle().stroke(
                                    lit ? Color.white : Color.white.opacity(0.3),
                                    lineWidth: lit ? 2 : 1.5
                                )
                            )
                            .shadow(color: lit ? hue : .clear, radius: lit ? 6 : 0)
                            .padding(.top, lit ? 7 : 9)
                        Text(s)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(lit ? .white : .white.opacity(0.5))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 44)
    }
}
