//
//  NavTabButton.swift
//  LA Hacks
//
//  Single tab button in CustomBottomNav.
//

import SwiftUI

struct NavTabButton: View {
    let tabVal: GalaxyTab
    let label: String
    let emoji: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(emoji)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)

                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.0)
            }
            .foregroundColor(isActive ? Color(hex: 0xFFE066) : .white.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, isActive ? 14 : 10)
            .background(
                Group {
                    if isActive {
                        LinearGradient(
                            colors: [Color(hex: 0xFFE066, opacity: 0.22), Color(hex: 0xFF8AD8, opacity: 0.18)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(hex: 0xFFE066, opacity: 0.5), lineWidth: 1.5)
                        )
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .offset(y: isActive ? -3 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: isActive)
    }
}
