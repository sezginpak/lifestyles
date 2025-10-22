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
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(MoodType.allCases, id: \.self) { mood in
                MoodEmojiButton(
                    mood: mood,
                    isSelected: selectedMood == mood
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
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
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                Text(mood.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? mood.color : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mood.color.opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? mood.color : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mood Intensity Slider

struct MoodIntensitySlider: View {
    @Binding var intensity: Int
    let selectedMood: MoodType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Yoğunluk")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(intensity)/5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(selectedMood.color.opacity(0.2)))
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            level <= intensity ?
                            selectedMood.color :
                            Color(.tertiarySystemFill)
                        )
                        .frame(height: CGFloat(level * 8))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                intensity = level
                            }
                            HapticFeedback.light()
                        }
                }
            }
            .frame(height: 40)
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
            HStack(spacing: 12) {
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

                VStack(alignment: .leading, spacing: 4) {
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
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        journalType.color.opacity(0.1) :
                        Color(.secondarySystemBackground)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? journalType.color : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mood Calendar Cell (Heatmap için)

struct MoodCalendarCell: View {
    let data: MoodDayData

    var body: some View {
        VStack(spacing: 4) {
            // Gün numarası
            Text("\(data.dayNumber)")
                .font(.caption2)
                .fontWeight(data.isToday ? .bold : .regular)
                .foregroundStyle(data.isToday ? .white : .primary)

            // Mood indicator
            if let mood = data.moodType {
                Circle()
                    .fill(mood.color)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .strokeBorder(Color(.tertiaryLabel), lineWidth: 1)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(data.isToday ? Color.blue : Color.clear)
        )
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
        VStack(alignment: .leading, spacing: 8) {
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
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
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
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
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
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
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
