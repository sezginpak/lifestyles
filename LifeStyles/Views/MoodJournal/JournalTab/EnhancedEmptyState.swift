//
//  EnhancedEmptyState.swift
//  LifeStyles
//
//  Enhanced empty state with illustration
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct EnhancedEmptyState: View {
    let title: String
    let message: String
    let icon: String
    let actionLabel: String?
    let action: (() -> Void)?

    @State private var isAnimating = false

    init(
        title: String,
        message: String,
        icon: String = "book.closed.fill",
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated icon
            ZStack {
                // Outer glow circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.brandPrimary.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .opacity(isAnimating ? 0.6 : 0.3)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary.opacity(0.15),
                                Color.purple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brandPrimary, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(isAnimating ? -5 : 5))
            }

            // Text content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
            }

            // Action button
            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))

                        Text(actionLabel)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.brandPrimary, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.brandPrimary.opacity(0.3), radius: 12, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        EnhancedEmptyState(
            title: "Henüz journal yok",
            message: "İlk journal'ını yazmaya başla ve düşüncelerini kaydet",
            icon: "book.closed.fill",
            actionLabel: "Yeni Journal",
            action: {}
        )
    }
    .background(Color(.systemGroupedBackground))
}
