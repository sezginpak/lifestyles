//
//  FriendDetailChatTab.swift
//  LifeStyles
//
//  Extracted from FriendDetailTabs.swift - Phase 6
//  Chat tab wrapper using FriendAIChatView for AI-powered chat
//

import SwiftUI

struct FriendDetailChatTab: View {
    @Bindable var friend: Friend
    @Binding var chatMessages: [ChatMessage]
    @Binding var userInput: String
    @Binding var isGeneratingAI: Bool

    var body: some View {
        FriendAIChatView(
            friend: friend,
            chatMessages: $chatMessages,
            userInput: $userInput,
            isGeneratingAI: $isGeneratingAI
        )
    }
}
