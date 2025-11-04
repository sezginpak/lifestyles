//
//  SmartSuggestionCard.swift
//  LifeStyles
//
//  Modern Akıllı Öneri Kartı
//  Created by Claude on 31.10.2025.
//

import SwiftUI

struct SmartSuggestionCard: View {
    let suggestion: GoalSuggestion
    var progress: Double? = nil // 0.0-1.0, kabul edildiyse
    let onAccept: () -> Void
    let onDismiss: () -> Void
    let onTap: () -> Void

    @State private var animateGradient = false
    @State private var animateBorder = false

    var body: some View {
        ZStack {
            // Gradient background (kategori bazlı)
            LinearGradient(
                colors: categoryGradientColors.map { $0.opacity(0.2) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 25)

            // Glassmorphism overlay
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)

            // Main content
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 14) {
                    // Category icon with progress ring
                    ZStack {
                        // Progress ring (eğer kabul edildiyse)
                        if let progress = progress {
                            Circle()
                                .stroke(progressColor.opacity(0.3), lineWidth: 3)
                                .frame(width: 64, height: 64)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    LinearGradient(
                                        colors: [progressColor, progressColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 64, height: 64)
                                .rotationEffect(.degrees(-90))
                        }

                        // Icon circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: categoryGradientColors.map { $0.opacity(0.25) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)

                        Text(suggestion.category.emoji)
                            .font(.system(size: 30))
                    }

                    // Title & subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.title)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        if let progress = progress {
                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.caption2)
                                Text("Devam Ediyor")
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(progressColor)
                        } else {
                            Text(suggestion.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                // Description
                Text(suggestion.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .lineSpacing(2)

                // Metrics badges
                HStack(spacing: 8) {
                    // Zorluk
                    MetricBadge(
                        icon: difficultyEmoji,
                        text: suggestion.estimatedDifficulty.displayName,
                        color: difficultyColor
                    )

                    // Relevance
                    MetricBadge(
                        icon: "star.fill",
                        text: "\(Int(suggestion.relevanceScore * 100))%",
                        color: categoryColor
                    )

                    // Deadline
                    if let daysUntil = daysUntilTarget {
                        MetricBadge(
                            icon: "calendar",
                            text: "\(daysUntil)g",
                            color: .blue
                        )
                    }

                    Spacer()
                }

                // Action buttons
                HStack(spacing: 12) {
                    // Kabul Et
                    Button {
                        HapticFeedback.success()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            onAccept()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Kabul Et")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // İlgilenmiyorum
                    Button {
                        HapticFeedback.warning()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(18)
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            categoryGradientColors[0].opacity(animateBorder ? 0.6 : 0.3),
                            categoryGradientColors[1].opacity(animateBorder ? 0.3 : 0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: categoryColor.opacity(0.25), radius: 20, y: 10)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.light()
            onTap()
        }
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Detayları Gör", systemImage: "doc.text")
            }

            Button {
                onAccept()
            } label: {
                Label("Hedef Olarak Ekle", systemImage: "checkmark.circle")
            }

            Button {
                // TODO: Remind later functionality
            } label: {
                Label("Hatırlat", systemImage: "clock")
            }

            Divider()

            Button(role: .destructive) {
                onDismiss()
            } label: {
                Label("İlgilenmiyorum", systemImage: "xmark")
            }
        }
        .onAppear {
            // Border animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                animateBorder = true
            }
        }
    }

    // MARK: - Computed Properties

    private var categoryColor: Color {
        suggestion.category.color
    }

    private var categoryGradientColors: [Color] {
        switch suggestion.category {
        case .health:
            return [Color(hex: "FF6B6B"), Color(hex: "FF8E8E")]
        case .social:
            return [Color(hex: "4ECDC4"), Color(hex: "7FE8E0")]
        case .career:
            return [Color(hex: "9B59B6"), Color(hex: "B883D4")]
        case .personal:
            return [Color(hex: "2ECC71"), Color(hex: "58D68D")]
        case .fitness:
            return [Color(hex: "FF9F43"), Color(hex: "FFA366")]
        case .other:
            return [Color(hex: "95A5A6"), Color(hex: "B2BABB")]
        }
    }

    private var difficultyEmoji: String {
        switch suggestion.estimatedDifficulty {
        case .easy: return "🟢"
        case .medium: return "🟡"
        case .hard: return "🔴"
        }
    }

    private var difficultyColor: Color {
        switch suggestion.estimatedDifficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .red
        }
    }

    private var daysUntilTarget: Int? {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: suggestion.suggestedTargetDate).day
        return days
    }

    private var progressColor: Color {
        guard let progress = progress else { return .gray }

        if progress < 0.3 {
            return .red
        } else if progress < 0.7 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Metric Badge

struct MetricBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            if icon.count == 1 {
                // Emoji
                Text(icon)
                    .font(.caption2)
            } else {
                // SF Symbol
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SmartSuggestionCard(
            suggestion: GoalSuggestion(
                title: "Bu hafta 3 arkadaşla iletişime geç",
                description: "Sosyal bağlarını güçlendir ve arkadaşlarınla düzenli iletişim kur",
                category: .social,
                source: .contact,
                suggestedTargetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                estimatedDifficulty: .easy,
                relevanceScore: 0.85
            ),
            onAccept: {},
            onDismiss: {},
            onTap: {}
        )
        .padding()

        SmartSuggestionCard(
            suggestion: GoalSuggestion(
                title: "Yeni bir alışkanlık edinin",
                description: "Sabah meditasyonu veya akşam okuma alışkanlığı kazanın",
                category: .personal,
                source: .habit,
                suggestedTargetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
                estimatedDifficulty: .medium,
                relevanceScore: 0.75
            ),
            progress: 0.45,
            onAccept: {},
            onDismiss: {},
            onTap: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
