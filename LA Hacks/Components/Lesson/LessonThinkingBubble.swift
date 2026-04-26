//
//  LessonThinkingBubble.swift
//  LA Hacks
//
//  Bubble shown while the on-device model is generating a hint or response —
//  combines a caption with the gravity n-body StarOrbitLoadingView.
//

import SwiftUI

// MARK: - Lesson thinking bubble (gravity n-body while Gemma generates)

struct LessonThinkingBubble: View {
    let pal: StarPalette
    let caption: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            VStack(alignment: .leading, spacing: 8) {
                Text(caption)
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: 0xE8D8FF))
                    .lineSpacing(2)
                StarOrbitLoadingView(
                    title: "Thinking…",
                    subtitle: "Nova is exploring ideas",
                    height: 180
                )
                .frame(maxWidth: .infinity)
            }
            Spacer(minLength: 0)
        }
    }
}
