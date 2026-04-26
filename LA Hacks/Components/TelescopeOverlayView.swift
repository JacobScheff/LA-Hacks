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

            // Lens reflection rings
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - r*0.87, y: cy - r*0.87, width: r*0.87*2, height: r*0.87*2)),
                with: .color(Color(red: 0.71, green: 0.82, blue: 1.0, opacity: 0.07)), lineWidth: 1
            )
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - r*0.70, y: cy - r*0.70, width: r*0.70*2, height: r*0.70*2)),
                with: .color(Color(red: 0.71, green: 0.82, blue: 1.0, opacity: 0.04)), lineWidth: 0.8
            )

        }
        .frame(width: viewW, height: viewH)
    }
}
