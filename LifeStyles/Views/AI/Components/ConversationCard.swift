//
//  ConversationCard.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Compact conversation card for chat history list
//

import SwiftUI
import SwiftData

struct ConversationCard: View {
    let conversation: ChatConversation
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    let onEdit: () -> Void

    @State private var showEditAlert = false
    @State private var editedTitle = ""

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Left: Avatar/Icon
            ZStack {
                Circle()
                    .fill(
                        conversation.isGeneralMode
                            ? LinearGradient(
                                colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.cardCommunication.opacity(0.8), Color.cardCommunication.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: conversation.isGeneralMode ? "brain.head.profile" : "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Middle: Content
            VStack(alignment: .leading, spacing: 6) {
                // Header: Title + Badges
                HStack(spacing: 6) {
                    // Pinned indicator
                    if conversation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }

                    // Title
                    Text(conversation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    // Favorite star
                    if conversation.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
                }

                // Preview text
                Text(conversation.lastMessagePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Footer: Badges + Stats
                HStack(spacing: 8) {
                    // Mode badge
                    if !conversation.isGeneralMode, let friendName = conversation.friendName {
                        Label(friendName, systemImage: "person.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.cardCommunication.gradient)
                            )
                    } else {
                        Label(String(localized: "conversation.general", comment: ""), systemImage: "sparkles")
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    // Message count badge
                    Label(String(localized: "analytics.message.count", defaultValue: "\(conversation.messageCount)", comment: "Message count"), systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.tertiarySystemBackground))
                        )
                }
            }

            Spacer()

            // Right: Time + Chevron
            VStack(alignment: .trailing, spacing: 4) {
                Text(conversation.relativeTime)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .frame(height: 50)
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(
                    conversation.isFavorite
                        ? Color.yellow.opacity(0.3)
                        : Color(.separator).opacity(0.2),
                    lineWidth: conversation.isFavorite ? 1.5 : 0.5
                )
        )
        .contextMenu {
            // Favorite toggle
            Button {
                HapticFeedback.light()
                onToggleFavorite()
            } label: {
                Label(
                    conversation.isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle",
                    systemImage: conversation.isFavorite ? "star.slash" : "star.fill"
                )
            }

            // Edit title
            Button {
                editedTitle = conversation.title
                showEditAlert = true
            } label: {
                Label(String(localized: "button.edit.title", comment: "Edit title"), systemImage: "pencil")
            }

            Divider()

            // Delete
            Button(role: .destructive) {
                HapticFeedback.warning()
                onDelete()
            } label: {
                Label(String(localized: "button.delete", comment: "Delete button"), systemImage: "trash")
            }
        }
        .alert("Başlığı Düzenle", isPresented: $showEditAlert) {
            TextField(String(localized: "placeholder.title", comment: "Title placeholder"), text: $editedTitle)
            Button(String(localized: "button.cancel", comment: "Cancel button"), role: .cancel) {}
            Button(String(localized: "button.save", comment: "Save button")) {
                if !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    conversation.updateTitle(editedTitle, isAIGenerated: false)
                    HapticFeedback.success()
                    onEdit()
                }
            }
        } message: {
            Text(String(localized: "chat.edit.title.placeholder", comment: "Edit chat title"))
        }
    }
}

// MARK: - Preview

#Preview {
    let conversation = ChatConversation(
        title: "Arkadaşlarla iletişim tavsiyeleri",
        friendId: nil,
        friendName: nil,
        isGeneralMode: true,
        isFavorite: true,
        isPinned: true
    )

    // Add some messages
    let msg1 = ChatMessage(content: "Hangi arkadaşlarımla konuşmalıyım?", isUser: true)
    let msg2 = ChatMessage(content: "İletişim kurmanız gereken 3 arkadaşınız var...", isUser: false)
    conversation.addMessage(msg1)
    conversation.addMessage(msg2)

    return NavigationStack {
        ScrollView {
            VStack(spacing: 12) {
                NavigationLink {
                    Text(String(localized: "chat.opened", comment: "Chat opened"))
                } label: {
                    ConversationCard(
                        conversation: conversation,
                        onDelete: { print("Delete") },
                        onToggleFavorite: { print("Toggle fav") },
                        onEdit: { print("Edit") }
                    )
                }
            }
            .padding()
        }
    }
}
