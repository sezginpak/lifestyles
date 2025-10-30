//
//  ChatMessage.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Individual AI chat messages
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date

    // Relationship to conversation
    var conversation: ChatConversation?

    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
