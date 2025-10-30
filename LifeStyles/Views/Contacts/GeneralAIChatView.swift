//
//  GeneralAIChatView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Genel AI Chat wrapper - arkadaş özel değil
//  Updated with conversation support on 25.10.2025
//

import SwiftUI
import SwiftData

struct GeneralAIChatView: View {
    @Environment(\.modelContext) private var modelContext

    let existingConversation: ChatConversation?

    @State private var chatMessages: [ChatMessage] = []
    @State private var userInput: String = ""
    @State private var isGeneratingAI = false

    init(existingConversation: ChatConversation? = nil) {
        self.existingConversation = existingConversation
    }

    var body: some View {
        FriendAIChatView(
            friend: nil,  // Genel mod
            existingConversation: existingConversation,
            chatMessages: $chatMessages,
            userInput: $userInput,
            isGeneratingAI: $isGeneratingAI
        )
        .environment(\.modelContext, modelContext)
    }
}

#Preview {
    GeneralAIChatView()
}
