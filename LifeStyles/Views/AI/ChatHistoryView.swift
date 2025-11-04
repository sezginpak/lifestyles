//
//  ChatHistoryView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  AI Chat conversation history with search, favorites, and organization
//

import SwiftUI
import SwiftData

struct ChatHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Query all conversations
    @Query(sort: \ChatConversation.updatedAt, order: .reverse)
    private var allConversations: [ChatConversation]

    // UI State
    @State private var selectedMode: ConversationMode = .general
    @State private var searchText = ""
    @State private var isRefreshing = false

    enum ConversationMode: String, CaseIterable {
        case general = "Genel"
        case friends = "Arkadaşlar"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Mod", selection: $selectedMode) {
                    ForEach(ConversationMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, Spacing.small)

                // Conversation List
                if filteredConversations.isEmpty {
                    emptyStateView
                } else {
                    conversationList
                }
            }
            .navigationTitle("Sohbet Geçmişi")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Sohbet ara...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            Text(String(localized: "ai.back", comment: "Back"))
                                .font(.subheadline)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            deleteAllConversations()
                        } label: {
                            Label("Tümünü Sil", systemImage: "trash")
                        }

                        Button {
                            Task {
                                await generateMissingTitles()
                            }
                        } label: {
                            Label("Başlıkları Yenile", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.medium) {
                // Pinned conversations
                if !pinnedConversations.isEmpty {
                    Section {
                        ForEach(pinnedConversations) { conversation in
                            conversationRow(conversation)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                            Text(String(localized: "chat.pinned", comment: "Pinned"))
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.top, Spacing.small)
                    }
                }

                // Regular conversations
                ForEach(unpinnedConversations) { conversation in
                    conversationRow(conversation)
                }
            }
            .padding()
        }
        .refreshable {
            await refreshConversations()
        }
    }

    private func conversationRow(_ conversation: ChatConversation) -> some View {
        NavigationLink {
            // Navigate to conversation
            if conversation.isGeneralMode {
                GeneralAIChatView(existingConversation: conversation)
            } else {
                // Friend-specific chat
                if let friendId = conversation.friendId {
                    FriendAIChatView(
                        friend: findFriend(by: friendId),
                        existingConversation: conversation
                    )
                }
            }
        } label: {
            ConversationCard(
                conversation: conversation,
                onTap: {
                    // NavigationLink handles the tap
                },
                onDelete: {
                    deleteConversation(conversation)
                },
                onToggleFavorite: {
                    conversation.toggleFavorite()
                    try? modelContext.save()
                },
                onEdit: {
                    try? modelContext.save()
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteConversation(conversation)
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                conversation.toggleFavorite()
                try? modelContext.save()
                HapticFeedback.light()
            } label: {
                Label(
                    conversation.isFavorite ? "Çıkar" : "Favori",
                    systemImage: conversation.isFavorite ? "star.slash" : "star.fill"
                )
            }
            .tint(.yellow)

            Button {
                conversation.togglePin()
                try? modelContext.save()
                HapticFeedback.light()
            } label: {
                Label(
                    conversation.isPinned ? "Çıkar" : "Sabitle",
                    systemImage: conversation.isPinned ? "pin.slash" : "pin.fill"
                )
            }
            .tint(.orange)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.large) {
            Spacer()

            Image(systemName: searchText.isEmpty ? "bubble.left.and.bubble.right" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.small) {
                Text(searchText.isEmpty ? "Henüz sohbet yok" : "Sonuç bulunamadı")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(searchText.isEmpty
                     ? "AI ile sohbet başlatın ve geçmişiniz burada görünsün"
                     : "'\(searchText)' için sonuç bulunamadı")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Filtered Conversations

    private var filteredConversations: [ChatConversation] {
        let modeFiltered: [ChatConversation]
        switch selectedMode {
        case .general:
            modeFiltered = allConversations.filter { $0.isGeneralMode }
        case .friends:
            modeFiltered = allConversations.filter { !$0.isGeneralMode }
        }

        // Search filter
        if searchText.isEmpty {
            return modeFiltered
        } else {
            return modeFiltered.filter { conversation in
                // Search in title
                if conversation.title.localizedCaseInsensitiveContains(searchText) {
                    return true
                }

                // Search in messages
                if let messages = conversation.messages {
                    return messages.contains { message in
                        message.content.localizedCaseInsensitiveContains(searchText)
                    }
                }

                return false
            }
        }
    }

    private var pinnedConversations: [ChatConversation] {
        filteredConversations.filter { $0.isPinned }
    }

    private var unpinnedConversations: [ChatConversation] {
        filteredConversations.filter { !$0.isPinned }
    }

    // MARK: - Helper Methods

    private func findFriend(by id: UUID) -> Friend? {
        let descriptor = FetchDescriptor<Friend>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func deleteConversation(_ conversation: ChatConversation) {
        withAnimation {
            modelContext.delete(conversation)
            try? modelContext.save()
        }
        HapticFeedback.success()
    }

    private func deleteAllConversations() {
        // Show confirmation
        let conversations = selectedMode == .general
            ? allConversations.filter { $0.isGeneralMode }
            : allConversations.filter { !$0.isGeneralMode }

        withAnimation {
            for conversation in conversations {
                modelContext.delete(conversation)
            }
            try? modelContext.save()
        }
        HapticFeedback.warning()
    }

    private func refreshConversations() async {
        isRefreshing = true
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        isRefreshing = false
    }

    private func generateMissingTitles() async {
        let conversationsWithoutAI = filteredConversations.filter { !$0.hasAITitle }

        guard !conversationsWithoutAI.isEmpty else { return }

        HapticFeedback.light()

        for conversation in conversationsWithoutAI {
            let title = await ChatTitleGenerator.shared.generateTitle(from: conversation)
            conversation.updateTitle(title, isAIGenerated: true)
        }

        try? modelContext.save()
        HapticFeedback.success()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ChatConversation.self, ChatMessage.self,
        configurations: config
    )

    // Add sample data
    let conv1 = ChatConversation(
        title: "Arkadaşlarla iletişim tavsiyeleri",
        isGeneralMode: true,
        isFavorite: true,
        isPinned: true
    )
    let msg1 = ChatMessage(content: "Hangi arkadaşlarımla konuşmalıyım?", isUser: true)
    conv1.addMessage(msg1)
    container.mainContext.insert(conv1)

    let conv2 = ChatConversation(
        title: "Ali ile buluşma fikirleri",
        friendId: UUID(),
        friendName: "Ali",
        isGeneralMode: false
    )
    container.mainContext.insert(conv2)

    return ChatHistoryView()
        .modelContainer(container)
}
