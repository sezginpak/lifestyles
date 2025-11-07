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
    @State private var sortOrder: SortOrder = .recentFirst
    @State private var filterOption: FilterOption = .all
    @State private var showFilterMenu = false

    // Selection State
    @State private var isEditMode = false
    @State private var selectedConversations: Set<UUID> = []

    enum ConversationMode: String, CaseIterable {
        case general = "Genel"
        case friends = "Arkadaşlar"
    }

    enum SortOrder: String, CaseIterable {
        case recentFirst = "En Yeni"
        case oldestFirst = "En Eski"
        case nameAZ = "İsim (A-Z)"
        case messageCount = "Mesaj Sayısı"
    }

    enum FilterOption: String, CaseIterable {
        case all = "Tümü"
        case favorites = "Favoriler"
        case pinned = "Sabitlenmiş"
    }

    var body: some View {
        VStack(spacing: 0) {
                // Statistics Summary
                if !allConversations.isEmpty {
                    statisticsSummaryView
                        .padding(.horizontal)
                        .padding(.vertical, Spacing.small)
                }

                // Segmented Control
                Picker("Mod", selection: $selectedMode) {
                    ForEach(ConversationMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, Spacing.small)

                // Filter and Sort Bar
                filterSortBar
                    .padding(.horizontal)
                    .padding(.bottom, Spacing.small)

                Divider()

                // Conversation List
                if filteredConversations.isEmpty {
                    emptyStateView
                } else {
                    conversationList
                }
            }
            .searchable(text: $searchText, prompt: "Sohbet ara...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditMode {
                        Button(String(localized: "button.cancel", comment: "Cancel button")) {
                            withAnimation {
                                isEditMode = false
                                selectedConversations.removeAll()
                            }
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isEditMode {
                        Button(selectedConversations.count == filteredConversations.count ? "Hiçbiri" : "Tümü") {
                            withAnimation {
                                if selectedConversations.count == filteredConversations.count {
                                    selectedConversations.removeAll()
                                } else {
                                    selectedConversations = Set(filteredConversations.map { $0.id })
                                }
                            }
                            HapticFeedback.light()
                        }
                        .disabled(filteredConversations.isEmpty)
                    } else {
                        HStack(spacing: 12) {
                            // Seç butonu
                            Button {
                                withAnimation {
                                    isEditMode = true
                                }
                                HapticFeedback.light()
                            } label: {
                                Text(String(localized: "chat.select", comment: "Select button"))
                            }
                            .disabled(filteredConversations.isEmpty)

                            // Mevcut menu
                            Menu {
                                Button {
                                    deleteAllConversations()
                                } label: {
                                    Label(String(localized: "label.tümünü.sil"), systemImage: "trash")
                                }

                                Button {
                                    Task {
                                        await generateMissingTitles()
                                    }
                                } label: {
                                    Label(String(localized: "label.başlıkları.yenile"), systemImage: "arrow.clockwise")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isEditMode && !selectedConversations.isEmpty {
                    deleteSelectedButton
                }
            }
    }

    // MARK: - Statistics Summary

    private var statisticsSummaryView: some View {
        HStack(spacing: Spacing.medium) {
            // Total conversations
            StatBadge(
                icon: "bubble.left.and.bubble.right",
                value: "\(modeFilteredConversations.count)",
                label: "Sohbet",
                color: .blue
            )

            // Total messages
            StatBadge(
                icon: "text.bubble",
                value: "\(totalMessageCount)",
                label: "Mesaj",
                color: .green
            )

            // Favorites
            StatBadge(
                icon: "star.fill",
                value: "\(modeFilteredConversations.filter { $0.isFavorite }.count)",
                label: "Favori",
                color: .yellow
            )

            Spacer()
        }
    }

    // MARK: - Filter and Sort Bar

    private var filterSortBar: some View {
        HStack(spacing: Spacing.small) {
            // Filter button
            Menu {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Button {
                        withAnimation {
                            filterOption = option
                        }
                        HapticFeedback.light()
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if filterOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                    Text(filterOption.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.1))
                )
            }

            // Sort button
            Menu {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        withAnimation {
                            sortOrder = order
                        }
                        HapticFeedback.light()
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.caption)
                    Text(sortOrder.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.purple.opacity(0.1))
                )
            }

            Spacer()

            // Result count
            Text(String(localized: "text.sortedandfilteredconversationscount.sonuç"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.medium) {
                // Pinned conversations
                if !pinnedConversations.isEmpty {
                    Section {
                        ForEach(Array(pinnedConversations.enumerated()), id: \.element.id) { index, conversation in
                            conversationRow(conversation)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.05), value: sortedAndFilteredConversations)
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
                ForEach(Array(unpinnedConversations.enumerated()), id: \.element.id) { index, conversation in
                    conversationRow(conversation)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.05), value: sortedAndFilteredConversations)
                }
            }
            .padding()
        }
        .overlay {
            if isRefreshing {
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .fill(.ultraThinMaterial)
                        )
                    Spacer()
                }
                .padding(.top, 80)
            }
        }
        .refreshable {
            await refreshConversations()
        }
    }

    @ViewBuilder
    private func conversationRow(_ conversation: ChatConversation) -> some View {
        if isEditMode {
            // Edit mode: Tıklanabilir row with checkbox
            Button {
                withAnimation {
                    if selectedConversations.contains(conversation.id) {
                        selectedConversations.remove(conversation.id)
                    } else {
                        selectedConversations.insert(conversation.id)
                    }
                }
                HapticFeedback.light()
            } label: {
                HStack(spacing: Spacing.medium) {
                    // Checkbox
                    Image(systemName: selectedConversations.contains(conversation.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(selectedConversations.contains(conversation.id) ? .blue : .secondary)

                    ConversationCard(
                        conversation: conversation,
                        onDelete: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                deleteConversation(conversation)
                            }
                        },
                        onToggleFavorite: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                conversation.toggleFavorite()
                                try? modelContext.save()
                            }
                        },
                        onEdit: {
                            try? modelContext.save()
                        }
                    )
                }
            }
            .buttonStyle(.plain)
        } else {
            // Normal mode: NavigationLink with swipe actions
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
                    onDelete: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            deleteConversation(conversation)
                        }
                    },
                    onToggleFavorite: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            conversation.toggleFavorite()
                            try? modelContext.save()
                        }
                    },
                    onEdit: {
                        try? modelContext.save()
                    }
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        deleteConversation(conversation)
                    }
                } label: {
                    Label(String(localized: "button.delete", comment: "Delete button"), systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        conversation.toggleFavorite()
                        try? modelContext.save()
                    }
                    HapticFeedback.light()
                } label: {
                    Label(
                        conversation.isFavorite ? "Çıkar" : "Favori",
                        systemImage: conversation.isFavorite ? "star.slash" : "star.fill"
                    )
                }
                .tint(.yellow)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        conversation.togglePin()
                        try? modelContext.save()
                    }
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
    }

    // MARK: - Delete Selected Button

    private var deleteSelectedButton: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                // Seçili sayı
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "text.selectedconversationscount.seçili"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if selectedConversations.count > 1 {
                        Text(String(localized: "chat.selected", comment: "Chat selected (plural)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(localized: "chat.selected", comment: "Chat selected (singular)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Sil butonu
                Button(role: .destructive) {
                    deleteSelectedConversations()
                } label: {
                    Label(String(localized: "button.delete", comment: "Delete button"), systemImage: "trash")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.red)
                        )
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.large) {
            Spacer()

            // Animated Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: searchText.isEmpty ? "bubble.left.and.bubble.right" : "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: searchText.isEmpty)

            VStack(spacing: Spacing.small) {
                Text(emptyStateTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(emptyStateSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.extraLarge)
            }

            // Quick tips for empty state (only when no search)
            if searchText.isEmpty && filterOption == .all {
                VStack(spacing: Spacing.small) {
                    QuickTipRow(icon: "brain.head.profile", text: "Genel sohbetler için AI ile konuşun")
                    QuickTipRow(icon: "person.2.fill", text: "Arkadaşlarınız hakkında tavsiye alın")
                    QuickTipRow(icon: "sparkles", text: "Sohbet geçmişiniz otomatik kaydedilir")
                }
                .padding(.horizontal)
                .padding(.top, Spacing.medium)
            }

            Spacer()
        }
        .padding()
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "Sonuç Bulunamadı"
        }

        switch filterOption {
        case .all:
            return "Henüz Sohbet Yok"
        case .favorites:
            return "Favori Sohbet Yok"
        case .pinned:
            return "Sabitlenmiş Sohbet Yok"
        }
    }

    private var emptyStateSubtitle: String {
        if !searchText.isEmpty {
            return "'\(searchText)' araması için sonuç bulunamadı. Farklı bir arama terimi deneyin."
        }

        switch filterOption {
        case .all:
            return selectedMode == .general
                ? "AI ile genel sohbet başlatın ve konuşmalarınız burada görünsün"
                : "Arkadaşlarınız hakkında AI ile konuşmaya başlayın"
        case .favorites:
            return "Henüz favori olarak işaretlediğiniz bir sohbet yok"
        case .pinned:
            return "Önemli sohbetleri sabitlediğinizde burada görünecek"
        }
    }

    // MARK: - Filtered & Sorted Conversations

    private var modeFilteredConversations: [ChatConversation] {
        switch selectedMode {
        case .general:
            return allConversations.filter { $0.isGeneralMode }
        case .friends:
            return allConversations.filter { !$0.isGeneralMode }
        }
    }

    private var searchFilteredConversations: [ChatConversation] {
        let conversations = modeFilteredConversations

        // Search filter
        if searchText.isEmpty {
            return conversations
        } else {
            return conversations.filter { conversation in
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

    private var filteredByOption: [ChatConversation] {
        let conversations = searchFilteredConversations

        switch filterOption {
        case .all:
            return conversations
        case .favorites:
            return conversations.filter { $0.isFavorite }
        case .pinned:
            return conversations.filter { $0.isPinned }
        }
    }

    private var sortedAndFilteredConversations: [ChatConversation] {
        let conversations = filteredByOption

        switch sortOrder {
        case .recentFirst:
            return conversations.sorted { $0.updatedAt > $1.updatedAt }
        case .oldestFirst:
            return conversations.sorted { $0.updatedAt < $1.updatedAt }
        case .nameAZ:
            return conversations.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .messageCount:
            return conversations.sorted { $0.messageCount > $1.messageCount }
        }
    }

    private var pinnedConversations: [ChatConversation] {
        sortedAndFilteredConversations.filter { $0.isPinned }
    }

    private var unpinnedConversations: [ChatConversation] {
        sortedAndFilteredConversations.filter { !$0.isPinned }
    }

    private var totalMessageCount: Int {
        modeFilteredConversations.reduce(0) { $0 + $1.messageCount }
    }

    // Legacy property for backward compatibility
    private var filteredConversations: [ChatConversation] {
        sortedAndFilteredConversations
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

    private func deleteSelectedConversations() {
        let conversationsToDelete = allConversations.filter { selectedConversations.contains($0.id) }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            for conversation in conversationsToDelete {
                modelContext.delete(conversation)
            }
            try? modelContext.save()

            // Reset state
            selectedConversations.removeAll()
            isEditMode = false
        }

        HapticFeedback.success()
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

// MARK: - Helper Components

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct QuickTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(Color(.tertiarySystemBackground))
        )
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
