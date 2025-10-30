//
//  JournalTypeCard.swift
//  LifeStyles
//
//  Modern gradient journal type selector
//  Glassmorphism, haptic feedback, animations
//

import SwiftUI

// MARK: - Journal Type Card

struct JournalTypeCard: View {
    let journalType: JournalType
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
            HapticFeedback.medium()
        }) {
            HStack(spacing: 16) {
                // Icon Circle with Gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    journalType.color.opacity(0.9),
                                    journalType.color.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: isSelected ? journalType.color.opacity(0.4) : .clear,
                            radius: 12,
                            y: 4
                        )

                    Image(systemName: journalType.icon)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(journalType.emoji)
                            .font(.title3)

                        Text(journalType.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }

                    Text(journalType.aiPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(journalType.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                ZStack {
                    // Glassmorphism background
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Gradient border
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: isSelected ? [
                                    journalType.color.opacity(0.6),
                                    journalType.color.opacity(0.3)
                                ] : [
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected ? 2 : 1
                        )
                }
            )
            .shadow(
                color: isSelected ? journalType.color.opacity(0.2) : .black.opacity(0.05),
                radius: isSelected ? 16 : 8,
                y: isSelected ? 6 : 2
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: 50) {
            // Trigger on release
        } onPressingChanged: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - Journal Type Selector Grid

struct JournalTypeSelectorGrid: View {
    @Binding var selectedType: JournalType

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "journal.type", comment: "Journal Type"))
                .font(.title3)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(JournalType.allCases, id: \.self) { type in
                    JournalTypeCard(
                        journalType: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Compact Journal Type Pill

struct JournalTypePill: View {
    let journalType: JournalType
    let showIcon: Bool

    init(
        journalType: JournalType,
        showIcon: Bool = true
    ) {
        self.journalType = journalType
        self.showIcon = showIcon
    }

    var body: some View {
        HStack(spacing: 6) {
            if showIcon {
                Image(systemName: journalType.icon)
                    .font(.caption)
            }

            Text(journalType.emoji)
                .font(.caption)

            Text(journalType.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(journalType.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(journalType.color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .strokeBorder(journalType.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Journal Type Cards") {
    @Previewable @State var selectedType: JournalType = .general

    ScrollView {
        VStack(spacing: 20) {
            JournalTypeSelectorGrid(selectedType: $selectedType)

            Divider()

            // Compact pills
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "compact.pills", comment: "Compact Pills"))
                    .font(.headline)

                HStack {
                    ForEach(JournalType.allCases, id: \.self) { type in
                        JournalTypePill(journalType: type)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview("Single Type Card") {
    JournalTypeCard(
        journalType: .gratitude,
        isSelected: true
    ) {
        print("Selected gratitude")
    }
    .padding()
}
