//
//  EditorNavigationButtons.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Journal editor navigation buttons (Back/Next/Save)
//

import SwiftUI

struct EditorNavigationButtons: View {
    @Bindable var state: JournalEditorState
    @Bindable var viewModel: MoodJournalViewModel
    let onSave: () -> Void
    let onLoadTagSuggestions: () -> Void

    // Edit mode check
    private var isEditMode: Bool {
        viewModel.editingJournalEntry != nil
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Back Button
            if state.currentStep != .type {
                Button {
                    withAnimation {
                        state.previousStep()
                    }
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(String(localized: "ai.back", comment: "Back"))
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }

            // Next / Skip / Save Button
            Button {
                if state.currentStep == .review {
                    onSave()
                } else {
                    withAnimation {
                        state.nextStep()
                    }
                    HapticFeedback.medium()

                    // Load tag suggestions when moving to tags step
                    if state.currentStep == .tags {
                        onLoadTagSuggestions()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if state.currentStep == .review {
                        if state.isSaving {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: isEditMode ? "checkmark" : "arrow.down.doc")
                        }
                        Text(isEditMode ? "Güncelle" : "Kaydet")
                    } else {
                        Text(state.currentStep.canSkip && !state.canProceed ? "Geç" : "İleri")
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: (state.currentStep == .review && state.canProceed && !state.isSaving) || (state.currentStep != .review && (state.canProceed || state.currentStep.canSkip)) ? [
                                    Color.brandPrimary,
                                    Color.purple
                                ] : [
                                    Color.gray.opacity(0.5),
                                    Color.gray.opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(
                    color: state.canProceed ? Color.brandPrimary.opacity(0.3) : .clear,
                    radius: 8,
                    y: 2
                )
            }
            .disabled(state.currentStep == .review ? !state.canProceed || state.isSaving : false)
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    VStack {
        Spacer()

        EditorNavigationButtons(
            state: JournalEditorState(),
            viewModel: MoodJournalViewModel(),
            onSave: {},
            onLoadTagSuggestions: {}
        )
        .padding()
        .background(.ultraThinMaterial)
    }
}
