//
//  MiniMetric.swift
//  LA Hacks
//
//  Star Hop! small stats tile used on the Quests tab.
//

import SwiftUI

// MARK: - MiniMetric

struct MiniMetric: View {
    let emoji: String
    let label: String
    let value: String
    let sub: String?
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Text(emoji).font(.system(size: 14))
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(accent)
            if let sub {
                Text(sub)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sCard(stroke: accent.opacity(0.33), padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
    }
}
