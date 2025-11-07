//
//  FriendAIChatView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Enhanced with Claude Haiku AI
//

import SwiftUI

// MARK: - Component Imports
// Supporting views have been extracted to separate files for better modularity
// Located in Views/Contacts/Components/Chat/

struct FriendAIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let friend: Friend?  // Optional - nil ise genel mod
    let existingConversation: ChatConversation?  // Existing conversation to load

    @Binding var chatMessages: [ChatMessage]
    @Binding var userInput: String
    @Binding var isGeneratingAI: Bool

    // Conversation management
    @State private var conversation: ChatConversation?
    @State private var hasGeneratedTitle = false

    // AI Services
    @State private var chatService = ChatHaikuService.shared
    @State private var usageManager = AIUsageManager.shared
    @State private var purchaseManager = PurchaseManager.shared
    @State private var privacySettings = AIPrivacySettings.shared
    @State private var questionService = QuickQuestionService.shared

    // Quick Questions
    @State private var quickQuestions: [QuickQuestion] = []
    @State private var isLoadingQuestions = false

    // UI State
    @State private var showPaywall = false
    @State private var showDataUsageInfo = false
    @State private var showAIDisabledAlert = false
    @State private var showHistorySheet = false
    @FocusState private var isInputFocused: Bool

    // Genel mod mu?
    var isGeneralMode: Bool {
        friend == nil
    }

    // MARK: - Initializer

    init(
        friend: Friend? = nil,
        existingConversation: ChatConversation? = nil,
        chatMessages: Binding<[ChatMessage]> = .constant([]),
        userInput: Binding<String> = .constant(""),
        isGeneratingAI: Binding<Bool> = .constant(false)
    ) {
        self.friend = friend
        self.existingConversation = existingConversation
        self._chatMessages = chatMessages
        self._userInput = userInput
        self._isGeneratingAI = isGeneratingAI
    }

    var body: some View {
        VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Empty State
                            if chatMessages.isEmpty && !isGeneratingAI {
                                emptyStateView
                                    .padding(.top, 40)
                            } else {
                                // Messages
                                ForEach(chatMessages) { message in
                                    VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                                        ModernChatBubble(message: message)
                                            .id(message.id)
                                            .transition(.scale.combined(with: .opacity))

                                        // Transparency badge (only for AI messages)
                                        if !message.isUser, let lastUsage = privacySettings.lastRequestDataCount {
                                            DataTransparencyBadge(dataCount: lastUsage) {
                                                showDataUsageInfo = true
                                            }
                                        }
                                    }
                                }

                                // Typing Indicator
                                if isGeneratingAI {
                                    StreamingTypingIndicator()
                                        .id("typing")
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .padding()
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: chatMessages.count)
                    }
                    .onChange(of: chatMessages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isGeneratingAI) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isInputFocused) { _, newValue in
                        if newValue {
                            // Klavye açıldığında biraz bekleyip scroll et
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                scrollToBottom(proxy: proxy)
                            }
                        }
                    }
                    .onTapGesture {
                        isInputFocused = false
                    }
                }

                Divider()

                // Modern Input Area
                modernInputArea
            }
            .navigationTitle(String(localized: "nav.ai.chat"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // History button
                        Button {
                            showHistorySheet = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.body)
                        }

                        // Menu
                        Menu {
                            Button {
                                clearChat()
                            } label: {
                                Label(String(localized: "ai.chat.clear", comment: "Clear Chat"), systemImage: "trash")
                            }

                            Button {
                                shareChat()
                            } label: {
                                Label(String(localized: "ai.chat.share", comment: "Share Chat"), systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .onAppear {
                // Load or create conversation
                loadOrCreateConversation()

                // Load quick questions
                Task {
                    await loadQuickQuestions()
                }

                // Auto-focus input on appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInputFocused = true
                }
            }
            .onDisappear {
                // Generate title if needed
                Task {
                    await generateTitleIfNeeded()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showDataUsageInfo) {
                DataUsageInfoSheet()
            }
            .sheet(isPresented: $showHistorySheet) {
                ChatHistoryView()
            }
            .alert(String(localized: "ai.features.disabled", comment: "AI Features Disabled"), isPresented: $showAIDisabledAlert) {
                Button(String(localized: "common.go.to.settings", comment: "Go to Settings")) {
                    // Navigate to settings - NOT IMPLEMENTED YET
                    // For now just dismiss
                }
                Button(String(localized: "common.ok", comment: "OK"), role: .cancel) {}
            } message: {
                Text(String(localized: "ai.chat.enable.instruction", comment: "Instructions to enable AI chat from settings"))
            }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Animated AI Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 8) {
                Text(String(localized: "ai.chat.assistant", comment: "AI Assistant"))
                    .font(.title2)
                    .fontWeight(.bold)

                Text(isGeneralMode
                    ? String(localized: "ai.chat.general.description", comment: "General AI chat description")
                    : String(format: NSLocalizedString("ai.chat.friend.description.format", comment: "Friend AI chat description with name"), friend!.name))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Dynamic Quick Questions (AI-powered)
            VStack(spacing: 12) {
                HStack {
                    Text(quickQuestionsTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Refresh button
                    if !isLoadingQuestions {
                        Button {
                            HapticFeedback.light()
                            Task {
                                await loadQuickQuestions(forceRefresh: true)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if quickQuestions.isEmpty && !isLoadingQuestions {
                    Text(String(localized: "friend.quick.questions.loading", comment: "Loading quick questions..."))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(quickQuestions) { question in
                        ModernQuickQuestionButton(
                            icon: question.icon,
                            question: question.question,
                            gradient: [
                                Color(hex: question.gradientStartHex),
                                Color(hex: question.gradientEndHex)
                            ]
                        ) {
                            // Click tracking
                            question.recordClick()
                            try? modelContext.save()

                            userInput = question.prompt
                            sendMessage()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Modern Input Area

    private var modernInputArea: some View {
        HStack(spacing: 12) {
            // Text Input
            HStack(spacing: 8) {
                TextField(String(localized: "ai.chat.input.placeholder", comment: "Ask a question..."), text: $userInput, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...4)
                    .disabled(isGeneratingAI)
                    .focused($isInputFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isInputFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: isInputFocused)

            // Send Button
            Button {
                HapticFeedback.light()
                sendMessage()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            userInput.isEmpty ?
                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: isGeneratingAI ? "stop.fill" : "arrow.up")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: !userInput.isEmpty)
                }
            }
            .disabled(userInput.isEmpty && !isGeneratingAI)
            .scaleEffect(userInput.isEmpty ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userInput.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Send Message

    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // CHECK AI FEATURES ENABLED
        if !privacySettings.hasGivenAIConsent || !privacySettings.aiChatEnabled {
            HapticFeedback.warning()
            showAIDisabledAlert = true
            return
        }

        // CHECK USAGE LIMIT (Free tier: 5 messages/day)
        let canSend = usageManager.canSendMessage(isPremium: purchaseManager.isPremium)

        if !canSend {
            // Show paywall
            HapticFeedback.warning()
            showPaywall = true
            return
        }

        // Haptic feedback
        HapticFeedback.medium()

        // Add user message
        let userMessage = ChatMessage(content: userInput, isUser: true)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            chatMessages.append(userMessage)
        }

        // Save to conversation
        saveMessageToConversation(userMessage)

        let question = userInput
        userInput = ""
        isGeneratingAI = true
        isInputFocused = false

        // Track usage
        usageManager.trackMessage()

        Task {
            await handleHaikuResponse(question: question)
        }
    }

    // MARK: - Haiku Response

    private func handleHaikuResponse(question: String) async {
        do {
            // Call ChatHaikuService
            let response = try await chatService.chat(
                friend: friend,
                question: question,
                chatHistory: chatMessages,
                modelContext: modelContext
            )

            // Add AI response
            await MainActor.run {
                let aiMessage = ChatMessage(content: response, isUser: false)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    chatMessages.append(aiMessage)
                }

                // Save to conversation
                saveMessageToConversation(aiMessage)

                HapticFeedback.success()
                isGeneratingAI = false
            }
        } catch ChatError.aiDisabled {
            print("❌ AI disabled")

            await MainActor.run {
                showAIDisabledAlert = true
                isGeneratingAI = false
                HapticFeedback.warning()
            }
        } catch {
            print("❌ Chat error: \(error)")

            // Fallback response
            await MainActor.run {
                let fallbackMessage = String(localized: "ai.chat.error.fallback", comment: "Sorry, I cannot respond right now. Please try again.")
                let aiMessage = ChatMessage(content: fallbackMessage, isUser: false)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    chatMessages.append(aiMessage)
                }
                HapticFeedback.error()
                isGeneratingAI = false
            }
        }
    }

    // MARK: - Helper Functions

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                if isGeneratingAI {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let lastMessage = chatMessages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    private func clearChat() {
        HapticFeedback.warning()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            chatMessages.removeAll()
        }
    }

    /// Mesajın uzunluğunu kontrol eder ve gerekirse kısaltır
    /// - Parameters:
    ///   - message: Kontrol edilecek mesaj
    ///   - maxLength: Maksimum karakter sayısı (varsayılan 350)
    /// - Returns: Gerekirse kısaltılmış mesaj
    private func truncateIfNeeded(_ message: String, maxLength: Int = 350) -> String {
        if message.count > maxLength {
            let truncated = String(message.prefix(maxLength - 20))
            return truncated + "...\n\n(Çok uzun)"
        }
        return message
    }

    private func shareChat() {
        let chatText = chatMessages.map { message in
            "\(message.isUser ? String(localized: "ai.chat.me", comment: "Me") : "AI"): \(message.content)"
        }.joined(separator: "\n\n")

        let activityVC = UIActivityViewController(
            activityItems: [chatText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }

    // MARK: - Smart Quick Actions

    // MARK: - Quick Questions Management

    /// Hızlı soruları yükle (cache'den veya AI ile)
    @MainActor
    private func loadQuickQuestions(forceRefresh: Bool = false) async {
        isLoadingQuestions = true

        // Kategoriyi belirle
        let category: QuickQuestionCategory = isGeneralMode ? .generalChat : .friendChat

        // Soruları getir
        let questions = await questionService.getQuestions(
            for: category,
            friend: friend,
            chatHistory: chatMessages,
            modelContext: modelContext,
            forceRefresh: forceRefresh
        )

        quickQuestions = questions
        isLoadingQuestions = false
    }

    /// Quick questions başlığı
    var quickQuestionsTitle: String {
        if isGeneralMode {
            return "Hızlı Sorular"
        }

        guard let friend = friend else { return "Hızlı Sorular" }

        if friend.needsContact {
            return "⚠️ Acil Eylemler"
        } else if friend.isPartner {
            return "💝 Partner İçin"
        } else {
            return "Hızlı Sorular"
        }
    }

    // MARK: - Conversation Memory

    /// Son N mesajı context olarak hazırla (8-10 mesaj, her biri kısaltılmış)
    func buildConversationContext(limit: Int = 10) -> String {
        guard !chatMessages.isEmpty else { return "" }

        let recentMessages = chatMessages.suffix(limit)
        let contextLines = recentMessages.map { msg in
            // Her mesajı 80 karaktere kısalt
            let shortContent = msg.content.count > 80
                ? String(msg.content.prefix(80)) + "..."
                : msg.content
            return "\(msg.isUser ? "Kullanıcı" : "AI"): \(shortContent)"
        }

        return """
        Önceki sohbet:
        \(contextLines.joined(separator: "\n"))
        """
    }

    // MARK: - Conversation Management

    /// Load existing conversation (don't create until first message)
    private func loadOrCreateConversation() {
        if let existing = existingConversation {
            // Load from existing conversation
            conversation = existing

            // Load messages from conversation
            if let messages = existing.messages {
                chatMessages = messages.sorted(by: { $0.timestamp < $1.timestamp })
            }

            print("✅ Loaded existing conversation: \(existing.title) with \(chatMessages.count) messages")
        } else {
            // Don't create conversation yet - wait for first message
            print("ℹ️ No existing conversation - will create on first message")
        }
    }

    /// Create conversation on first message
    private func createConversationIfNeeded() {
        guard conversation == nil else { return }

        let newConversation = ChatConversation(
            title: "Yeni Sohbet",
            friendId: friend?.id,
            friendName: friend?.name,
            isGeneralMode: isGeneralMode,
            isFavorite: false,
            isPinned: false,
            hasAITitle: false
        )

        modelContext.insert(newConversation)
        conversation = newConversation

        print("✅ Created new conversation on first message")
    }

    /// Save message to current conversation
    private func saveMessageToConversation(_ message: ChatMessage) {
        // Create conversation on first message
        createConversationIfNeeded()

        guard let conv = conversation else {
            print("⚠️ Failed to create conversation")
            return
        }

        // Set conversation relationship
        message.conversation = conv

        // Insert message to context
        modelContext.insert(message)

        // Add to conversation
        conv.addMessage(message)

        // Save context
        try? modelContext.save()

        print("💾 Saved message to conversation: \(conv.title)")
    }

    /// Generate AI title if conversation is new and has messages
    private func generateTitleIfNeeded() async {
        guard let conv = conversation else { return }

        // Skip if already has AI-generated title
        if conv.hasAITitle || hasGeneratedTitle {
            return
        }

        // Skip if no messages
        guard let messages = conv.messages, messages.count >= 2 else {
            return
        }

        print("🤖 Generating AI title for conversation...")

        // Generate title
        let title = await ChatTitleGenerator.shared.generateTitle(from: conv)

        // Update conversation
        await MainActor.run {
            conv.updateTitle(title, isAIGenerated: true)
            try? modelContext.save()
            hasGeneratedTitle = true

            print("✅ AI title generated: \(title)")
        }
    }
}

// MARK: - Modern Chat Bubble
// Extracted to Views/Contacts/Components/Chat/ModernChatBubble.swift

// MARK: - Streaming Typing Indicator
// Extracted to Views/Contacts/Components/Chat/StreamingTypingIndicator.swift

// MARK: - Modern Quick Question Button
// Extracted to Views/Contacts/Components/Chat/ModernQuickQuestionButton.swift

// MARK: - Data Transparency Badge
// Extracted to Views/Contacts/Components/Chat/DataTransparencyBadge.swift

// MARK: - Data Usage Info Sheet
// Extracted to Views/Contacts/Components/Chat/DataUsageInfoSheet.swift

// MARK: - Preview

#Preview {
    @Previewable @State var messages: [ChatMessage] = [
        ChatMessage(content: "Merhaba! Bana yardım edebilir misin?", isUser: true),
        ChatMessage(content: "Elbette! Size nasıl yardımcı olabilirim?", isUser: false)
    ]
    @Previewable @State var input: String = ""
    @Previewable @State var generating: Bool = false

    let friend = Friend(name: "Test Arkadaş", frequency: .weekly)

    FriendAIChatView(
        friend: friend,
        chatMessages: $messages,
        userInput: $input,
        isGeneratingAI: $generating
    )
}
