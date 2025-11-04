//
//  FriendDetailButtons.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from FriendDetailView.swift - Action buttons and badges
//

import SwiftUI

import SwiftData
// MARK: - Stats Badge (Modern Header Component)

struct StatsBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            // Icon with subtle background
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            // Value and label
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground).opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Quick Action Compact Button (Modern Header Component)

struct QuickActionCompactButton: View {
    let icon: String
    let label: String
    let colors: [Color]
    let action: () -> Void

    // Opsiyonel: Context menu için
    var contextMenuItems: (() -> AnyView)? = nil

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(AppConstants.Animation.spring) {
                isPressed = true
            }
            HapticFeedback.medium()
            action()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Glassmorphism effect
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: colors.first?.opacity(isPressed ? 0.2 : 0.3) ?? .clear,
                radius: isPressed ? 6 : 10,
                x: 0,
                y: isPressed ? 3 : 6
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let contextMenuItems = contextMenuItems {
                contextMenuItems()
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Friend.self, configurations: config)
    let friend = Friend(name: "Test Arkadaş", phoneNumber: "555-1234", frequency: .weekly, isImportant: true)
    container.mainContext.insert(friend)

    return NavigationStack {
        FriendDetailView(friend: friend)
            .modelContainer(container)
    }
}
