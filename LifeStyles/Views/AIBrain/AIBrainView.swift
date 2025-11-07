//
//  AIBrainView.swift
//  LifeStyles
//
//  Created by AI Assistant on 06.11.2025.
//  AI Brain - Tab Container (Sohbetler & Bilgiler)
//

import SwiftUI
import SwiftData

struct AIBrainView: View {
    @State private var selectedTab: AIBrainTab = .knowledge

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Tab Content
                TabView(selection: $selectedTab) {
                    // Chat History Tab
                    ChatHistoryView()
                        .tag(AIBrainTab.chat)

                    // Knowledge Tab
                    KnowledgeTabView()
                        .tag(AIBrainTab.knowledge)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(String(localized: "nav.ai.brain"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - AI Brain Tab Enum

enum AIBrainTab: String, CaseIterable {
    case chat = "Sohbetler"
    case knowledge = "Bilgiler"

    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .knowledge: return "brain.head.profile"
        }
    }

    var title: String {
        rawValue
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: AIBrainTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AIBrainTab.allCases, id: \.self) { tab in
                CustomTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    HapticFeedback.light()
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Custom Tab Button

struct CustomTabButton: View {
    let tab: AIBrainTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .semibold))

                if isSelected {
                    Text(tab.title)
                        .font(.system(size: 14, weight: .semibold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(isSelected ? .white : .secondary)
            .padding(.horizontal, isSelected ? 20 : 14)
            .padding(.vertical, 10)
            .frame(maxWidth: isSelected ? .infinity : nil)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 3)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    AIBrainView()
        .modelContainer(for: [UserKnowledge.self, EntityKnowledge.self, ChatConversation.self])
}
