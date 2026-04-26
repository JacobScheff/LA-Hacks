//
//  GalaxyScreen.swift
//  LA Hacks
//
//  Pannable / zoomable galaxy screen with sky canvas + hit layer.
//

import SwiftUI
import WidgetKit

// MARK: - Galaxy screen

struct GalaxyScreen: View {
    @EnvironmentObject var state: GalaxyState
    let onTrain: (StarNode) -> Void
    let onProfile: () -> Void

    // Pan + zoom state
    @State private var tx: CGFloat = -50
    @State private var ty: CGFloat = 180
    @State private var scale: CGFloat = 0.5

    // In-flight gesture deltas
    @State private var dragOffset: CGSize = .zero
    @State private var pinchDelta: CGFloat = 1.0
    // Focal-point correction applied while pinching
    @State private var pinchTxCorr: CGFloat = 0
    @State private var pinchTyCorr: CGFloat = 0

    // Selection / overlays
    @State private var selected: StarNode?
    @State private var filter: MasteryStage? = nil
    @State private var modalConstellation: Constellation?

    // Filter chip "all" support — kept separate so we can show 'all' as a
    // selected state when filter is nil.
    @State private var showAllPill = true

    // Upload flow
    @State private var uploadStage: UploadStage = .idle
    @State private var readingStep: Int = 0
    @State private var revealResult: GenerationResult?

    // Telescope warp-in animation
    private enum WarpPhase { case enter, exit, done }
    @State private var warpPhase: WarpPhase = .enter
    @State private var warpScale: CGFloat = 0.18
    @State private var warpBlur: CGFloat = 22
    @State private var warpBrightness: Double = -0.7
    @State private var telescopeScale: CGFloat = 1.0
    @State private var lensRotation: Double = 0
    @State private var lastTabLeave: Date?
    @State private var warpGeneration: Int = 0

    enum UploadStage { case idle, pick, reading, reveal }

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let safeBot = geo.safeAreaInsets.bottom

