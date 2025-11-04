//
//  ChatConversation.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  SwiftData model for AI chat conversations with persistent history
//

import Foundation
import SwiftData

@Model
final class ChatConversation {
    // MARK: - Properties

    var id: UUID = UUID()
    var title: String = "Yeni Sohbet"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Friend-specific conversation (nil = general mode)
    var friendId: UUID?
    var friendName: String?  // Cached for display
    var isGeneralMode: Bool = true

    // Organization
    var isFavorite: Bool = false
    var isPinned: Bool = false

    // Auto-generated title state
    var hasAITitle: Bool = false  // true = AI generated, false = manual/default

    // Messages relationship
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.conversation)
    var messages: [ChatMessage]?

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        title: String = "Yeni Sohbet",
        friendId: UUID? = nil,
        friendName: String? = nil,
        isGeneralMode: Bool = true,
        isFavorite: Bool = false,
        isPinned: Bool = false,
        hasAITitle: Bool = false
    ) {
        self.id = id
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.friendId = friendId
        self.friendName = friendName
        self.isGeneralMode = isGeneralMode
        self.isFavorite = isFavorite
        self.isPinned = isPinned
        self.hasAITitle = hasAITitle
        self.messages = []
    }

    // MARK: - Computed Properties

    var messageCount: Int {
        messages?.count ?? 0
    }

    var lastMessage: ChatMessage? {
        messages?.sorted(by: { $0.timestamp < $1.timestamp }).last
    }

    var lastMessagePreview: String {
        guard let last = lastMessage else {
            return "Henüz mesaj yok"
        }

        let content = last.content
        if content.count > 60 {
            return String(content.prefix(60)) + "..."
        }
        return content
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }

    // MARK: - Methods

    func addMessage(_ message: ChatMessage) {
        if messages == nil {
            messages = []
        }
        messages?.append(message)
        updatedAt = Date()
    }

    func updateTitle(_ newTitle: String, isAIGenerated: Bool = false) {
        title = newTitle
        hasAITitle = isAIGenerated
        updatedAt = Date()
    }

    func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }

    func togglePin() {
        isPinned.toggle()
        updatedAt = Date()
    }
}
