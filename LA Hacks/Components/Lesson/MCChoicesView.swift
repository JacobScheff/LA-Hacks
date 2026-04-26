//
//  MCChoicesView.swift
//  LA Hacks
//
//  Multiple-choice answer grid for a lesson problem (with hint button).
//

import SwiftUI

// MARK: - MC choices

struct MCChoicesView: View {
    let choices: [String]
    let problem: LessonProblem
    let idx: Int
    let pal: StarPalette
    @Binding var hintTier: Int
    let onAnswer: (String, LessonProblem, Int, Bool) -> Void
    let onHint: (LessonProblem, Int) -> Void  // (problem, requested tier)

    @State private var tapped: String? = nil

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(choices.enumerated()), id: \.offset) { i, ch in
                let isTapped = tapped == ch
                Button(action: {
                    guard tapped == nil else { return }
                    tapped = ch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                        onAnswer(ch, problem, idx, hintTier > 0)
                    }
                }) {
                    HStack(spacing: 10) {
                        Text(String(UnicodeScalar(65 + i)!))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(isTapped ? .white : Color(hex: 0xC8AAF0, opacity: 0.8))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(isTapped ? Color.white.opacity(0.25) : Color.white.opacity(0.08)))
                        Text(ch)
                            .font(.system(size: 14, weight: isTapped ? .bold : .medium, design: .rounded))
                            .foregroundColor(isTapped ? .white : Color(hex: 0xE6D2FF, opacity: 0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isTapped
                                  ? AnyShapeStyle(LinearGradient(colors: [pal.mid.opacity(0.8), pal.halo.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color.white.opacity(0.055)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isTapped ? pal.mid : Color.white.opacity(0.12), lineWidth: 1.5)
                    )
                    .shadow(color: isTapped ? pal.glow.opacity(0.5) : .clear, radius: 8)
                    .animation(.easeOut(duration: 0.15), value: isTapped)
                }
                .buttonStyle(.plain)
                .disabled(tapped != nil)
            }
            HintButton(problem: problem, hintTier: $hintTier, onHint: onHint)
        }
    }
}
