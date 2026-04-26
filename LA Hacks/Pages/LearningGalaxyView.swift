//
//  LearningGalaxyView.swift
//  LA Hacks
//
//  Star Hop! root tab-routing view + GalaxyState + GalaxyTab enum.
//

import SwiftUI
import Combine

// MARK: - Tab routing

enum GalaxyTab: String, Hashable {
    case galaxy, study, nova
}

/// App-level state shared between Galaxy + tabs (so an upload-grown
/// constellation persists when you flip away and back).
@MainActor
final class GalaxyState: ObservableObject {
    @Published var constellations: [Constellation] = GalaxyData.constellations
    @Published var pendingNewIds: Set<String> = []

    var stats: (mastered: Int, gaps: Int, learning: Int) {
        let all = computeAllStages()
        var m = 0, g = 0, l = 0
        for stage in all.values {
            switch stage {
            case .shining:   m += 1
            case .sleepy:    g += 1
            case .twinkling: l += 1
            case .locked:    break
            }
        }
        return (m, g, l)
    }

    /// Computes the live MasteryStage for every node using UserSettings.starMastery + edge graph.
    func computeAllStages() -> [String: MasteryStage] {
        let settings = UserSettings.shared
        var neighborIds: [String: [String]] = [:]
        for c in constellations {
            for e in c.edges {
                neighborIds[e.a, default: []].append(e.b)
                neighborIds[e.b, default: []].append(e.a)
            }
        }
        for e in GalaxyData.bridges {
            neighborIds[e.a, default: []].append(e.b)
            neighborIds[e.b, default: []].append(e.a)
        }
        var stages: [String: MasteryStage] = [:]
        for c in constellations {
            for n in c.nodes {
                stages[n.id] = settings.stage(for: n.id, initiallyLocked: n.initiallyLocked, neighborIds: neighborIds[n.id] ?? [])
            }
        }
        return stages
    }

    func nodesById() -> [String: (node: StarNode, constellationId: String, constellationName: String, constellationEmoji: String)] {
        var out: [String: (StarNode, String, String, String)] = [:]
        for c in constellations {
            for n in c.nodes { out[n.id] = (n, c.id, c.name, c.emoji) }
        }
        return out
    }
}

// MARK: - Root view

struct LearningGalaxyView: View {
    @State private var tab: GalaxyTab = .galaxy
    @State private var trainingNode: StarNode?
    @State private var lessonNode: StarNode?
    @State private var showMe = false
    @StateObject private var state = GalaxyState()
    @State private var contentID = UUID()
    @Environment(UserSettings.self) var userSettings

    init() {
        let bar = UITabBarAppearance()
        bar.configureWithOpaqueBackground()
        bar.backgroundColor = UIColor(red: 0.04, green: 0.02, blue: 0.11, alpha: 0.97)
        bar.shadowColor = .clear

        let gold = UIColor(red: 1.0, green: 0.878, blue: 0.4, alpha: 1.0)
        let dim  = UIColor.white.withAlphaComponent(0.28)

        bar.stackedLayoutAppearance.normal.titleTextAttributes   = [.foregroundColor: dim]
        bar.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: gold]

        UITabBar.appearance().standardAppearance   = bar
        UITabBar.appearance().scrollEdgeAppearance = bar
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab(value: GalaxyTab.galaxy) {
                GalaxyScreen(onTrain: { trainingNode = $0 }, onProfile: { showMe = true })
                    .environmentObject(state)
                    .ignoresSafeArea()
                    .id(contentID)
            } label: {
                Label { Text("Galaxy") } icon: { Image(uiImage: Self.emojiTabIcon("🌌")) }
            }

            Tab(value: GalaxyTab.study) {
                StudyTab(onBeginQuest: {
                    trainingNode = LearningGalaxyView.makeSyntheticNode(
                        label: "Adding Slices", emoji: "🍕")
                })
                .background { tabBackground }
                .id(contentID)
            } label: {
                Label { Text("Quests") } icon: { Image(uiImage: Self.emojiTabIcon("🎯")) }
            }

