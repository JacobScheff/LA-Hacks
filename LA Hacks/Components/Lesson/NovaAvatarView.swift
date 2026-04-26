//
//  NovaAvatarView.swift
//  LA Hacks
//
//  Circular avatar for Nova, used inside lesson chat bubbles.
//

import SwiftUI

// MARK: - Nova avatar

struct NovaAvatarView: View {
    let size: CGFloat
    let pal: StarPalette

    var body: some View {
        Text("✦")
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle().fill(LinearGradient(
                    colors: [pal.mid, pal.halo],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            )
            .overlay(Circle().stroke(pal.mid.opacity(0.3), lineWidth: 2))
            .shadow(color: pal.glow, radius: 8)
    }
}
