//
//  LessonInputArea.swift
//  LA Hacks
//
//  Bottom input area for the lesson — switches between action button,
//  multiple-choice, and text input based on BottomInputKind.
//

import SwiftUI

// MARK: - Bottom input area

struct LessonInputArea: View {
    let inputKind: BottomInputKind
    let pal: StarPalette
    @Binding var hintTier: Int
    let questionKey: Int
    let onAction: (LessonAction) -> Void
    let onAnswer: (String, LessonProblem, Int, Bool) -> Void
    let onHint: (LessonProblem, Int) -> Void  // (problem, requested tier)

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            Group {
                switch inputKind {
                case .action(let label, let kind):
                    actionView(label: label, kind: kind)
                case .mc(let choices, let problem, let idx):
                    MCChoicesView(choices: choices, problem: problem, idx: idx, pal: pal, hintTier: $hintTier, onAnswer: onAnswer, onHint: onHint)
                        .id(questionKey)
                case .text(let problem, let idx):
                    TextInputView(problem: problem, idx: idx, pal: pal, hintTier: $hintTier, onAnswer: onAnswer, onHint: onHint)
                        .id(questionKey)
                }
            }
            .padding(EdgeInsets(top: 12, leading: 14, bottom: 28, trailing: 14))
        }
        .background(Color(hex: 0x09041E))
    }

    private func actionView(label: String, kind: LessonAction) -> some View {
        Button(action: { onAction(kind) }) {
            Text(label)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x1A0B40))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [pal.mid, pal.halo], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: pal.glow, radius: 16, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
