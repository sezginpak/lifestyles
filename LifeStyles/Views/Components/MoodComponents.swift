//
//  MoodComponents.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Mood & Journal için reusable components
//

import SwiftUI

// MARK: - Mood Emoji Picker

struct MoodEmojiPicker: View {
    @Binding var selectedMood: MoodType
    // DS: Updated grid spacing from 12 to Spacing.medium
    let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.medium), count: 5)

    var body: some View {
        // DS: Updated grid spacing from 12 to Spacing.medium
        LazyVGrid(columns: columns, spacing: Spacing.medium) {
            ForEach(MoodType.allCases, id: \.self) { mood in
                MoodEmojiButton(
                    mood: mood,
                    isSelected: selectedMood == mood
                ) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selectedMood = mood
                    }
                    HapticFeedback.light()
                }
            }
        }
    }
}

struct MoodEmojiButton: View {
    let mood: MoodType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // DS: Updated spacing from 4 to Spacing.micro
            VStack(spacing: Spacing.micro) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                Text(mood.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? mood.color : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            // DS: Updated padding from 12 to Spacing.medium
            .padding(.vertical, Spacing.medium)
            .background(
                // DS: Updated cornerRadius to CornerRadius.normal
                RoundedRectangle(cornerRadius: CornerRadius.normal)
                    .fill(isSelected ? mood.color.opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                // DS: Updated cornerRadius to CornerRadius.normal
                RoundedRectangle(cornerRadius: CornerRadius.normal)
                    .strokeBorder(
                        isSelected ? mood.color : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mood.displayName)
        .accessibilityValue(isSelected ? "Seçili" : "Seçili değil")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Seçmek için tıklayın")
    }
}

// MARK: - Mood Intensity Slider

struct MoodIntensitySlider: View {
    @Binding var intensity: Int
    let selectedMood: MoodType

    var body: some View {
        // DS: Updated spacing from 8 to Spacing.small
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text(String(localized: "mood.intensity", comment: "Intensity"))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(String(format: NSLocalizedString("mood.intensity.of.five", comment: "Intensity out of 5"), intensity))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    // DS: Updated padding to Spacing.small and Spacing.micro
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.micro)
                    .background(Capsule().fill(selectedMood.color.opacity(0.2)))
            }

            // DS: Updated spacing from 8 to Spacing.small
            HStack(spacing: Spacing.small) {
                ForEach(1...5, id: \.self) { level in
                    // DS: cornerRadius 4 is reasonable for small bars
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            level <= intensity ?
                            selectedMood.color :
                            Color(.tertiarySystemFill)
                        )
                        .frame(height: CGFloat(level * 8))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                intensity = level
                            }
                            HapticFeedback.light()
                        }
                }
            }
            .frame(height: 40)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Yoğunluk seviyesi: \(intensity) / 5")
        .accessibilityValue("\(intensity)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if intensity < 5 {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        intensity += 1
                    }
                    HapticFeedback.light()
                }
            case .decrement:
                if intensity > 1 {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        intensity -= 1
                    }
                    HapticFeedback.light()
                }
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Journal Type Button

struct JournalTypeButton: View {
    let journalType: JournalType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticFeedback.light()
        }) {
            // DS: Updated spacing from 12 to Spacing.medium
            HStack(spacing: Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    journalType.color.opacity(0.8),
                                    journalType.color.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: journalType.icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                // DS: Updated spacing from 4 to Spacing.micro
                VStack(alignment: .leading, spacing: Spacing.micro) {
                    HStack {
                        Text(journalType.emoji)
                            .font(.title3)

                        Text(journalType.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }

                    Text(journalType.aiPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(journalType.color)
                }
            }
            // DS: Updated padding from 12 to Spacing.medium
            .padding(Spacing.medium)
            .background(
                // DS: Updated cornerRadius to CornerRadius.relaxed
                RoundedRectangle(cornerRadius: CornerRadius.relaxed)
                    .fill(
                        isSelected ?
                        journalType.color.opacity(0.1) :
                        Color(.secondarySystemBackground)
                    )
            )
            .overlay(
                // DS: Updated cornerRadius to CornerRadius.relaxed
                RoundedRectangle(cornerRadius: CornerRadius.relaxed)
                    .strokeBorder(
                        isSelected ? journalType.color : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(journalType.displayName)
        .accessibilityValue(isSelected ? "Seçili" : "Seçili değil")
        .accessibilityHint(journalType.aiPrompt)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Mood Calendar Cell (Heatmap için)

struct MoodCalendarCell: View {
    let data: MoodDayData

    var body: some View {
        // DS: Updated spacing from 4 to Spacing.micro
        VStack(spacing: Spacing.micro) {
            // Gün numarası
            Text("\(data.dayNumber)")
                .font(.caption2)
                .fontWeight(data.isToday ? .bold : .regular)
                .foregroundStyle(data.isToday ? .white : .primary)

            // Mood indicator
            if let mood = data.moodType {
                Circle()
                    .fill(mood.color)
                    // DS: Updated size from 8 to Spacing.small
                    .frame(width: Spacing.small, height: Spacing.small)
            } else {
                Circle()
                    .strokeBorder(Color(.tertiaryLabel), lineWidth: 1)
                    // DS: Updated size from 8 to Spacing.small
                    .frame(width: Spacing.small, height: Spacing.small)
            }
        }
        .frame(maxWidth: .infinity)
        // DS: Updated padding from 8 to Spacing.small
        .padding(.vertical, Spacing.small)
        .background(
            // DS: Updated cornerRadius to CornerRadius.tight
            RoundedRectangle(cornerRadius: CornerRadius.tight)
                .fill(data.isToday ? Color.blue : Color.clear)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(data.moodType != nil ? "\(data.dayNumber), \(data.moodType!.displayName)" : "\(data.dayNumber), mood kaydı yok")
        .accessibilityValue(data.isToday ? "Bugün" : "")
    }
}

// MARK: - Mood Stat Card (Dashboard için)

struct MoodStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?

    var body: some View {
        // DS: Updated spacing from 8 to Spacing.small
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Spacer()

                if let trend = trend {
                    Text(trend)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(color.opacity(0.15)))
                }
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .metadataText() // DS: Using typography helper
        }
        // DS: Updated padding to Spacing.large
        .padding(Spacing.large)
        .background(
            // DS: Updated cornerRadius to CornerRadius.normal
            RoundedRectangle(cornerRadius: CornerRadius.normal)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityValue(trend != nil ? "Trend: \(trend!)" : "")
    }
}

// MARK: - Empty State

struct MoodEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?

    var body: some View {
        // DS: Updated spacing from 20 to Spacing.xlarge
        VStack(spacing: Spacing.xlarge) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // DS: Updated spacing from 8 to Spacing.small
            VStack(spacing: Spacing.small) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(message)
                    .secondaryText() // DS: Using typography helper
                    .multilineTextAlignment(TextAlignment.center)
            }

            if let actionLabel = actionLabel, let action = action {
                Button {
                    HapticFeedback.medium()
                    action()
                } label: {
                    Text(actionLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        // DS: Updated padding to Spacing.xxlarge and Spacing.medium
                        .padding(.horizontal, Spacing.xxlarge)
                        .padding(.vertical, Spacing.medium)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(40)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MoodEmojiPicker(selectedMood: .constant(.happy))

        MoodIntensitySlider(
            intensity: .constant(3),
            selectedMood: .happy
        )

        JournalTypeButton(
            journalType: .gratitude,
            isSelected: true,
            action: {}
        )
    }
    .padding()
}
