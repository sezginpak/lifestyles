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
    let onTap: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    let onEdit: () -> Void

    @State private var showEditAlert = false
    @State private var editedTitle = ""

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Header: Title + Badges
                HStack(spacing: Spacing.small) {
                    // Pinned indicator
                    if conversation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    // Title
                    Text(conversation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    // Favorite star
                    if conversation.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                // Preview text
                Text(conversation.lastMessagePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Footer: Badges + Time
                HStack(spacing: Spacing.small) {
                    // Friend badge (if applicable)
                    if !conversation.isGeneralMode, let friendName = conversation.friendName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                            Text(friendName)
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.cardCommunication.gradient)
                        .clipShape(Capsule())
                    } else {
                        // General mode badge
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.caption2)
                            Text(String(localized: "ai.general", comment: "General"))
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }

                    // Message count
                    HStack(spacing: 2) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.caption2)
                        Text("\(conversation.messageCount)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)

                    Spacer()

                    // Time
                    Text(conversation.relativeTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(Spacing.medium)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.normal)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                Label("Başlığı Düzenle", systemImage: "pencil")
            }

            Divider()

            // Delete
            Button(role: .destructive) {
                HapticFeedback.warning()
                onDelete()
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .alert("Başlığı Düzenle", isPresented: $showEditAlert) {
            TextField("Başlık", text: $editedTitle)
            Button("İptal", role: .cancel) {}
            Button("Kaydet") {
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

    return ScrollView {
        VStack(spacing: 12) {
            ConversationCard(
                conversation: conversation,
                onTap: { print("Tapped") },
                onDelete: { print("Delete") },
                onToggleFavorite: { print("Toggle fav") },
                onEdit: { print("Edit") }
            )
        }
        .padding()
    }
}
