//
//  TextInputView.swift
//  LA Hacks
//
//  Free-form text answer input for a lesson problem (with hint button).
//

import SwiftUI

// MARK: - Text input

struct TextInputView: View {
    let problem: LessonProblem
    let idx: Int
    let pal: StarPalette
    @Binding var hintTier: Int
    let onAnswer: (String, LessonProblem, Int, Bool) -> Void
    let onHint: (LessonProblem, Int) -> Void  // (problem, requested tier)

    @State private var textVal = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("", text: $textVal, prompt: Text("Your answer…").foregroundColor(.white.opacity(0.4)))
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1.5)
                    )
                    .focused($isFocused)
                    .onSubmit { submit() }

                Button(action: submit) {
                    Text("→")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(textVal.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.25) : Color(hex: 0x1A0B40))
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(textVal.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? AnyShapeStyle(Color.white.opacity(0.07))
                                      : AnyShapeStyle(LinearGradient(colors: [pal.mid, pal.halo], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        )
                        .shadow(color: textVal.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : pal.glow.opacity(0.6), radius: 10)
                }
                .buttonStyle(.plain)
                .disabled(textVal.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            HintButton(problem: problem, hintTier: $hintTier, onHint: onHint)
        }
    }

    private func submit() {
        let v = textVal.trimmingCharacters(in: .whitespaces)
        guard !v.isEmpty else { return }
        isFocused = false
        onAnswer(v, problem, idx, hintTier > 0)
    }
}
