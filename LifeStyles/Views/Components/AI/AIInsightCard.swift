//
//  AIInsightCard.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI

/// AI öneri kartı - Glassmorphism tasarım, expand/collapse animasyonlu
struct AIInsightCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    var isLoading: Bool = false
    var isExpanded: Binding<Bool>?
    @ViewBuilder let content: Content

    @State private var animateGradient = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: toggleExpand) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 40, height: 40)

                        if isLoading {
                            ProgressView()
                                .tint(accentColor)
                        } else {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
                    }

                    // Title
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    // Expand indicator
                    if isExpanded != nil {
                        Image(systemName: isExpanded?.wrappedValue == true ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded?.wrappedValue == true ? 180 : 0))
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Content
            if isExpanded?.wrappedValue ?? true {
                content
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(animateGradient ? 0.15 : 0.08),
                            accentColor.opacity(animateGradient ? 0.08 : 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }

    private func toggleExpand() {
        if let binding = isExpanded {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                binding.wrappedValue.toggle()
            }
        }
    }
}

/// Kompakt AI insight kartı (collapse olmayan)
struct CompactAIInsightCard: View {
    let title: String
    let message: String
    let icon: String
    let accentColor: Color
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action button
            if action != nil {
                Button(action: { action?() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 28, height: 28)
                        .background(accentColor.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Priority action kartı
struct PriorityActionCard: View {
    let action: PriorityAction
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Priority indicator
                ZStack {
                    Circle()
                        .fill(priorityColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: priorityIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(priorityColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(action.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(action.priority.displayName)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor.opacity(0.15))
                            .foregroundStyle(priorityColor)
                            .clipShape(Capsule())
                    }

                    Text(action.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(priorityColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var priorityColor: Color {
        switch action.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    private var priorityIcon: String {
        switch action.priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "clock.fill"
        case .low: return "info.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview("AI Insight Card") {
    VStack(spacing: 20) {
        AIInsightCard(
            title: "Günlük Özet",
            icon: "sparkles",
            accentColor: .purple,
            isExpanded: .constant(true)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "ai.insight.preview.text", comment: "Today is a great day! You made progress on 3 goals and completed 2 habits."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "ai.insight.suggestions", comment: "Suggestions:"))
                        .font(.caption.weight(.semibold))

                    Text(String(localized: "ai.insight.preview.suggestion.1", comment: "• Contact a friend"))
                        .font(.caption)
                    Text(String(localized: "ai.insight.preview.suggestion.2", comment: "• Complete evening yoga routine"))
                        .font(.caption)
                }
            }
        }

        CompactAIInsightCard(
            title: "Hedef Önerisi",
            message: "Bu ay için yeni bir fitness hedefi belirlemeye ne dersin?",
            icon: "target",
            accentColor: .blue,
            action: {}
        )

        PriorityActionCard(
            action: PriorityAction(
                title: "Gecikmiş hedef: Kitap okuma",
                description: "5 gün gecikmiş",
                priority: .high,
                type: .goal,
                relatedId: UUID()
            )
        )
    }
    .padding()
}
