//
//  DailyInsightCard.swift
//  LifeStyles
//
//  Modern Daily Insight Card - Sabah/Öğle/Akşam dinamik
//  Created by Claude on 25.10.2025.
//

import SwiftUI

// MARK: - Daily Insight Card

struct DailyInsightCard: View {
    let insight: String
    let timeOfDay: TimeOfDay
    var isLoading: Bool = false
    var onRefresh: (() async -> Void)?
    var onExpand: (() -> Void)?

    @State private var animateGradient = false

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Compact icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: timeOfDay.gradientColors.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                if isLoading {
                    ProgressView()
                        .tint(timeOfDay.gradientColors.first!)
                } else {
                    Image(systemName: timeOfDay.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: timeOfDay.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(timeOfDay.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(String(localized: "insight.personal.recommendation", comment: "Your Personal Recommendation"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Refresh button
                    if let refresh = onRefresh {
                        Button {
                            HapticFeedback.light()
                            Task {
                                await refresh()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(timeOfDay.gradientColors.first!)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                    }
                }

                if isLoading {
                    // Compact loading skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.1))
                        .frame(height: 14)
                        .shimmering()
                } else {
                    Text(insight)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .lineSpacing(4)
                }

                // Expand button (if provided)
                if onExpand != nil {
                    Button {
                        HapticFeedback.light()
                        onExpand?()
                    } label: {
                        HStack(spacing: 4) {
                            Text(String(localized: "insight.view.detailed", comment: "View Details"))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(timeOfDay.gradientColors.first!)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(timeOfDay.gradientColors.first!)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            timeOfDay.gradientColors[0].opacity(animateGradient ? 0.3 : 0.15),
                            timeOfDay.gradientColors[1].opacity(animateGradient ? 0.15 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: timeOfDay.gradientColors.first!.opacity(0.1),
            radius: 8,
            y: 4
        )
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .onAppear {
            // Gradient animation
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Compact Daily Insight Card

/// Dashboard için kompakt versiyon
struct CompactDailyInsightCard: View {
    let insight: String
    let timeOfDay: TimeOfDay
    var isLoading: Bool = false
    var onTap: (() -> Void)?

    @State private var animateGradient = false

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap?()
        } label: {
            HStack(spacing: Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: timeOfDay.gradientColors.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    if isLoading {
                        ProgressView()
                            .tint(timeOfDay.gradientColors.first!)
                    } else {
                        Image(systemName: timeOfDay.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: timeOfDay.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeOfDay.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if isLoading {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.secondary.opacity(0.1))
                            .frame(height: 14)
                            .shimmering()
                    } else {
                        Text(insight)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                timeOfDay.gradientColors[0].opacity(animateGradient ? 0.3 : 0.15),
                                timeOfDay.gradientColors[1].opacity(animateGradient ? 0.15 : 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Full Insight Sheet

struct FullDailyInsightSheet: View {
    let insight: String
    let timeOfDay: TimeOfDay
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xlarge) {
                    // Hero section
                    VStack(spacing: Spacing.medium) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: timeOfDay.gradientColors.map { $0.opacity(0.2) },
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: timeOfDay.icon)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: timeOfDay.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text(timeOfDay.displayName)
                            .font(.title.bold())

                        Text(String(localized: "insight.personal.recommendation", comment: "Your Personal Recommendation"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xlarge)

                    // Insight content
                    Text(insight)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(8)
                        .padding(Spacing.large)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                                .fill(.ultraThinMaterial)
                        )

                    // Metadata
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(String(localized: "insight.generated.by.claude", comment: "Generated by Claude Haiku"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(Date(), style: .time)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, Spacing.medium)
                }
                .padding(Spacing.large)
            }
            .navigationTitle("Günlük Öneriniz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Shimmering Modifier

extension View {
    func shimmering() -> some View {
        modifier(ShimmeringModifier())
    }
}

struct ShimmeringModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
                    .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

// MARK: - Preview

#Preview("Daily Insight Card - Morning") {
    VStack(spacing: Spacing.large) {
        DailyInsightCard(
            insight: "Günaydın! Bugün 3 arkadaşınla iletişim kurman gerekiyor. Sabah meditasyonunu unutma ve hedeflerine adım adım ilerle. 🌟",
            timeOfDay: .morning,
            onRefresh: {},
            onExpand: {}
        )

        CompactDailyInsightCard(
            insight: "Bugün harika bir gün olacak! 3 hedefin var.",
            timeOfDay: .morning
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Daily Insight Card - Afternoon") {
    DailyInsightCard(
        insight: "Öğlene kadar 2 alışkanlık tamamladın, harikasın! Öğleden sonra için bir arkadaşınla buluşmayı unutma. ☀️",
        timeOfDay: .afternoon,
        onRefresh: {},
        onExpand: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Daily Insight Card - Evening") {
    DailyInsightCard(
        insight: "Bugün 4 hedefte ilerleme kaydetttin! Akşam günlüğünü yazmayı unutma ve yarın için uyku düzenini koru. 🌆",
        timeOfDay: .evening,
        onRefresh: {},
        onExpand: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Daily Insight Card - Loading") {
    DailyInsightCard(
        insight: "",
        timeOfDay: .morning,
        isLoading: true
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Full Insight Sheet") {
    FullDailyInsightSheet(
        insight: "Günaydın! Bugün 3 arkadaşınla iletişim kurman gerekiyor. Sabah meditasyonunu unutma ve hedeflerine adım adım ilerle. Mood'una göre bugün aktif bir gün olabilir! 🌟",
        timeOfDay: .morning
    )
}
