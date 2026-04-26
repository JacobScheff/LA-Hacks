//
//  NovaAITab.swift
//  LA Hacks
//
//  Claude-style conversational UI for Nova AI.
//

import SwiftUI

// MARK: - Nova AI Tab

struct NovaAITab: View {
    @State private var messages: [ChatMessage] = []
    @State private var rawStream: String = ""
    @State private var isProcessing: Bool = false
    @State private var downloadProgress: Float = 0.0
    @State private var inputText: String = ""
    @FocusState private var inputFocused: Bool

    private let suggestions = [
        "Explain this concept simply",
        "Help me understand fractions",
        "What is the scientific method?",
        "How do I improve my writing?"
    ]

    var body: some View {
        VStack(spacing: 0) {
            minimalHeader

            ZStack {
                if messages.isEmpty && !isProcessing {
                    welcomeState
                } else {
                    messagesView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isProcessing && downloadProgress > 0 && downloadProgress < 1.0 {
                downloadBanner
            }

            inputBar
        }
        .onTapGesture { inputFocused = false }
    }

    // MARK: - Header

    private var minimalHeader: some View {
        HStack(spacing: 10) {
            novaIconSmall(size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text("Ask Nova")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("Powered by Gemma · on-device")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            if !messages.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        messages = []
                        rawStream = ""
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.clear)
    }

    // MARK: - Welcome State

    private var welcomeState: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                VStack(spacing: 14) {
                    novaIconSmall(size: 72)
                        .shadow(color: Color(hex: 0xCC88FF, opacity: 0.5), radius: 24)

                    Text("What would you like to learn?")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Ask me anything — I'll explain it clearly.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            inputText = suggestion
                            sendMessage()
                        } label: {
                            HStack(spacing: 12) {
                                Text(suggestion)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 40)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Messages

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(messages) { msg in
                        messageBubble(msg)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                    }

                    if isProcessing {
                        if currentlyThinking {
                            thinkingBubble
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                        } else if !parsedStream.isEmpty {
                            novaBubble(parsedStream, isStreaming: true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                        }
                    }

                    Color.clear.frame(height: 12).id("bottom")
                }
                .padding(.top, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .onChange(of: messages.count) { _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: rawStream) { _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        if msg.role == .user {
            userBubble(msg.content)
        } else {
            novaBubble(msg.content, isStreaming: false)
        }
    }

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 56)
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: 0x1A0B40))
                .lineSpacing(2)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .shadow(color: Color(hex: 0xFF8A4C, opacity: 0.25), radius: 8, x: 0, y: 2)
        }
    }

    private func novaBubble(_ text: String, isStreaming: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            novaIconSmall(size: 26)

            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: 0xE8D8FF))
                .lineSpacing(3)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(isStreaming ? 0.15 : 0.09), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)

            Spacer(minLength: 56)
        }
    }

    private var thinkingBubble: some View {
        HStack(alignment: .bottom, spacing: 10) {
            novaIconSmall(size: 26)

            BouncingDotsRow()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )

            Spacer(minLength: 56)
        }
    }

    // MARK: - Download Banner

    private var downloadBanner: some View {
        HStack(spacing: 10) {
            Text("⬇️").font(.system(size: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text("Downloading Nova's brain…")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: g.size.width * CGFloat(downloadProgress))
                    }
                }
                .frame(height: 4)
            }
            Text(String(format: "%.0f%%", downloadProgress * 100))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0xFFE066))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: 0x160A3A))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask Nova anything…", text: $inputText, axis: .vertical)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white)
                .tint(Color(hex: 0xFFE066))
                .lineLimit(1...6)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .focused($inputFocused)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        canSend ? Color(hex: 0xFFE066) : Color.white.opacity(0.18)
                    )
                    .animation(.easeInOut(duration: 0.15), value: canSend)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(inputFocused ? 0.2 : 0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.2), value: inputFocused)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isProcessing
    }

    // MARK: - Shared Nova Icon

    private func novaIconSmall(size: CGFloat) -> some View {
        Text("✦")
            .font(.system(size: size * 0.38, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle().fill(LinearGradient(
                    colors: [Color(hex: 0xCC88FF), Color(hex: 0x5EE7FF)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            )
            .shadow(color: Color(hex: 0xCC88FF, opacity: 0.35), radius: 8)
    }

    // MARK: - Thought Channel Parsing

    private var parsedStream: String {
        var text = rawStream
        while let startRange = text.range(of: "<|channel>thought") {
            if let endRange = text.range(of: "<channel|>", range: startRange.upperBound..<text.endIndex) {
                text.removeSubrange(startRange.lowerBound..<endRange.upperBound)
            } else {
                text.removeSubrange(startRange.lowerBound..<text.endIndex)
                break
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var currentlyThinking: Bool {
        guard isProcessing else { return false }
        var text = rawStream
        while let startRange = text.range(of: "<|channel>thought") {
            if let endRange = text.range(of: "<channel|>", range: startRange.upperBound..<text.endIndex) {
                text.removeSubrange(startRange.lowerBound..<endRange.upperBound)
            } else {
                return true
            }
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let thoughtToken = "<|channel>thought"
        if trimmed.isEmpty || thoughtToken.hasPrefix(trimmed) { return true }
        if parsedStream.isEmpty { return true }
        return false
    }

    // MARK: - Send

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isProcessing else { return }

        inputFocused = false
        inputText = ""

        let history = messages
        messages.append(ChatMessage(role: .user, content: text))
        isProcessing = true
        rawStream = ""
        downloadProgress = 0.0

        let context = PipelineContext(
            activeConstellationID: nil,
            activeStarID: nil,
            studentName: "Explorer",
            history: history
        )

        RAGPipeline.run(
            userQuery: text,
            context: context,
            onDownload: { progress in
                DispatchQueue.main.async { self.downloadProgress = progress }
            },
            onStream: { currentText in
                DispatchQueue.main.async { self.rawStream = currentText }
            },
            onComplete: { result in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    let finalText: String
                    if let error = result.error {
                        finalText = "Oops! Nova had a problem: \(error.localizedDescription)"
                    } else {
                        finalText = self.parsedStream.isEmpty ? result.text : self.parsedStream
                    }
                    self.messages.append(ChatMessage(role: .assistant, content: finalText))
                    self.rawStream = ""
                }
            }
        )
    }
}

// MARK: - Bouncing Dots

private struct BouncingDotsRow: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate * 4.5
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 6, height: 6)
                        .offset(y: CGFloat(sin(t + Double(i) * 0.7) * -3.5))
                }
            }
        }
    }
}