            Tab(value: GalaxyTab.nova) {
                NovaAITab()
                    .background { tabBackground }
                    .id(contentID)
            } label: {
                Label { Text("Nova") } icon: {
                    Image(uiImage: Self.novaTabIcon())
                }
            }
        }
        .sheet(isPresented: $showMe) {
            YouTab()
                .background { tabBackground }
        }
        .onChange(of: userSettings.language) { _, _ in contentID = UUID() }
        .tint(Color(hex: 0xFFE066))
        .preferredColorScheme(.dark)
        .overlay {
            if let node = trainingNode {
                TrainingOverlay(
                    node: node,
                    onClose: { trainingNode = nil },
                    onStart: { n in trainingNode = nil; lessonNode = n }
                )
                .transition(.opacity)
            }
            if let node = lessonNode {
                let constellation = state.constellations.first { c in
                    c.nodes.contains { $0.id == node.id }
                }
                LessonView(
                    node: node,
                    constellationName: constellation?.name ?? "",
                    course: constellation?.course ?? "",
                    blurb: constellation?.blurb,
                    siblingLabels: constellation?.nodes
                        .filter { $0.id != node.id }
                        .map(\.label) ?? [],
                    onClose: { lessonNode = nil }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: trainingNode?.id)
        .animation(.easeOut(duration: 0.3), value: lessonNode?.id)
    }

    static func novaTabIcon(size: CGFloat = 28) -> UIImage {
        let sz = CGSize(width: size, height: size)
        let rendered = UIGraphicsImageRenderer(size: sz).image { _ in
            UIImage(named: "Nova Image")?.draw(in: CGRect(origin: .zero, size: sz))
        }
        return rendered.withRenderingMode(.alwaysOriginal)
    }

    static func emojiTabIcon(_ emoji: String) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let img = UIGraphicsImageRenderer(size: size).image { _ in
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 26)]
            let s = emoji as NSString
            let sz = s.size(withAttributes: attrs)
            s.draw(at: CGPoint(x: (size.width - sz.width) / 2,
                               y: (size.height - sz.height) / 2),
                   withAttributes: attrs)
        }
        return img.withRenderingMode(.alwaysOriginal)
    }

    static func makeSyntheticNode(label: String, emoji: String, initiallyLocked: Bool = false) -> StarNode {
        StarNode(
            id: "synthetic-\(label.lowercased().replacingOccurrences(of: " ", with: "-"))",
            label: label,
            constellationID: "synthetic",
            star: nil,
            emoji: emoji,
            x: 0, y: 0,
            status: status,
            size: 5,
            mastery: status == .mastered ? 1.0 : 0.4
        )
    }

    /// Shared background for non-galaxy tabs: nebula wash + star dust, full bleed.
    private var tabBackground: some View {
        ZStack {
            backdrop
            dustOverlay
        }
        .ignoresSafeArea()
    }

    /// Background gradients — richer multi-stop nebula washes.
    private var backdrop: some View {
        ZStack {
            Color(hex: 0x07021A)
            // Top-left magenta nebula
            RadialGradient(
                colors: [Color(hex: 0xFF5DC8, opacity: 0.52), Color(hex: 0xC030A0, opacity: 0.22), .clear],
                center: UnitPoint(x: 0.22, y: 0.10),
                startRadius: 0, endRadius: 500
            )
            // Bottom-right cyan nebula
            RadialGradient(
                colors: [Color(hex: 0x28E8FF, opacity: 0.46), Color(hex: 0x08B8D8, opacity: 0.16), .clear],
                center: UnitPoint(x: 0.80, y: 0.82),
                startRadius: 0, endRadius: 460
            )
            // Center deep violet
            RadialGradient(
                colors: [Color(hex: 0x8030E8, opacity: 0.44), Color(hex: 0x5010C0, opacity: 0.14), .clear],
                center: UnitPoint(x: 0.52, y: 0.48),
                startRadius: 0, endRadius: 580
            )
            // Top-right warm orange accent
            RadialGradient(
                colors: [Color(hex: 0xFF8020, opacity: 0.26), .clear],
                center: UnitPoint(x: 0.92, y: 0.06),
                startRadius: 0, endRadius: 260
            )
            // Bottom-left indigo accent
            RadialGradient(
                colors: [Color(hex: 0x2040D8, opacity: 0.30), .clear],
                center: UnitPoint(x: 0.06, y: 0.92),
                startRadius: 0, endRadius: 300
            )
        }
    }

    /// Faint star dust across non-galaxy tabs (mirrors TabFrame in Learning Galaxy.html).
    private var dustOverlay: some View {
        Canvas { ctx, size in
            let pts: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (0.18, 0.22, 0.7, 0.50),
                (0.82, 0.38, 0.6, 0.40),
                (0.35, 0.78, 0.6, 0.40),
                (0.70, 0.92, 0.6, 0.30),
                (0.50, 0.52, 0.5, 0.22),
                (0.10, 0.55, 0.4, 0.30),
                (0.92, 0.62, 0.5, 0.30),
                (0.45, 0.10, 0.4, 0.30),
            ]
            for (px, py, pr, op) in pts {
                let x = px * size.width, y = py * size.height
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - pr, y: y - pr, width: pr * 2, height: pr * 2)),
                    with: .color(.white.opacity(op))
                )
            }
        }
        .allowsHitTesting(false)
        .opacity(0.6)
    }
}

#Preview {
    LearningGalaxyView()
}
