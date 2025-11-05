//
//  StepTagsView.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Journal editor - Tag selection step
//

import SwiftUI

struct StepTagsView: View {
    @Bindable var state: JournalEditorState
    @Bindable var viewModel: MoodJournalViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.medium) {
                // Compact Header
                VStack(spacing: Spacing.small) {
                    Image(systemName: "tag.fill")
                        .font(.largeTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [state.selectedType.color, state.selectedType.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(String(localized: "mood.add.tags", comment: "Add tags"))
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(String(localized: "journal.categorize", comment: "Categorize your journal"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.medium)
                .frame(maxWidth: .infinity)

                // Tag Picker
                TagPickerView(
                    selectedTags: $state.selectedTags,
                    suggestions: viewModel.tagSuggestions,
                    allEntries: viewModel.journalEntries
                )
                .padding(.horizontal, Spacing.medium)
                .padding(.top, Spacing.small)

                // Bottom padding for keyboard
                Color.clear.frame(height: 120)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    StepTagsView(
        state: JournalEditorState(),
        viewModel: MoodJournalViewModel()
    )
}
