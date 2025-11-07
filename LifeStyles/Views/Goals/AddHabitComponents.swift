//
//  AddHabitComponents.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from AddHabitView.swift - Supporting UI components
//

import SwiftUI
import SwiftData
import SwiftData

// MARK: - Supporting Views
struct HabitProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step == currentStep {
                    Capsule()
                        .fill(Color.accentSecondary)
                        .frame(width: 32, height: 6)
                } else {
                    Capsule()
                        .fill(step < currentStep ? Color.accentSecondary.opacity(0.5) : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 6)
                }
            }
        }
        .animation(.spring(response: 0.3), value: currentStep)
    }
}

struct HabitTemplateRow: View {
    let template: HabitTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppConstants.Spacing.medium) {
                Text(template.emoji).font(.title).frame(width: 44, height: 44).background(Circle().fill(Color.accentSecondary.opacity(0.1)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name).font(.headline)
                    Text(frequencyLabel).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card).fill(Color.adaptiveSecondaryBackground))
        }
        .buttonStyle(.plain)
    }

    private var frequencyLabel: String {
        switch template.frequency {
        case .daily: return "Günlük"
        case .weekly: return "Haftalık"
        case .monthly: return "Aylık"
        }
    }
}

struct HabitPreviewCard: View {
    let draft: HabitDraft

    var body: some View {
        VStack(spacing: AppConstants.Spacing.medium) {
            HStack {
                Text(draft.emoji).font(.system(size: 48))
                Spacer()
                VStack(alignment: .trailing) {
                    Text(String(localized: "habit.target.count", defaultValue: "\(draft.targetCount)", comment: "Target count")).font(.title.weight(.bold)).foregroundStyle(Color.accentSecondary)
                    Text(frequencyLabel).font(.caption).foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(draft.name).font(.title3.weight(.semibold))
                if !draft.description.isEmpty {
                    Text(draft.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card).fill(LinearGradient(colors: [Color.accentSecondary.opacity(0.2), Color.accentSecondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card).stroke(Color.accentSecondary.opacity(0.3), lineWidth: 1))
    }

    private var frequencyLabel: String {
        switch draft.frequency {
        case .daily: return "kez/gün"
        case .weekly: return "kez/hafta"
        case .monthly: return "kez/ay"
        }
    }
}

#Preview {
    @Previewable @State var viewModel = GoalsViewModel()
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)
    AddHabitView(viewModel: viewModel, modelContext: container.mainContext)
}
