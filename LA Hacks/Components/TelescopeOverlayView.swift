//
//  TelescopeOverlayView.swift
//  LA Hacks
//
//  Telescope eyepiece overlay used as a warp-in page transition.
//

import SwiftUI

// MARK: - Telescope overlay (warp-in page transition)

struct TelescopeOverlayView: View {
    let viewW: CGFloat
    let viewH: CGFloat
    var lensRotation: Double = 0   // radians; driven by parent warp animation

    var body: some View {
        let cx = viewW / 2
        let cy = viewH * 0.48
        let r  = viewW * 0.46

        Canvas { ctx, _ in
            // Vignette: clear inside eyepiece, dark outside
            ctx.fill(
                Path(CGRect(x: 0, y: 0, width: viewW, height: viewH)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .clear,                      location: 0.00),
                        .init(color: .clear,                      location: 0.80),
                        .init(color: .black.opacity(0.90),        location: 0.91),
                        .init(color: .black.opacity(0.99),        location: 0.97),
                        .init(color: Color(hex: 0x020108),        location: 1.00),
                    ]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: 0, endRadius: r
                )
            )

            // Chromatic aberration fringe
            ctx.fill(
                Path(CGRect(x: 0, y: 0, width: viewW, height: viewH)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .clear,                                                  location: 0.74),
                        .init(color: Color(red: 0.24, green: 0.31, blue: 1.0, opacity: 0.13), location: 0.82),
                        .init(color: Color(red: 1.0,  green: 0.16, blue: 0.24, opacity: 0.10), location: 0.87),
                        .init(color: .clear,                                                  location: 0.92),
                    ]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: 0, endRadius: r
                )
            )

            // Hard eyepiece rim
            let rimR = r + 18
            let rimPath = Path(ellipseIn: CGRect(x: cx - rimR, y: cy - rimR, width: rimR * 2, height: rimR * 2))
            ctx.stroke(rimPath, with: .color(Color(red: 0.12, green: 0.12, blue: 0.20, opacity: 0.98)), lineWidth: 38)
            ctx.stroke(rimPath, with: .color(Color(red: 0.35, green: 0.41, blue: 0.55, opacity: 0.55)), lineWidth: 2)

            // Inner rim line
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - (r-1), y: cy - (r-1), width: (r-1)*2, height: (r-1)*2)),
                with: .color(Color(red: 0.51, green: 0.61, blue: 0.78, opacity: 0.30)),
                lineWidth: 1.5
            )

            // Outer focus-barrel ring — asymmetric so rotation is legible.
            // Layout: bright index mark at i=0, then a 60° gap (i=1..6 skipped),
            // then regular ticks resume. The gap sweeping around makes spinning obvious.
            let outerTickColor  = Color(red: 0.71, green: 0.82, blue: 1.0, opacity: 0.26)
            let outerIndexColor = Color(red: 0.71, green: 0.82, blue: 1.0, opacity: 0.70)
            var outerTicks = Path()
            var outerIndex = Path()
            for i in 0..<36 {
                if i >= 1 && i <= 6 { continue }    // 60° gap right after the index mark
                let theta = Double(i) * (.pi / 18.0) + lensRotation
                let isMajor = (i % 3 == 0)
                let isIndex = (i == 0)
                let innerR = r * (isIndex ? 0.76 : isMajor ? 0.81 : 0.84)
                let p1 = CGPoint(x: cx + CGFloat(cos(theta)) * innerR,
                                 y: cy + CGFloat(sin(theta)) * innerR)
                let p2 = CGPoint(x: cx + CGFloat(cos(theta)) * r * 0.87,
                                 y: cy + CGFloat(sin(theta)) * r * 0.87)
                if isIndex {
                    outerIndex.move(to: p1); outerIndex.addLine(to: p2)
                } else {
                    outerTicks.move(to: p1); outerTicks.addLine(to: p2)
                }
            }
            ctx.stroke(outerTicks, with: .color(outerTickColor), lineWidth: 0.7)
            ctx.stroke(outerIndex, with: .color(outerIndexColor), lineWidth: 1.5)

            // Inner focus-barrel ring — 24 ticks, counter-rotates at 0.6×.
            // Gap at i=14..17 (different clock position keeps the two rings readable).
            var innerTicks = Path()
            var innerIndex = Path()
            for i in 0..<24 {
                if i >= 14 && i <= 17 { continue }  // 60° gap
                let theta = Double(i) * (.pi / 12.0) - lensRotation * 0.6
                let isMajor = (i % 4 == 0)
                let isIndex = (i == 0)
                let innerR = r * (isIndex ? 0.61 : isMajor ? 0.63 : 0.65)
                let p1 = CGPoint(x: cx + CGFloat(cos(theta)) * innerR,
                                 y: cy + CGFloat(sin(theta)) * innerR)
                let p2 = CGPoint(x: cx + CGFloat(cos(theta)) * r * 0.70,
                                 y: cy + CGFloat(sin(theta)) * r * 0.70)
                if isIndex {
                    innerIndex.move(to: p1); innerIndex.addLine(to: p2)
                } else {
                    innerTicks.move(to: p1); innerTicks.addLine(to: p2)
                }
            }
            ctx.stroke(innerTicks, with: .color(Color(red: 0.71, green: 0.82, blue: 1.0, opacity: 0.16)), lineWidth: 0.5)
            ctx.stroke(innerIndex, with: .color(Color(red: 0.71, green: 0.82, blue: 1.0, opacity: 0.50)), lineWidth: 1.0)

        }
        .frame(width: viewW, height: viewH)
    }
}
