//
//  GoalDetailSheet.swift
//  LifeStyles
//
//  Created by Claude on 5.11.2025.
//  Goal detay ve progress güncelleme sheet'i
//

import SwiftUI
import SwiftData

struct GoalDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let goal: Goal
    let onUpdate: () -> Void

    @State private var manualProgress: Double
    @State private var showingDeleteAlert = false
    @State private var showingCompleteAlert = false

    init(goal: Goal, onUpdate: @escaping () -> Void) {
        self.goal = goal
        self.onUpdate = onUpdate
        _manualProgress = State(initialValue: goal.progress)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard

                    // Progress Section
                    progressSection

                    // Milestones Section
                    if let milestones = goal.milestones, !milestones.isEmpty {
                        milestonesSection(milestones: milestones)
                    }

                    // Info Section
                    infoSection

                    // Actions
                    actionButtons
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "goal.details", comment: "Goal Details"))
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
            .alert("Hedefi Tamamla", isPresented: $showingCompleteAlert) {
                Button(String(localized: "button.cancel", comment: "Cancel button"), role: .cancel) { }
                Button(String(localized: "button.complete", comment: "Complete")) {
                    completeGoal()
                }
            } message: {
                Text(String(localized: "goal.complete.confirm", comment: ""))
            }
            .alert("Hedefi Sil", isPresented: $showingDeleteAlert) {
                Button(String(localized: "button.cancel", comment: "Cancel button"), role: .cancel) { }
                Button(String(localized: "button.delete", comment: "Delete button"), role: .destructive) {
                    deleteGoal()
                }
            } message: {
                Text(String(localized: "goal.delete.confirm", comment: ""))
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Emoji & Category
            ZStack {
                Circle()
                    .fill(Color(hex: goal.category.ringColor).opacity(0.2))
                    .frame(width: 80, height: 80)

                Text(goal.emoji ?? goal.category.emoji)
                    .font(.system(size: 40))
            }

            // Title
            Text(goal.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Description
            if !goal.goalDescription.isEmpty {
                Text(goal.goalDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Badges
            HStack(spacing: 12) {
                // Category
                GoalBadge(
                    icon: goal.category.emoji,
                    text: goal.category.displayName,
                    color: Color(hex: goal.category.ringColor)
                )

                // Priority
                GoalBadge(
                    icon: goal.priority.emoji,
                    text: goal.priority.displayName,
                    color: priorityColor
                )

                // Status
                GoalBadge(
                    icon: goal.isOverdue ? "⚠️" : "📅",
                    text: "\(abs(goal.daysRemaining)) gün",
                    color: goal.isOverdue ? .red : .blue
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "goal.progress", comment: ""))
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 20) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(
                            Color(hex: goal.category.ringColor).opacity(0.2),
                            lineWidth: 12
                        )
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: goal.currentProgress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: goal.category.ringColor),
                                    Color(hex: goal.category.ringColor).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goal.currentProgress)

                    VStack(spacing: 4) {
                        Text(String(localized: "progress.percentage", defaultValue: "\(Int(goal.currentProgress * 100))%", comment: "Progress percentage"))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: goal.category.ringColor))

                        Text(String(localized: "goal.completed", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Progress Mode Toggle
                if let milestones = goal.milestones, !milestones.isEmpty {
                    VStack(spacing: 8) {
                        Toggle(isOn: Binding(
                            get: { goal.useManualProgress },
                            set: { newValue in
                                goal.useManualProgress = newValue
                                try? modelContext.save()
                                onUpdate()
                            }
                        )) {
                            HStack {
                                Image(systemName: goal.useManualProgress ? "slider.horizontal.3" : "checkmark.circle")
                                    .foregroundStyle(Color(hex: goal.category.ringColor))
                                Text(goal.useManualProgress ? "Manuel İlerleme" : "Adım Bazlı İlerleme")
                                    .font(.subheadline)
                            }
                        }
                        .tint(Color(hex: goal.category.ringColor))

                        Text(goal.useManualProgress ?
                            "Slider ile manuel olarak ilerleme güncelleyebilirsin" :
                            "İlerleme adımlardan otomatik hesaplanıyor")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                // Manual Progress Slider
                if goal.useManualProgress || (goal.milestones?.isEmpty ?? true) {
                    VStack(spacing: 12) {
                        HStack {
                            Text(String(localized: "progress.with.label", defaultValue: "Progress: \(Int(manualProgress * 100))%", comment: "Progress with label"))
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            if manualProgress != goal.progress {
                                Button(String(localized: "button.save", comment: "Save button")) {
                                    updateProgress()
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(hex: goal.category.ringColor))
                            }
                        }

                        Slider(value: $manualProgress, in: 0...1, step: 0.05)
                            .tint(Color(hex: goal.category.ringColor))
                            .onChange(of: manualProgress) { _, newValue in
                                HapticFeedback.light()
                            }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Milestones Section

    private func milestonesSection(milestones: [GoalMilestone]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "goal.steps", comment: ""))
                    .font(.headline)

                Spacer()

                Text(String(localized: "progress.fraction", defaultValue: "\(goal.completedMilestonesCount)/\(goal.totalMilestonesCount)", comment: "Progress fraction"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(milestones.sorted(by: { $0.order < $1.order })) { milestone in
                    GoalMilestoneRow(
                        milestone: milestone,
                        color: Color(hex: goal.category.ringColor),
                        onToggle: {
                            toggleMilestone(milestone)
                        }
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 12) {
            InfoRow(
                icon: "calendar",
                label: "Başlangıç",
                value: formatDate(goal.createdAt)
            )

            Divider()

            InfoRow(
                icon: "flag.checkered",
                label: "Hedef Tarih",
                value: formatDate(goal.targetDate),
                valueColor: goal.isOverdue ? .red : .primary
            )

            if let completedAt = goal.completedAt {
                Divider()

                InfoRow(
                    icon: "checkmark.seal.fill",
                    label: "Tamamlandı",
                    value: formatDate(completedAt),
                    valueColor: .green
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !goal.isCompleted {
                // Complete Button
                Button {
                    showingCompleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(String(localized: "goal.complete.button", comment: ""))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: goal.category.ringColor))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // Delete Button
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text(String(localized: "goal.delete.button", comment: ""))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Actions

    private func updateProgress() {
        goal.progress = manualProgress

        // Progress %100 ise otomatik complete
        if manualProgress >= 1.0 && !goal.isCompleted {
            completeGoal()
        } else {
            try? modelContext.save()
            HapticFeedback.success()
            onUpdate()
        }
    }

    private func toggleMilestone(_ milestone: GoalMilestone) {
        goal.toggleMilestone(milestone)
        try? modelContext.save()
        HapticFeedback.medium()
        onUpdate()

        // Progress güncellendi, UI'da reflection için manualProgress'i sync et
        manualProgress = goal.currentProgress
    }

    private func completeGoal() {
        goal.isCompleted = true
        goal.completedAt = Date()
        goal.progress = 1.0

        try? modelContext.save()
        HapticFeedback.success()
        onUpdate()

        dismiss()
    }

    private func deleteGoal() {
        modelContext.delete(goal)
        try? modelContext.save()
        HapticFeedback.success()
        onUpdate()

        dismiss()
    }

    // MARK: - Helpers

    private var priorityColor: Color {
        switch goal.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct GoalMilestoneRow: View {
    let milestone: GoalMilestone
    let color: Color
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(milestone.isCompleted ? color : Color.secondary.opacity(0.3))
                    .animation(.spring(response: 0.3), value: milestone.isCompleted)

                // Title
                Text(milestone.title)
                    .font(.body)
                    .foregroundStyle(milestone.isCompleted ? .secondary : .primary)
                    .strikethrough(milestone.isCompleted)

                Spacer()

                // Completed Date
                if milestone.isCompleted, let completedAt = milestone.completedAt {
                    Text(formatShortDate(completedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(milestone.isCompleted ? color.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
        .font(.subheadline)
    }
}

struct GoalBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    let goal = Goal(
        title: "Haftada 3 kez spor yap",
        goalDescription: "Sağlıklı yaşam için düzenli egzersiz yapmak çok önemli",
        category: .health,
        priority: .high,
        targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
        progress: 0.4,
        emoji: "🏃"
    )

    let m1 = GoalMilestone(title: "Salona kayıt ol", isCompleted: true, order: 0)
    let m2 = GoalMilestone(title: "İlk antrenman", isCompleted: true, order: 1)
    let m3 = GoalMilestone(title: "3. gün tamamla", order: 2)

    m1.goal = goal
    m2.goal = goal
    m3.goal = goal

    goal.milestones = [m1, m2, m3]

    return GoalDetailSheet(goal: goal) {
        print("Updated")
    }
}
