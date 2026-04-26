//
//  StarOrbitLoadingView.swift
//  LA Hacks
//
//  Gravity n-body simulation loading view (3 orbiting stars).
//  Extracted from GalaxyTabs.swift.
//

import SwiftUI
import Combine

// MARK: - Gravity N-Body Simulation Loading View

final class NBodyEngine: ObservableObject {
    struct GravityStar {
        var position: CGPoint
        var velocity: CGVector
        var color: Color
        var mass: CGFloat
        var trail: [CGPoint] = []
    }
    
    @Published var stars: [GravityStar] = []
    private var timer: Timer?
    
    func start() {
        let colors: [Color] = [
            Color(hex: 0xFFE066), // Yellow (Mastered)
            Color(hex: 0x5EE7FF), // Cyan (Sleepy)
            Color(hex: 0xFF8AD8)  // Pink (Learning)
        ]
        
        // Starts the stars 3x further out (compared to the original radius of 16)
        let R: CGFloat = 55.0
        
        stars = (0..<3).map { i in
            let angle = Double(i) * 2.0 * .pi / 3.0
            
            // Vastly more randomness in position
            let ox = CGFloat.random(in: -15.0...15.0)
            let oy = CGFloat.random(in: -15.0...15.0)
            
            // Entirely random directions with high initial speeds
            let speed = CGFloat.random(in: 6.0...12.0)
            let vAngle = Double.random(in: 0...(2 * .pi))
            
            let pos = CGPoint(x: R * CGFloat(cos(angle)) + ox, y: R * CGFloat(sin(angle)) + oy)
            let vel = CGVector(dx: speed * CGFloat(cos(vAngle)), dy: speed * CGFloat(sin(vAngle)))
            let mass = CGFloat.random(in: 0.8...2.5)
            
            return GravityStar(position: pos, velocity: vel, color: colors[i], mass: mass)
        }
        
        timer?.invalidate()
        
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.update()
        }
        // Attaching to .common so it doesn't freeze during scrolling/touch!
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
    
    func stop() {
        timer?.invalidate()
    }
    
    private func update() {
        let G: CGFloat = 80.0
        let centerPull: CGFloat = 0.008 // Gentle center pull to keep them on-screen
        let dt: CGFloat = 0.4
        let damping: CGFloat = 1.0 // NO damping, they will never slow down and stop
        
        var newStars = stars
        for i in 0..<newStars.count {
            var ax: CGFloat = 0
            var ay: CGFloat = 0
            
            // Gravity from other stars
            for j in 0..<newStars.count {
                if i == j { continue }
                let dx = stars[j].position.x - stars[i].position.x
                let dy = stars[j].position.y - stars[i].position.y
                let distSq = dx * dx + dy * dy
                let dist = sqrt(distSq)
                
                // Generous softening to prevent crazy slingshots
                let force = G * stars[j].mass / (distSq + 200.0)
                ax += force * (dx / dist)
                ay += force * (dy / dist)
            }
            
            // Weak gravity towards center to prevent them flying completely off canvas
            ax -= centerPull * stars[i].position.x
            ay -= centerPull * stars[i].position.y
            
            // Update velocity
            newStars[i].velocity.dx += ax * dt
            newStars[i].velocity.dy += ay * dt
            newStars[i].velocity.dx *= damping
            newStars[i].velocity.dy *= damping
            
            // Update position
            newStars[i].position.x += newStars[i].velocity.dx * dt
            newStars[i].position.y += newStars[i].velocity.dy * dt
            
            // Update long trail
            newStars[i].trail.insert(newStars[i].position, at: 0)
            if newStars[i].trail.count > 35 {
                newStars[i].trail.removeLast()
            }
        }
        stars = newStars
    }
}

struct StarOrbitLoadingView: View {
    var title: String = "Thinking..."
    var subtitle: String = "Nova is exploring ideas"
    var height: CGFloat = 240
    @StateObject private var engine = NBodyEngine()
    
    var body: some View {
        // Using a ZStack allows the Canvas to perfectly occupy the entire
        // background card area, letting stars fly all the way to the border.
        ZStack(alignment: .topLeading) {
            Canvas { ctx, size in
                let cx = size.width / 2
                let cy = size.height / 2
                
                for star in engine.stars {
                    let baseRadius = 2.0 + star.mass * 0.8
                    
                    // Draw fading trails
                    for (idx, pt) in star.trail.enumerated().reversed() {
                        let progress = 1.0 - (CGFloat(idx) / CGFloat(star.trail.count))
                        let radius = (baseRadius + 1.5) * progress
                        
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: cx + pt.x - radius, y: cy + pt.y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(star.color.opacity(progress * 0.5))
                        )
                    }
                    
                    // Draw leading head
                    let headX = cx + star.position.x
                    let headY = cy + star.position.y
                    
                    // White core
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: headX - baseRadius, y: headY - baseRadius, width: baseRadius * 2, height: baseRadius * 2)),
                        with: .color(.white)
                    )
                    
                    // Glow bloom proportional to mass
                    let glowR = baseRadius * 2.8
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: headX - glowR, y: headY - glowR, width: glowR * 2, height: glowR * 2)),
                        with: .color(star.color.opacity(0.8))
                    )
                }
            }
            .frame(height: height) // Lots of vertical room for the stars to sling around!
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x5EE7FF))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: 0x5EE7FF, opacity: 0.08))
        )
        // Hard clip to exactly the shape of the border box so stars reach the absolute edge
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0x5EE7FF, opacity: 0.25), lineWidth: 1.5)
        )
        .onAppear {
            engine.start()
        }
        .onDisappear {
            engine.stop()
        }
    }
}
