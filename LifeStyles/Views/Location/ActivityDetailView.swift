//
//  ActivityDetailView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Aktivite detay sayfası
//

import SwiftUI
import SwiftData

struct ActivityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let activity: ActivitySuggestion
    let onComplete: () -> Void
    let onToggleFavorite: () -> Void

    @State private var showingCompletionAlert = false

    @Query private var completions: [ActivityCompletion]

    private var relatedCompletions: [ActivityCompletion] {
        completions.filter { $0.activityTitle == activity.title }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Section
                    heroSection

                    // Action Buttons
                    actionButtons

                    // Activity Info
                    activityInfo

                    // Tips Section
                    tipsSection

                    // Completion History
                    if !relatedCompletions.isEmpty {
                        completionHistory
                    }

                    // Scientific Reason
                    if let reason = activity.scientificReason {
                        scientificReasonSection(reason)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "activity.detail.title", comment: "Activity detail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onToggleFavorite()
                    } label: {
                        Image(systemName: activity.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(activity.isFavorite ? .yellow : .secondary)
                    }
                }
            }
            .alert(String(localized: "activity.completed.alert.title", comment: "Activity completed!"), isPresented: $showingCompletionAlert) {
                Button(String(localized: "activity.completed.alert.button", comment: "Great!"), role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(String(format: NSLocalizedString("activity.completed.alert.message", comment: "Congratulations! You earned X points!"), activity.calculatedPoints))
            }
        }
        .onAppear {
            // Mark as viewed
            activity.markAsViewed()
            try? modelContext.save()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: activity.isCompleted ?
                                [Color.green, Color.mint] :
                                [Color.brandPrimary, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .glowEffect(color: activity.isCompleted ? .green : .brandPrimary, radius: 20)

                Text(activity.type.emoji)
                    .font(.system(size: 50))
            }

            // Title
            Text(activity.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Category & Time
            HStack(spacing: 16) {
                Label(activity.type.displayName, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !activity.timeOfDayDisplay.isEmpty {
                    Label(activity.timeOfDayDisplay, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Description
            Text(activity.activityDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Complete Button
            Button {
                HapticFeedback.success()
                onComplete()
                showingCompletionAlert = true
            } label: {
                HStack {
                    Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    Text(activity.isCompleted ? String(localized: "common.completed", comment: "Completed") : String(localized: "activity.complete.button", comment: "Complete activity"))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: activity.isCompleted ?
                            [Color.green, Color.mint] :
                            [Color.brandPrimary, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: (activity.isCompleted ? Color.green : Color.brandPrimary).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(activity.isCompleted)
        }
    }

    // MARK: - Activity Info

    private var activityInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "activity.info.title", comment: "Activity information"))
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 10) {
                ActivityInfoRow(icon: "star.fill", label: String(localized: "activity.info.difficulty"), value: activity.difficultyDisplayName, color: .orange)
                ActivityInfoRow(icon: "clock.fill", label: String(localized: "activity.info.duration"), value: activity.formattedDuration, color: .blue)
                ActivityInfoRow(icon: "star.circle.fill", label: String(localized: "activity.info.points"), value: String(format: NSLocalizedString("location.points", comment: "Points"), activity.calculatedPoints), color: .yellow)
                ActivityInfoRow(icon: "eye.fill", label: String(localized: "activity.info.views"), value: String(format: NSLocalizedString("location.times.count", comment: "Times count"), activity.viewCount), color: .purple)

                if let lastViewed = activity.lastViewedAt {
                    ActivityInfoRow(
                        icon: "clock.arrow.circlepath",
                        label: String(localized: "activity.info.last_viewed"),
                        value: formatRelativeDate(lastViewed),
                        color: .indigo
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(activityTipTitle)
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text(activityTipContent)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Completion History

    private var completionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.green)
                Text(String(localized: "activity.completion.history", comment: "Completion History"))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(String(format: NSLocalizedString("location.times.count", comment: "Times count"), relatedCompletions.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(relatedCompletions.prefix(5)) { completion in
                    HStack {
                        Text(completion.categoryEmoji)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.formattedDate)
                                .font(.caption)
                                .fontWeight(.medium)

                            if let notes = completion.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text("\(completion.pointsEarned)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(10)
                    .background(Color.green.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Scientific Reason Section

    private func scientificReasonSection(_ reason: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)
                Text(String(localized: "activity.why.important", comment: "Why Is It Important?"))
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text(reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Helper Properties

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var activityTipTitle: String {
        switch activity.type {
        case .outdoor: return String(localized: "tips.outdoor.title")
        case .exercise: return String(localized: "tips.exercise.title")
        case .social: return String(localized: "tips.social.title")
        case .learning: return String(localized: "tips.learning.title")
        case .creative: return String(localized: "tips.creative.title")
        case .relax: return String(localized: "tips.relax.title")
        }
    }

    private var activityTipContent: String {
        switch activity.type {
        case .outdoor: return String(localized: "tips.outdoor.content")
        case .exercise: return String(localized: "tips.exercise.content")
        case .social: return String(localized: "tips.social.content")
        case .learning: return String(localized: "tips.learning.content")
        case .creative: return String(localized: "tips.creative.content")
        case .relax: return String(localized: "tips.relax.content")
        }
    }
}

// MARK: - Info Row Component

struct ActivityInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}
