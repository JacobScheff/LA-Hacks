//
//  NovaAITab.swift
//  LA Hacks
//
//  Nova AI — sessions list home + individual chat view.
//

import SwiftUI

// MARK: - Chat Session

struct ChatSession: Identifiable {
    let id: UUID
    let date: Date
    var messages: [ChatMessage]

    init(messages: [ChatMessage]) {
        self.id = UUID()
        self.date = Date()
        self.messages = messages
    }

    var preview: String {
        messages.first(where: { $0.role == .user })?.content ?? "New conversation"
    }
}

// MARK: - Nova AI Tab

struct NovaAITab: View {
    @State private var sessions: [ChatSession] = []
    @State private var isInChat = false
    @State private var currentSessionId: UUID? = nil

    // Active chat state
    @State private var messages: [ChatMessage] = []
    @State private var rawStream: String = ""
    @State private var isProcessing = false
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
        Group {
            if isInChat {
                chatScreen
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                homeScreen
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.88), value: isInChat)
    }

    // MARK: - Home Screen

    private var homeScreen: some View {
        VStack(spacing: 0) {
            homeHeader

            if sessions.isEmpty {
                emptyHomeState
            } else {
                sessionsList
            }
        }
    }

    private var homeHeader: some View {
        HStack(spacing: 10) {
            novaIconSmall(size: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text("Nova AI")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("Your on-device AI tutor")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            newChatIconButton
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var newChatIconButton: some View {
        Button(action: startNewChat) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: 0xFFE066))
                .padding(8)
        }
        .buttonStyle(.plain)
    }

    private var emptyHomeState: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                novaIconSmall(size: 100)
                    .shadow(color: Color(hex: 0x5EE7FF, opacity: 0.4), radius: 30)

                Text("No chats yet")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Start a conversation with Nova\nto begin learning!")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            newChatButton
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionsList: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(sessions) { session in
                        sessionRow(session)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)

            newChatButton
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    private func sessionRow(_ session: ChatSession) -> some View {
        let isGenerating = session.id == currentSessionId && isProcessing
        return Button {
            loadSession(session)
        } label: {
            HStack(spacing: 12) {
                novaIconSmall(size: 38)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.preview)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if isGenerating {
                        HStack(spacing: 6) {
                            BouncingDotsRow()
                                .frame(height: 14)
                            Text("Generating…")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: 0xFFE066).opacity(0.8))
                        }
                    } else {
                        Text(session.date, style: .relative)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isGenerating ? Color(hex: 0xFFE066, opacity: 0.05) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isGenerating ? Color(hex: 0xFFE066, opacity: 0.18) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var newChatButton: some View {
        Button(action: startNewChat) {
            HStack(spacing: 8) {
                Image(systemName: isProcessing ? "rays" : "plus")
                    .font(.system(size: 14, weight: .bold))
                Text(LocalizedStringKey(isProcessing ? "Nova is thinking…" : "New Chat"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(Color(hex: 0x1A0B40))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isProcessing
                        ? [Color(hex: 0xFFE066, opacity: 0.45), Color(hex: 0xFF8A4C, opacity: 0.45)]
                        : [Color(hex: 0xFFE066), Color(hex: 0xFF8A4C)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: 0xFF8A4C, opacity: isProcessing ? 0.15 : 0.45), radius: 14, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    // MARK: - Chat Screen

    private var chatScreen: some View {
        VStack(spacing: 0) {
            chatHeader

            ZStack {
                messagesView
                    .allowsHitTesting(!messages.isEmpty || isProcessing)

                if messages.isEmpty && !isProcessing {
                    welcomeState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isProcessing && downloadProgress > 0 && downloadProgress < 1.0 {
                downloadBanner
            }

            inputBar
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 10) {
            Button(action: exitChat) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.07)))
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)

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
                        currentSessionId = nil
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
    }

    // MARK: - Welcome State

    private var welcomeState: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                VStack(spacing: 14) {
                    novaIconSmall(size: 90)

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
                                Text(LocalizedStringKey(suggestion))
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
                VStack(spacing: 0) {
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
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
            .onChange(of: messages.count) {
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: rawStream) {
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: isProcessing) {
                if !isProcessing {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        if msg.role == .user {
            userBubble(msg.content)
        } else if msg.content.hasPrefix("Oops!") {
            novaErrorBubble(msg.content)
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

            NovaMarkdownText(content: text)
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

    private func novaErrorBubble(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image("Nova Image")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .opacity(0.7)

            VStack(alignment: .leading, spacing: 6) {
                Text("Nova ran into a problem")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: 0xFF8A8A))

                Text(text)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: 0xFF3B3B, opacity: 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: 0xFF8A8A, opacity: 0.25), lineWidth: 1)
            )

            Spacer(minLength: 40)
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
        HStack(alignment: .center, spacing: 10) {
            TextField("Ask Nova anything…", text: $inputText, axis: .vertical)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white)
                .tint(Color(hex: 0xFFE066))
                .lineLimit(1...6)
                .submitLabel(.send)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .focused($inputFocused)
                .onChange(of: inputText) {
                    if inputText.last == "\n" {
                        inputText = String(inputText.dropLast())
                        if canSend { sendMessage() }
                    }
                }

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
            .padding(.trailing, 6)
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
        Image("Nova Image")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: Color(hex: 0x5EE7FF, opacity: 0.4), radius: size * 0.25)
    }

    // MARK: - Navigation Actions

    private func startNewChat() {
        guard !isProcessing else { return }
        messages = []
        rawStream = ""
        downloadProgress = 0.0
        currentSessionId = nil
        isInChat = true
    }

    private func loadSession(_ session: ChatSession) {
        // Re-entering the session that's currently generating — just navigate back in
        if session.id == currentSessionId {
            isInChat = true
            return
        }
        guard !isProcessing else { return }
        messages = session.messages
        rawStream = ""
        isProcessing = false
        currentSessionId = session.id
        isInChat = true
    }

    private func exitChat() {
        inputFocused = false
        guard !messages.isEmpty else {
            isInChat = false
            return
        }
        if let sid = currentSessionId, let idx = sessions.firstIndex(where: { $0.id == sid }) {
            sessions[idx].messages = messages
        } else {
            // First exit — assign an ID so onComplete can update this session later
            let newSession = ChatSession(messages: messages)
            currentSessionId = newSession.id
            sessions.insert(newSession, at: 0)
        }
        // Leave messages/rawStream/isProcessing intact — generation continues in background
        isInChat = false
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
                    // Persist final answer into whichever session this belongs to
                    if let sid = self.currentSessionId,
                       let idx = self.sessions.firstIndex(where: { $0.id == sid }) {
                        self.sessions[idx].messages = self.messages
                    }
                }
            }
        )
    }
}

// MARK: - Markdown Text

private struct NovaMarkdownText: View {
    let content: String

    private var attributed: AttributedString? {
        try? AttributedString(
            markdown: content,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )
    }

    var body: some View {
        if let attributed {
            Text(attributed)
        } else {
            Text(content)
        }
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
