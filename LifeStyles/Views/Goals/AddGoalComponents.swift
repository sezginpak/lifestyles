//
//  AddGoalComponents.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from AddGoalView.swift - Supporting UI components
//

import SwiftUI

import SwiftData
// MARK: - Supporting Views

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step == currentStep {
                    Capsule()
                        .fill(Color.cardGoals)
                        .frame(width: 32, height: 6)
                } else {
                    Capsule()
                        .fill(step < currentStep ? Color.cardGoals.opacity(0.5) : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 6)
                }
            }
        }
        .animation(.spring(response: 0.3), value: currentStep)
    }
}

struct GoalTemplateRow: View {
    let template: GoalTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppConstants.Spacing.medium) {
                Text(template.emoji)
                    .font(.title)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.cardGoals.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.headline)
                    Text(String(format: NSLocalizedString("goal.days.format", comment: "X days"), template.suggestedDays))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(Color.adaptiveSecondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GoalPreviewCard: View {
    let draft: GoalDraft

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: draft.targetDate).day ?? 0
    }

    var body: some View {
        VStack(spacing: AppConstants.Spacing.medium) {
            HStack {
                Text(draft.emoji)
                    .font(.system(size: 48))

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(localized: "goal.days.remaining", defaultValue: "\(daysRemaining)", comment: "Days remaining"))
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.cardGoals)
                    Text(String(localized: "goal.days.remaining", comment: "days remaining"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(draft.title)
                    .font(.title3.weight(.semibold))

                if !draft.description.isEmpty {
                    Text(draft.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                HStack {
                    Label(categoryName(draft.category), systemImage: "tag")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(draft.targetDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cardGoals.opacity(0.2),
                            Color.cardGoals.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .stroke(Color.cardGoals.opacity(0.3), lineWidth: 1)
        )
    }

    private func categoryName(_ category: GoalCategory) -> String {
        switch category {
        case .health: return "Sağlık"
        case .fitness: return "Fitness"
        case .career: return "Kariyer"
        case .social: return "Sosyal"
        case .personal: return "Kişisel"
        case .other: return "Diğer"
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var viewModel = GoalsViewModel()

    AddGoalView(
        viewModel: viewModel,
        modelContext: ModelContext(
            try! ModelContainer(for: Goal.self, Habit.self)
        )
    )
}
