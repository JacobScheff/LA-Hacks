//
//  HintButton.swift
//  LA Hacks
//
//  Tiered hint button — escalates from static hint → LLM hint → walk-through.
//

import SwiftUI

// MARK: - Hint button

/// Tiered hint button. Each tap escalates: 1) static hint, 2) LLM deeper
/// hint, 3) walk-through (effectively gives up and advances).
struct HintButton: View {
    let problem: LessonProblem
    @Binding var hintTier: Int
    let onHint: (LessonProblem, Int) -> Void  // (problem, requested tier)

    var body: some View {
        // Hide entirely once tier 3 (walk-through) has been requested.
        if hintTier >= 3 || problem.hint.isEmpty {
            EmptyView()
        } else {
            let labelText: String = {
                switch hintTier {
                case 0: return "💡 Show hint"
                case 1: return "🔎 Deeper hint"
                default: return "🤝 Show me how"
                }
            }()
            let costText: String = {
                switch hintTier {
                case 0: return "(−5 XP)"
                case 1: return "(−10 XP)"
                default: return "(skips this Q)"
                }
            }()

            Button(action: {
                let next = hintTier + 1
                hintTier = next
                onHint(problem, next)
            }) {
                HStack(spacing: 6) {
                    Text(labelText)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: 0x5EE7FF))
                    Text(costText)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: 0x5EE7FF, opacity: 0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(hex: 0x5EE7FF, opacity: 0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            }
            .buttonStyle(.plain)
        }
    }
}
