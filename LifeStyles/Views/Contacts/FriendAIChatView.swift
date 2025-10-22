//
//  FriendAIChatView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Enhanced with Claude Haiku AI
//

import SwiftUI

struct FriendAIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let friend: Friend?  // Optional - nil ise genel mod
    @Binding var chatMessages: [ChatMessage]
    @Binding var userInput: String
    @Binding var isGeneratingAI: Bool

    // AI Services
    @State private var chatService = ChatHaikuService.shared
    @State private var usageManager = AIUsageManager.shared
    @State private var purchaseManager = PurchaseManager.shared
    @State private var privacySettings = AIPrivacySettings.shared

    // UI State
    @State private var showPaywall = false
    @State private var showDataUsageInfo = false
    @State private var showAIDisabledAlert = false
    @FocusState private var isInputFocused: Bool

    // Genel mod mu?
    var isGeneralMode: Bool {
        friend == nil
    }

    var body: some View {
        NavigationStack {
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
                    .onTapGesture {
                        isInputFocused = false
                    }
                }

                Divider()

                // Modern Input Area
                modernInputArea
            }
            .navigationTitle("AI Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            Text(String(localized: "common.back", comment: "Back"))
                                .font(.subheadline)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
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
            .onAppear {
                // Auto-focus input on appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInputFocused = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showDataUsageInfo) {
                DataUsageInfoSheet()
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

            // Smart Quick Actions (duruma göre dinamik)
            VStack(spacing: 12) {
                Text(smartActionsTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(smartQuickActions, id: \.question) { action in
                    ModernQuickQuestionButton(
                        icon: action.icon,
                        question: action.question,
                        gradient: action.gradient
                    ) {
                        userInput = action.prompt
                        sendMessage()
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

    /// Quick action modeli
    struct QuickAction {
        let icon: String
        let question: String
        let gradient: [Color]
        let prompt: String
    }

    /// Arkadaş durumuna veya genel moda göre akıllı quick action'lar
    var smartQuickActions: [QuickAction] {
        var actions: [QuickAction] = []

        // GENEL MOD
        if isGeneralMode {
            actions.append(QuickAction(
                icon: "person.3.fill",
                question: "Hangi arkadaşlarla görüşmeliyim?",
                gradient: [.orange, .red],
                prompt: "Hangi arkadaşlarımla iletişim kurmam gerekir?"
            ))

            actions.append(QuickAction(
                icon: "calendar.badge.clock",
                question: "Bu hafta ne yapmalıyım?",
                gradient: [.blue, .cyan],
                prompt: "Bu hafta için önerin nedir?"
            ))

            actions.append(QuickAction(
                icon: "sparkles",
                question: "Motivasyon ver",
                gradient: [.purple, .pink],
                prompt: "Bana motivasyon ver ve günümü nasıl geçirmeliyim?"
            ))

            actions.append(QuickAction(
                icon: "map.fill",
                question: "Aktivite öner",
                gradient: [.green, .mint],
                prompt: "Bugün ne tür aktiviteler yapabilirim?"
            ))

            return actions
        }

        // ARKADAŞ MODU
        guard let friend = friend else { return actions }

        // İletişim gerekiyorsa - ACIL
        if friend.needsContact {
            actions.append(QuickAction(
                icon: "exclamationmark.bubble.fill",
                question: "Mesaj taslağı oluştur",
                gradient: [.red, .orange],
                prompt: "\(friend.name) için acil bir mesaj taslağı yaz"
            ))

            actions.append(QuickAction(
                icon: "clock.fill",
                question: "Ne zaman aramalıyım?",
                gradient: [.orange, .yellow],
                prompt: "\(friend.name)'i ne zaman aramam gerekir?"
            ))
        }
        // Partner ise
        else if friend.isPartner {
            actions.append(QuickAction(
                icon: "heart.fill",
                question: "Randevu fikri ver",
                gradient: [.pink, .red],
                prompt: "\(friend.name) ile romantik bir buluşma fikri öner"
            ))

            actions.append(QuickAction(
                icon: "gift.fill",
                question: "Hediye önerisi al",
                gradient: [.purple, .pink],
                prompt: "\(friend.name) için hediye önerisi ver"
            ))

            if let daysUntil = friend.daysUntilAnniversary, daysUntil <= 30 {
                actions.append(QuickAction(
                    icon: "calendar.badge.clock",
                    question: "Yıldönümü planı",
                    gradient: [.red, .orange],
                    prompt: "Yıldönümümüz yaklaşıyor, önerilerin neler?"
                ))
            }
        }
        // Normal durum
        else {
            actions.append(QuickAction(
                icon: "message.fill",
                question: "Mesaj taslağı oluştur",
                gradient: [.blue, .cyan],
                prompt: "\(friend.name) için bir mesaj taslağı yaz"
            ))

            actions.append(QuickAction(
                icon: "lightbulb.fill",
                question: "İlişki önerisi ver",
                gradient: [.orange, .yellow],
                prompt: "\(friend.name) ile ilişkimi nasıl geliştirebilirim?"
            ))

            actions.append(QuickAction(
                icon: "chart.bar.fill",
                question: "İletişim analizi yap",
                gradient: [.purple, .pink],
                prompt: "\(friend.name) ile iletişim geçmişimi analiz et"
            ))
        }

        return actions
    }

    /// Quick actions başlığı
    var smartActionsTitle: String {
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
}

// MARK: - Modern Chat Bubble

struct ModernChatBubble: View {
    let message: ChatMessage
    var isStreaming: Bool = false

    @State private var showActions = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            } else {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Message Content
                HStack(alignment: .bottom, spacing: 4) {
                    if message.isUser {
                        Text(message.content)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 18,
                                    bottomLeadingRadius: 18,
                                    bottomTrailingRadius: 4,
                                    topTrailingRadius: 18
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        HStack(alignment: .top, spacing: 0) {
                            Text(message.content)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 18,
                                        bottomLeadingRadius: 4,
                                        bottomTrailingRadius: 18,
                                        topTrailingRadius: 18
                                    )
                                )
                                .overlay(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 18,
                                        bottomLeadingRadius: 4,
                                        bottomTrailingRadius: 18,
                                        topTrailingRadius: 18
                                    )
                                    .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
                                )

                            if isStreaming {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.content
                        HapticFeedback.success()
                    } label: {
                        Label(String(localized: "common.copy", comment: "Copy"), systemImage: "doc.on.doc")
                    }
                }

                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Streaming Typing Indicator

struct StreamingTypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
            )

            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Modern Quick Question Button

struct ModernQuickQuestionButton: View {
    let icon: String
    let question: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Data Transparency Badge

struct DataTransparencyBadge: View {
    let dataCount: DataUsageCount
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.caption2)
                Text(dataCount.summary)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Usage Info Sheet

struct DataUsageInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var privacySettings = AIPrivacySettings.shared

    var body: some View {
        NavigationStack {
            List {
                if let dataCount = privacySettings.lastRequestDataCount {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.green)
                                Text(String(localized: "ai.data.last.request", comment: "Last AI Request"))
                                    .font(.headline)
                            }

                            Text(String(localized: "ai.data.used.for.response", comment: "Data used for this response:"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if dataCount.friendsCount > 0 {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(.blue)
                                        .frame(width: 24)
                                    Text(String(format: NSLocalizedString("ai.data.friends.count.format", comment: "Friend information count"), dataCount.friendsCount))
                                        .font(.callout)
                                }
                            }

                            if dataCount.goalsCount > 0 {
                                HStack {
                                    Image(systemName: "target")
                                        .foregroundStyle(.green)
                                        .frame(width: 24)
                                    Text(String(format: NSLocalizedString("ai.data.goals.count.format", comment: "Goals information count"), dataCount.goalsCount))
                                        .font(.callout)
                                }
                            }

                            if dataCount.habitsCount > 0 {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(.purple)
                                        .frame(width: 24)
                                    Text(String(format: NSLocalizedString("ai.data.habits.count.format", comment: "Habits information count"), dataCount.habitsCount))
                                        .font(.callout)
                                }
                            }

                            if dataCount.hasMoodData {
                                HStack {
                                    Image(systemName: "face.smiling")
                                        .foregroundStyle(.orange)
                                        .frame(width: 24)
                                    Text(String(localized: "ai.data.mood", comment: "Mood data"))
                                        .font(.callout)
                                }
                            }

                            if dataCount.hasLocationData {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(.purple)
                                        .frame(width: 24)
                                    Text(String(localized: "ai.data.location", comment: "Location data"))
                                        .font(.callout)
                                }
                            }

                            if dataCount.totalItems == 0 && !dataCount.hasMoodData && !dataCount.hasLocationData {
                                HStack {
                                    Image(systemName: "exclamationmark.circle")
                                        .foregroundStyle(.orange)
                                        .frame(width: 24)
                                    Text(String(localized: "ai.data.not.shared", comment: "No data shared"))
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(dataCount.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 4)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        AIPrivacySettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.purple)
                            Text(String(localized: "ai.privacy.manage.settings", comment: "Manage Privacy Settings"))
                        }
                    }
                } header: {
                    Text(String(localized: "common.settings", comment: "Settings"))
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(String(localized: "ai.privacy.note.1", comment: "Your data is only used to generate AI responses"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(String(localized: "ai.privacy.note.2", comment: "Anthropic does not use your data for training"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(String(localized: "ai.privacy.note.3", comment: "You can control each data type separately"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(String(localized: "ai.privacy.notes", comment: "Privacy Notes"))
                }
            }
            .navigationTitle(String(localized: "ai.data.usage", comment: "Data Usage"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.ok", comment: "OK")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

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
