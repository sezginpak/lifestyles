//
//  StepReviewView.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Journal editor - Final review step
//

import SwiftUI

struct StepReviewView: View {
    @Bindable var state: JournalEditorState
    @Bindable var viewModel: MoodJournalViewModel

    // Edit mode check
    private var isEditMode: Bool {
        viewModel.editingJournalEntry != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                // Header
                VStack(spacing: Spacing.small) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.success)

                    Text(String(localized: "journal.preview.save", comment: "Preview and Save"))
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(String(localized: "journal.check", comment: "Check your journal"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.xlarge)

                // Review Card
                VStack(alignment: .leading, spacing: Spacing.large) {
                    // Type
                    ReviewRow(
                        icon: state.selectedType.icon,
                        label: "Tip",
                        value: "\(state.selectedType.emoji) \(state.selectedType.displayName)",
                        color: state.selectedType.color
                    )

                    Divider()

                    // Title
                    if !state.title.isEmpty {
                        ReviewRow(
                            icon: "text.cursor",
                            label: "Başlık",
                            value: state.title,
                            color: .secondary
                        )

                        Divider()
                    }

                    // Content Preview
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(Color.secondary)
                            Text(String(localized: "journal.content", comment: "Content"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(String(localized: "journal.character.count", defaultValue: "\(state.content.count) characters", comment: "Character count"))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Text(state.content.prefix(150) + (state.content.count > 150 ? "..." : ""))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(4)
                    }

                    // Tags
                    if !state.selectedTags.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.small) {
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundStyle(Color.secondary)
                                Text(String(localized: "mood.tags", comment: "Tags"))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }

                            FlowLayout(spacing: 6) {
                                ForEach(state.selectedTags, id: \.self) { tag in
                                    Text(String(localized: "journal.tag.format", defaultValue: "#\(tag)", comment: "Tag format"))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(state.selectedType.color)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(state.selectedType.color.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }

                    // Mood Link
                    if viewModel.currentMood != nil && !isEditMode {
                        Divider()

                        Toggle(isOn: $state.linkToMood) {
                            HStack(spacing: Spacing.small) {
                                Text(viewModel.currentMood?.moodType.emoji ?? "😊")
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(localized: "journal.link.to.mood", comment: "Link to today's mood"))
                                        .font(.caption)
                                        .fontWeight(.semibold)

                                    if let mood = viewModel.currentMood {
                                        Text(mood.moodType.displayName)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .tint(.brandPrimary)
                    }
                }
                .padding(Spacing.large)
                .glassmorphismCard(
                    cornerRadius: CornerRadius.medium
                )
            }
            .padding(Spacing.large)
        }
    }
}

#Preview {
    StepReviewView(
        state: {
            let state = JournalEditorState()
            state.currentStep = .review
            state.selectedType = .gratitude
            state.title = "Test Journal"
            state.content = "Bu bir test journal içeriğidir."
            state.selectedTags = ["test", "sample"]
            return state
        }(),
        viewModel: MoodJournalViewModel()
    )
}
