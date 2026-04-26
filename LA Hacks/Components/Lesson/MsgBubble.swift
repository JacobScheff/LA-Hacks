//
//  MsgBubble.swift
//  LA Hacks
//
//  Chat bubble (Nova / student / stats) + ChatMsg model.
//

import SwiftUI

// MARK: - Chat message model

struct ChatMsg: Identifiable {
    let id = UUID()
    let source: MessageSource
    let text: String
    var isHint: Bool = false
    var isStats: Bool = false
    var statsXP: Int = 0
    var statsHearts: Int = 3
    var statsHints: Int = 0
    // Color-coded student-bubble feedback from origin/main's content-filters PR.
    // nil for neutral student input, .correct/.incorrect for graded answers.
    var answerResult: AnswerResult? = nil
    enum AnswerResult { case correct, incorrect }
}

// MARK: - Chat bubble

struct MsgBubble: View {
    let msg: ChatMsg
    let pal: StarPalette

    var body: some View {
        if msg.isStats {
            statsBubble
        } else if msg.source == .nova {
            novaBubble
        } else {
            studentBubble
        }
    }

    private var novaBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            Text(msg.text)
                .font(.system(size: 14.5, weight: .regular, design: .rounded))
                .foregroundColor(msg.isHint ? Color(hex: 0x5EE7FF) : Color(hex: 0xE8D8FF))
                .lineSpacing(2)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(msg.isHint ? Color(hex: 0x5EE7FF, opacity: 0.1) : Color(hex: 0x201048, opacity: 0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(msg.isHint ? Color(hex: 0x5EE7FF, opacity: 0.3) : Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
            Spacer(minLength: 44)
        }
    }

    private var studentBubble: some View {
        HStack {
            Spacer(minLength: 44)
            Text(msg.text)
                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                .foregroundColor(msg.answerResult == nil ? Color(hex: 0x1A0B40) : .white)
                .lineSpacing(2)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            msg.answerResult == .correct
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: 0x34C759), Color(hex: 0x30B354)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                : msg.answerResult == .incorrect
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: 0xFF3B30), Color(hex: 0xD93025)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: 0xFF8A4C), Color(hex: 0xFFCC44)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                )
                .shadow(color: msg.answerResult == .correct
                            ? Color(hex: 0x34C759, opacity: 0.4)
                            : msg.answerResult == .incorrect
                            ? Color(hex: 0xFF3B30, opacity: 0.4)
                            : Color(hex: 0xFF8A4C, opacity: 0.3),
                        radius: 8, x: 0, y: 2)
        }
    }

    private var statsBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            NovaAvatarView(size: 26, pal: pal)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                statTile("✨", label: "XP earned",   val: "+\(msg.statsXP)",   c: Color(hex: 0xFFE066))
                statTile("❤️", label: "Hearts left", val: "\(msg.statsHearts)/3", c: Color(hex: 0xFF8AD8))
                statTile("💡", label: "Hints used",  val: "\(msg.statsHints)", c: Color(hex: 0x5EE7FF))
                statTile("🔥", label: "Streak",      val: "+1 day",            c: Color(hex: 0xFF8A4C))
            }
            .frame(width: 240)
            Spacer(minLength: 0)
        }
    }

    private func statTile(_ icon: String, label: String, val: String, c: Color) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 16))
            Text(val)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(c)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(0.3)
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8).padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
