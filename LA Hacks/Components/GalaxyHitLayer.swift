//
//  GalaxyHitLayer.swift
//  LA Hacks
//
//  Invisible hit-test layer over the SkyCanvas for star/constellation taps.
//

import SwiftUI

// MARK: - Hit-test layer

struct GalaxyHitLayer: View {
    let constellations: [Constellation]
    let tx: CGFloat
    let ty: CGFloat
    let scale: CGFloat
    let showDiscoverNebula: Bool
    let onTapStar: (StarNode) -> Void
    let onTapConstellation: (Constellation) -> Void
    let onTapDiscover: () -> Void

    var body: some View {
        ZStack {
            // Star hit targets
            ForEach(constellations) { c in
                ForEach(c.nodes) { n in
                    Color.clear
                        .frame(width: max(n.size * 6, 32), height: max(n.size * 6, 32))
                        .contentShape(Circle())
                        .position(worldToScreen(CGPoint(x: n.x, y: n.y)))
                        .onTapGesture { onTapStar(n) }
                        .allowsHitTesting(true)
                }
            }
            // Constellation name buttons (above each constellation)
            ForEach(constellations) { c in
                let minY = c.nodes.map(\.y).min() ?? c.centroid.y
                Color.clear
                    .frame(width: 200 * scale, height: 32 * scale)
                    .contentShape(Rectangle())
                    .position(worldToScreen(CGPoint(x: c.centroid.x, y: minY - 22)))
                    .onTapGesture { onTapConstellation(c) }
                    .allowsHitTesting(true)
            }
            // Discover nebula tap
            if showDiscoverNebula {
                Color.clear
                    .frame(width: 240 * scale, height: 240 * scale)
                    .contentShape(Circle())
                    .position(worldToScreen(CGPoint(x: 760, y: 1450)))
                    .onTapGesture { onTapDiscover() }
                    .allowsHitTesting(true)
            }
        }
    }

    private func worldToScreen(_ p: CGPoint) -> CGPoint {
        let wsc: CGFloat = 1.3
        return CGPoint(x: p.x * scale * wsc + tx, y: p.y * scale * wsc + ty)
    }
}
