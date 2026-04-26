//
//  PathsTab.swift
//  LA Hacks
//
//  Trips tab — multi-step learning paths.
//  Extracted from GalaxyTabs.swift.
//

import SwiftUI

// MARK: - Trips (PathsTab)

struct PathsTab: View {

    private struct Trip: Identifiable {
        let id: String
        let title: String
        let kicker: String
        let desc: String
        let stars: [String]
        let progress: Double
        let minutes: Int
        let hue: Color
        let reward: String
    }

    private let trips: [Trip] = [
        Trip(
            id: "pizza",
            title: "Pizza Master Trip",
            kicker: "🍕 SLICE & SHARE",
            desc: "Slice, share, and add fractions like a pizza wizard!",
            stars:["Halves", "Read", "Equal", "Compare", "Add", "Mixed", "Simplify"],
            progress: 0.4, minutes: 80,
            hue: Color(hex: 0xFF8AD8),
            reward: "🍕 Pizza Chef sticker"
        ),
        Trip(
            id: "space",
            title: "Space Explorer",
            kicker: "🪐 BLAST OFF",
            desc: "Visit every planet and become Earth's tiniest astronaut!",
            stars:["Sun", "Seasons", "Weather", "Water", "Planets"],
            progress: 0.55, minutes: 70,
            hue: Color(hex: 0xA78BFA),
            reward: "🚀 Space Cadet badge"
        ),
        Trip(
            id: "story",
            title: "Story Wizard",
            kicker: "✨ TELL TALES",
            desc: "Read, write, and craft your very own story.",
            stars:["Smooth Read", "Main Idea", "Details", "Theme", "Story"],
            progress: 0.42, minutes: 90,
            hue: Color(hex: 0xFFE066),
            reward: "📖 Wizard hat"
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TabHeader(
                    kicker: "🗺️ ADVENTURES",
                    title: "Trips",
                    emoji: "🚀",
                    subtitle: "Big journeys that unlock big rewards!"
                )

                VStack(spacing: 14) {
                    ForEach(trips) { p in tripCard(p) }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 70)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
    }

    private func tripCard(_ p: Trip) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(p.kicker)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(p.hue)
                    .padding(.bottom, 4)
                Text(p.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                    .foregroundColor(.white)
                    .padding(.bottom, 6)
                Text(p.desc)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 14)

                PathStrip(stars: p.stars, progress: p.progress, hue: p.hue)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors:[p.hue.opacity(0.13), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .overlay(
                Rectangle()
                    .fill(p.hue.opacity(0.2))
                    .frame(height: 1),
                alignment: .bottom
            )

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int((p.progress * 100).rounded()))% lit · \(p.minutes) min")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(p.hue)
                    Text("🎁 Reward: \(p.reward)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Button(action: {}) {
                    Text("Go! →")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0x1A0B40))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [p.hue, p.hue.opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: p.hue.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(p.hue.opacity(0.33), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