            ZStack(alignment: .top) {
                galaxyBackdrop

                // World layer — pan + zoom
                ZStack {
                    SkyCanvas(
                        constellations: state.constellations,
                        stages: state.computeAllStages(),
                        pendingNewIds: state.pendingNewIds,
                        tx: tx + dragOffset.width + pinchTxCorr,
                        ty: ty + dragOffset.height + pinchTyCorr,
                        scale: scale * pinchDelta,
                        selectedId: selected?.id,
                        focusedConstellationId: focusedConstellationId,
                        filter: filter,
                        showDiscoverNebula: state.constellations.count == GalaxyData.constellations.count
                    )
                    .allowsHitTesting(false)

                    GalaxyHitLayer(
                        constellations: state.constellations,
                        tx: tx + dragOffset.width + pinchTxCorr,
                        ty: ty + dragOffset.height + pinchTyCorr,
                        scale: scale * pinchDelta,
                        showDiscoverNebula: state.constellations.count == GalaxyData.constellations.count,
                        onTapStar: { handleStarTap($0, viewport: geo.size) },
                        onTapConstellation: { c in
                            modalConstellation = c
                            Self.saveConstellationToWidget(c)
                        },
                        onTapDiscover: { uploadStage = .pick }
                    )
                }
                .contentShape(Rectangle())
                .simultaneousGesture(makeGesture(W: W, H: H))

                // Top fade — translucent dark gradient, no hard edge
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0x07021A, opacity: 0.96), location: 0.00),
                        .init(color: Color(hex: 0x0D0530, opacity: 0.90), location: 0.10),
                        .init(color: Color(hex: 0x0D0530, opacity: 0.78), location: 0.22),
                        .init(color: Color(hex: 0x08041A, opacity: 0.52), location: 0.40),
                        .init(color: Color(hex: 0x08041A, opacity: 0.18), location: 0.60),
                        .init(color: Color(hex: 0x08041A, opacity: 0.00), location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 340)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)

                // Bottom fade
                LinearGradient(
                    colors: [
                        Color(hex: 0x08041A, opacity: 0.0),
                        Color(hex: 0x08041A, opacity: 0.7),
                        Color(hex: 0x08041A, opacity: 0.95),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 180)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)

                TopHeader(stats: state.stats, filter: filter, onFilter: { filter = $0 }, onProfile: onProfile, topInset: safeTop)

                if selected == nil {
                    HintPill(gaps: state.stats.gaps)
                        .padding(.bottom, 82 + max(safeBot, 10))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .allowsHitTesting(false)
                }

                // Upload flow overlays
                switch uploadStage {
                case .idle: EmptyView()
                case .pick:
                    UploadModal(
                        onClose: { uploadStage = .idle },
                        onGenerate: startGenerate
                    )
                    .zIndex(95)
                    .transition(.opacity)
                case .reading:
                    ReadingScreen(stage: readingStep)
                        .zIndex(95)
                        .transition(.opacity)
                case .reveal:
                    if let r = revealResult {
                        RevealScreen(
                            result: r,
                            onClose: closeReveal,
                            onExplore: { exploreReveal(viewport: geo.size) }
                        )
                        .zIndex(95)
                        .transition(.opacity)
                    }
                }
            }
            .frame(width: W, height: H)
            .clipped()
            .sheet(item: $selected) { node in
                SkillSheet(
                    node: node,
                    onTrain: { n in
                        selected = nil
                        onTrain(n)
                    }
                )
            }
            .sheet(item: $modalConstellation) { c in
                ConstellationModal(
                    constellation: c,
                    onJumpToStar: { node in
                        modalConstellation = nil
                        handleStarTap(node, viewport: geo.size)
                    }
                )
            }
            .animation(.easeOut(duration: 0.25), value: selected?.id)
            .animation(.easeOut(duration: 0.25), value: uploadStage)
            .scaleEffect(warpScale)
            .blur(radius: warpBlur)
            .brightness(warpBrightness)
            .overlay(alignment: .center) {
                if warpPhase != .done {
                    TelescopeOverlayView(viewW: W, viewH: H, lensRotation: lensRotation)
                        .scaleEffect(telescopeScale, anchor: UnitPoint(x: 0.5, y: 0.48))
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                let elapsed = lastTabLeave.map { Date().timeIntervalSince($0) } ?? .infinity
                guard elapsed > 3.0 else { return }
                warpGeneration += 1
                warpPhase = .enter
                warpScale = 0.18
                warpBlur = 22
                warpBrightness = -0.7
                telescopeScale = 1.0
                lensRotation = 0
                startWarp()
            }
            .onDisappear {
                lastTabLeave = Date()
                warpGeneration += 1
                warpPhase = .done
                warpScale = 1.0
                warpBlur = 0
                warpBrightness = 0
                telescopeScale = 1.0
                lensRotation = 0
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Backdrop layers

    private var galaxyBackdrop: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x3C145A, opacity: 0.55), Color(hex: 0x08041A, opacity: 1)],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 0, endRadius: 600
            )
        }
        .allowsHitTesting(false)
    }

    private func startWarp() {
        let gen = warpGeneration
        withAnimation(.spring(response: 1.3, dampingFraction: 0.52)) {
            warpScale = 1.0
        }
        withAnimation(.timingCurve(0.22, 1.0, 0.36, 1.0, duration: 1.1)) {
            warpBlur = 0
            warpBrightness = 0
        }
        // Lens rings spin fast then decelerate as focus locks in
        withAnimation(.timingCurve(0.05, 0.9, 0.35, 1.0, duration: 1.3)) {
            lensRotation = .pi * 2.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            guard warpGeneration == gen else { return }
            warpPhase = .exit
            withAnimation(.timingCurve(0.3, 0.0, 0.8, 1.0, duration: 0.65)) {
                telescopeScale = 3.4
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard warpGeneration == gen else { return }
            warpPhase = .done
            telescopeScale = 1.0
        }
    }

    private var focusedConstellationId: String? {
        guard let s = selected else { return nil }
        return state.nodesById()[s.id]?.constellationId
    }

    // MARK: Gestures

    private func clampOffset(tx: CGFloat, ty: CGFloat, scale: CGFloat, W: CGFloat, H: CGFloat) -> (CGFloat, CGFloat) {
        // Derive world bounds from actual star positions so they tighten/grow with content.
        let wsc: CGFloat = 1.3
        let allNodes = state.constellations.flatMap(\.nodes)
        let rawMaxX = allNodes.map(\.x).max() ?? GalaxyData.SKY_W
        let rawMaxY = allNodes.map(\.y).max() ?? GalaxyData.SKY_H
        // Always include the discover-nebula at (760, 1450) even when it has no stars yet.
        let pad: CGFloat = 110
        let worldW = (max(rawMaxX, 760) + pad) * wsc
        let worldH = (max(rawMaxY, 1450) + pad) * wsc
        let margin: CGFloat = 120
        let clampedTx = max(margin - worldW * scale, min(W - margin, tx))
        let clampedTy = max(margin - worldH * scale, min(H - margin, ty))
        return (clampedTx, clampedTy)
    }

    private func makeGesture(W: CGFloat, H: CGFloat) -> some Gesture {
        SimultaneousGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { v in
                    let (cTx, cTy) = clampOffset(
                        tx: tx + v.translation.width,
                        ty: ty + v.translation.height,
                        scale: scale, W: W, H: H
                    )
                    dragOffset = CGSize(width: cTx - tx, height: cTy - ty)
                }
                .onEnded { _ in
                    tx += dragOffset.width
                    ty += dragOffset.height
                    dragOffset = .zero
                },
            MagnifyGesture()
                .onChanged { v in
                    let focal = v.startLocation
                    let rawD = v.magnification
                    let newScale = max(0.35, min(2.5, scale * rawD))
                    let d = newScale / scale
                    pinchDelta = d
                    pinchTxCorr = (focal.x - tx) * (1 - d)
                    pinchTyCorr = (focal.y - ty) * (1 - d)
                }
                .onEnded { v in
                    let focal = v.startLocation
                    let rawD = v.magnification
                    let newScale = max(0.35, min(2.5, scale * rawD))
                    let d = newScale / scale
                    let (cTx, cTy) = clampOffset(
                        tx: tx + (focal.x - tx) * (1 - d),
                        ty: ty + (focal.y - ty) * (1 - d),
                        scale: newScale, W: W, H: H
                    )
                    tx = cTx; ty = cTy; scale = newScale
                    pinchDelta = 1.0; pinchTxCorr = 0; pinchTyCorr = 0
                }
        )
    }

    // MARK: Tap handling

    private func handleStarTap(_ node: StarNode, viewport: CGSize) {
        let viewW = viewport.width
        let viewH = viewport.height
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            scale = 1.0
            tx = viewW / 2 - node.x
            ty = viewH * 0.35 - node.y
            selected = node
        }
    }

    // MARK: Upload flow

    private func startGenerate(text: String, fileName: String) {
        let built = buildGenerationResult(
            text: text, fileName: fileName,
            constellations: state.constellations
        )
        uploadStage = .reading
        readingStep = 0
        let delays: [Double] = [0.6, 1.1, 1.7, 2.3]
        for (i, d) in delays.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                self.readingStep = min(i, 3)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
            // commit nodes
            if let new = built.newConstellation {
                state.constellations.append(new)
                state.pendingNewIds = Set(new.nodes.map { $0.id })
            } else if let targetId = built.targetConstellationId, !built.addedNodes.isEmpty {
                if let idx = state.constellations.firstIndex(where: { $0.id == targetId }) {
                    let c = state.constellations[idx]
                    let updated = Constellation(
                        id: c.id, name: c.name, realName: c.realName, nickname: c.nickname,
                        emoji: c.emoji, course: c.course, blurb: c.blurb, skyStory: c.skyStory,
                        centroid: c.centroid,
                        nodes: c.nodes + built.addedNodes,
                        edges: c.edges
                    )
                    state.constellations[idx] = updated
                    state.pendingNewIds = Set(built.addedNodes.map { $0.id })
                }
            }
            self.revealResult = built.result
            self.uploadStage = .reveal
        }
    }

    private func closeReveal() {
        uploadStage = .idle
        revealResult = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            state.pendingNewIds.removeAll()
        }
    }

    private func exploreReveal(viewport: CGSize) {
        if let r = revealResult, let jump = r.jumpTo {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                scale = jump.scale
                tx = viewport.width / 2 - jump.x * jump.scale
                ty = viewport.height * 0.4 - jump.y * jump.scale
            }
        }
        closeReveal()
    }

    // MARK: Widget bridge

    static func saveConstellationToWidget(_ c: Constellation) {
        let settings = UserSettings.shared
        var neighborMap: [String: [String]] = [:]
        for e in c.edges {
            neighborMap[e.a, default: []].append(e.b)
            neighborMap[e.b, default: []].append(e.a)
        }
        let nodeMap = Dictionary(uniqueKeysWithValues: c.nodes.map { ($0.id, $0) })
        let nodesArr: [[String: Any]] = c.nodes.map { n in
            let stage = settings.stage(for: n.id, initiallyLocked: n.initiallyLocked, neighborIds: neighborMap[n.id] ?? [])
            return ["x": Double(n.x), "y": Double(n.y),
                    "status": stage.rawValue, "size": Double(n.size)]
        }
        let edgesArr: [[String: Any]] = c.edges.compactMap { e in
            guard let a = nodeMap[e.a], let b = nodeMap[e.b] else { return nil }
            return ["ax": Double(a.x), "ay": Double(a.y),
                    "bx": Double(b.x), "by": Double(b.y)]
        }
        let payload: [String: Any] = [
            "id":             c.id,
            "name":           c.name,
            "emoji":          c.emoji,
            "course":         c.course,
            "masteryPercent": Int((c.masteryAvg * 100).rounded()),
            "nodes":          nodesArr,
            "edges":          edgesArr
        ]
        guard
            let data  = try? JSONSerialization.data(withJSONObject: payload),
            let suite = UserDefaults(suiteName: "group.com.lahacks.widget")
        else { return }
        suite.set(data, forKey: "activeConstellation")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
