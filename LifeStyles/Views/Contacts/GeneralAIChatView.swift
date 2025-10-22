//
//  GeneralAIChatView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Genel AI Chat wrapper - arkadaş özel değil
//

import SwiftUI
import SwiftData

struct GeneralAIChatView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var chatMessages: [ChatMessage] = []
    @State private var userInput: String = ""
    @State private var isGeneratingAI = false

    var body: some View {
        FriendAIChatView(
            friend: nil,  // Genel mod
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
