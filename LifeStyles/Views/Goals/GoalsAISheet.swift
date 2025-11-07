//
//  GoalsAISheet.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from GoalsView.swift - AI Insight Sheet
//

import SwiftUI
import FoundationModels

// MARK: - AI Insight Sheet

@available(iOS 26.0, *)
struct GoalAIInsightSheet: View {
    let goal: Goal
    @Bindable var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoadingAI[goal.id] == true {
                        AILoadingView(message: "AI analiz ediyor...")
                            .padding()
                    } else if let insight = viewModel.goalInsights[goal.id] {
                        VStack(spacing: 16) {
                            // Summary
                            AIInsightCard(
                                title: "Özet",
                                icon: "doc.text.fill",
                                accentColor: .blue,
                                isExpanded: .constant(true)
                            ) {
                                Text(insight.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            // Strategy
                            AIInsightCard(
                                title: "Strateji",
                                icon: "lightbulb.fill",
                                accentColor: .orange,
                                isExpanded: .constant(true)
                            ) {
                                AIMarkdownView(content: insight.strategy)
                            }

                            // Motivation
                            AIInsightCard(
                                title: "Motivasyon",
                                icon: "heart.fill",
                                accentColor: .pink,
                                isExpanded: .constant(true)
                            ) {
                                Text(insight.motivation)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            // Next Steps
                            AIInsightCard(
                                title: "Sonraki Adımlar",
                                icon: "list.bullet.circle.fill",
                                accentColor: .green,
                                isExpanded: .constant(true)
                            ) {
                                AIMarkdownView(content: insight.nextSteps)
                            }

                            // Urgency Badge
                            HStack {
                                Spacer()
                                urgencyBadge(for: insight.urgency)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(goal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.close", comment: "Close button")) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func urgencyBadge(for urgency: String) -> some View {
        let color: Color
        let icon: String
        let text: String

        switch urgency.lowercased() {
        case "overdue":
            color = .red
            icon = "exclamationmark.triangle.fill"
            text = "Gecikmiş"
        case "high":
            color = .orange
            icon = "clock.fill"
            text = "Yüksek Öncelik"
        case "medium":
            color = .yellow
            icon = "calendar"
            text = "Orta Öncelik"
        default:
            color = .blue
            icon = "info.circle"
            text = "Düşük Öncelik"
        }

        return HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct HabitRow: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: AppConstants.Spacing.medium) {
            // Checkbox button
            Button {
                HapticFeedback.medium()
                onToggle()
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            habit.isCompletedToday() ?
                            LinearGradient(colors: [Color.success, Color.success.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 3
                        )
                        .frame(width: 32, height: 32)

                    if habit.isCompletedToday() {
                        Image(systemName: "checkmark")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.success)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: AppConstants.Spacing.small) {
                    // Streak badge
                    if habit.currentStreak > 0 {
                        StreakBadgeView(days: habit.currentStreak, size: .small)
                    }

                    // Tamamlanma oranı göstergesi (opsiyonel)
                    HStack(spacing: 2) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption2)
                        Text(String(localized: "goals.this.week", comment: "This Week"))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Spacer()

            // Status indicator
            if habit.isCompletedToday() {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(Color.success)

                    Text(String(localized: "common.completed", comment: "Completed"))
                        .font(.caption2)
                        .foregroundStyle(Color.success)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

