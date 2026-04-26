//
//  TabHeader.swift
//  LA Hacks
//
//  Star Hop! shared TabHeader used in Quests, Trips, Nova AI, Settings tabs.
//  Ported from project/tabs.jsx.
//

import SwiftUI

// MARK: - Shared

struct TabHeader: View {
    let kicker: String
    let title: String
    let emoji: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(kicker)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.5)
                .foregroundColor(Color(hex: 0xFFE066))
                .shadow(color: Color(hex: 0xFFE066, opacity: 0.5), radius: 6)
            Text("\(emoji) \(title)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .foregroundColor(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }
}

extension View {
    func sCard(stroke: Color = Color.white.opacity(0.12), padding: EdgeInsets = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(stroke, lineWidth: 1.5)
            )
    }
}
