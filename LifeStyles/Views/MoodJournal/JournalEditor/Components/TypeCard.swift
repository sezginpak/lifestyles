//
//  TypeCard.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Journal type selection card component
//

import SwiftUI

struct TypeCard: View {
    let type: JournalType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [type.color.opacity(0.9), type.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: type.icon)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(type.emoji)
                        Text(type.displayName)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    Text(type.aiPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(type.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(Spacing.large)
            .glassmorphismCard(
                cornerRadius: CornerRadius.medium
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Spacing.medium) {
        TypeCard(type: .general, isSelected: true, onSelect: {})
        TypeCard(type: .gratitude, isSelected: false, onSelect: {})
    }
    .padding()
}
