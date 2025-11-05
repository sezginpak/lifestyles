//
//  ModernChatBubble.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct ModernChatBubble: View {
    let message: ChatMessage
    var isStreaming: Bool = false

    @State private var showActions = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            } else {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Message Content
                HStack(alignment: .bottom, spacing: 4) {
                    if message.isUser {
                        Text(message.content)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 18,
                                    bottomLeadingRadius: 18,
                                    bottomTrailingRadius: 4,
                                    topTrailingRadius: 18
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        HStack(alignment: .top, spacing: 0) {
                            Text(message.content)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 18,
                                        bottomLeadingRadius: 4,
                                        bottomTrailingRadius: 18,
                                        topTrailingRadius: 18
                                    )
                                )
                                .overlay(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 18,
                                        bottomLeadingRadius: 4,
                                        bottomTrailingRadius: 18,
                                        topTrailingRadius: 18
                                    )
                                    .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
                                )

                            if isStreaming {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.content
                        HapticFeedback.success()
                    } label: {
                        Label(String(localized: "common.copy", comment: "Copy"), systemImage: "doc.on.doc")
                    }
                }

                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        ModernChatBubble(message: ChatMessage(content: "Merhaba! Bana yardım edebilir misin?", isUser: true))
        ModernChatBubble(message: ChatMessage(content: "Elbette! Size nasıl yardımcı olabilirim?", isUser: false))
    }
    .padding()
}
