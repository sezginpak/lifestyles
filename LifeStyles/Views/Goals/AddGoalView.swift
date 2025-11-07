//
//  AddGoalView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI
import SwiftData

/// Multi-step hedef ekleme wizard view
struct AddGoalView: View {
    @Bindable var viewModel: GoalsViewModel
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @State private var draftManager = DraftManager.shared

    // Draft state
    @State private var draft: GoalDraft

    // Validation errors
    @State private var titleError: String?
    @State private var dateError: String?
    @State private var descriptionError: String?

    // UI state
    @State private var showingEmojiPicker = false
    @State private var showingTemplateSelection = true
    @State private var isLoadingAI = false

    init(viewModel: GoalsViewModel, modelContext: ModelContext) {
        self.viewModel = viewModel
        self.modelContext = modelContext

        // Draft'tan yükle veya yeni oluştur
        let loadedDraft = DraftManager.shared.loadDraftGoal() ?? .empty
        _draft = State(initialValue: loadedDraft)

        // Eğer draft varsa template selection'ı atla
        _showingTemplateSelection = State(initialValue: DraftManager.shared.loadDraftGoal() == nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.cardGoals.opacity(0.1),
                        Color.cardGoals.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    if !showingTemplateSelection {
                        ProgressIndicator(currentStep: draft.currentStep, totalSteps: 4)
                            .padding()
                    }

                    // Content
                    ScrollView {
                        VStack(spacing: AppConstants.Spacing.large) {
                            if showingTemplateSelection {
                                templateSelectionView
                            } else {
                                switch draft.currentStep {
                                case 1:
                                    step1BasicInfoView
                                case 2:
                                    step2DetailsView
                                case 3:
                                    step3PreviewView
                                default:
                                    EmptyView()
                                }
                            }
                        }
                        .padding()
                    }

                    // Navigation buttons
                    if !showingTemplateSelection {
                        navigationButtons
                    }
                }
            }
            .navigationTitle(showingTemplateSelection ? "Hedef Şablonu" : "Yeni Hedef")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "button.cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $draft.emoji)
            }
            .onChange(of: draft) { _, newDraft in
                // Auto-save draft
                draftManager.saveDraftGoal(newDraft)
            }
        }
    }

    // MARK: - Template Selection View
    private var templateSelectionView: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            // Header
            VStack(spacing: AppConstants.Spacing.small) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cardGoals, Color.cardGoals.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(String(localized: "goal.template.select", comment: "Select template"))
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(String(localized: "goal.template.description", comment: "Template description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical)

            // Blank goal button
            Button {
                withAnimation {
                    showingTemplateSelection = false
                    draft.currentStep = 1
                }
                HapticFeedback.selection()
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                    VStack(alignment: .leading) {
                        Text(String(localized: "goal.blank.title", comment: "Blank goal"))
                            .font(.headline)
                        Text(String(localized: "goal.blank.description", comment: "Start from scratch"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.adaptiveSecondaryBackground)
                )
            }
            .buttonStyle(.plain)

            // Templates
            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(String(localized: "goal.popular.templates", comment: "Popular templates"))
                    .font(.headline)
                    .padding(.horizontal, AppConstants.Spacing.small)

                ForEach(GoalTemplatesData.popularTemplates) { template in
                    GoalTemplateRow(template: template) {
                        applyTemplate(template)
                    }
                }
            }

            // More templates button
            Button {
                // Tüm şablonları göster (gelecekte modal açılabilir)
                HapticFeedback.selection()
            } label: {
                HStack {
                    Text(String(localized: "goal.all.templates", comment: "All templates"))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.cardGoals)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                        .stroke(Color.cardGoals, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Step 1: Basic Info
    private var step1BasicInfoView: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            VStack(spacing: AppConstants.Spacing.small) {
                Text(String(localized: "common.basic.info", comment: "Basic info"))
                    .font(.title2.weight(.bold))
                Text(String(localized: "goal.basic.info.description", comment: "Basic info description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Emoji picker button
            Button {
                showingEmojiPicker = true
                HapticFeedback.selection()
            } label: {
                VStack(spacing: AppConstants.Spacing.small) {
                    Text(draft.emoji)
                        .font(.system(size: 64))
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(Color.cardGoals.opacity(0.15))
                        )

                    Text(String(localized: "friend.change.emoji", comment: "Change emoji"))
                        .font(.caption)
                        .foregroundStyle(Color.cardGoals)
                }
            }
            .buttonStyle(.plain)

            // Title field
            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(String(localized: "goal.title.label", comment: "Goal title"))
                    .font(.subheadline.weight(.semibold))

                TextField(String(localized: "goal.title.placeholder", comment: "Goal title placeholder"), text: $draft.title)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                            .fill(Color.adaptiveSecondaryBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                            .stroke(titleError != nil ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .onChange(of: draft.title) { _, newValue in
                        titleError = GoalValidation.validateTitle(newValue)
                    }

                if let error = titleError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Category picker
            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(String(localized: "goal.category.label", comment: "Category"))
                    .font(.subheadline.weight(.semibold))

                Picker(String(localized: "goal.category.label", comment: "Category"), selection: $draft.category) {
                    ForEach([GoalCategory.health, .fitness, .career, .social, .personal, .other], id: \.self) { category in
                        HStack {
                            Text(categoryIcon(category))
                            Text(categoryName(category))
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Step 2: Details
    private var step2DetailsView: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            VStack(spacing: AppConstants.Spacing.small) {
                Text(String(localized: "common.details", comment: "Details"))
                    .font(.title2.weight(.bold))
                Text(String(localized: "goal.details.description", comment: "Details description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Description field
            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                HStack {
                    Text(String(localized: "common.description.optional", comment: "Description optional"))
                        .font(.subheadline.weight(.semibold))
                    Spacer()

                    // AI suggestion button (iOS 26+)
                    if #available(iOS 26.0, *) {
                        Button {
                            generateAIDescription()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text(String(localized: "common.ai.suggestion", comment: "AI suggestion"))
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.brandPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.brandPrimary.opacity(0.1))
                            )
                        }
                        .disabled(isLoadingAI)
                    }
                }

                TextEditor(text: $draft.description)
                    .frame(height: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                            .fill(Color.adaptiveSecondaryBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                            .stroke(descriptionError != nil ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .onChange(of: draft.description) { _, newValue in
                        descriptionError = GoalValidation.validateDescription(newValue)
                    }

                if isLoadingAI {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text(String(localized: "goal.ai.generating", comment: "AI generating"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = descriptionError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Target date picker
            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(String(localized: "goal.target.date", comment: "Target date"))
                    .font(.subheadline.weight(.semibold))

                DatePicker(
                    String(localized: "goal.target.date", comment: "Target date"),
                    selection: $draft.targetDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .onChange(of: draft.targetDate) { _, newValue in
                    dateError = GoalValidation.validateDate(newValue)
                }

                if let error = dateError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Step 3: Preview
    private var step3PreviewView: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            VStack(spacing: AppConstants.Spacing.small) {
                Text(String(localized: "goal.preview.save", comment: "Preview and save"))
                    .font(.title2.weight(.bold))
                Text(String(localized: "goal.preview.description", comment: "Preview description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Preview card
            GoalPreviewCard(draft: draft)

            // Reminder toggle
            VStack(alignment: .leading, spacing: AppConstants.Spacing.medium) {
                Toggle(isOn: $draft.reminderEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "friend.reminder", comment: "Reminder"))
                            .font(.subheadline.weight(.semibold))
                        Text(String(localized: "goal.reminder.description", comment: "Reminder description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(Color.cardGoals)

                if draft.reminderEnabled {
                    Text(String(localized: "goal.reminder.time", comment: "Reminder time"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(Color.adaptiveSecondaryBackground)
            )
        }
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: AppConstants.Spacing.medium) {
            if draft.currentStep > 1 {
                Button {
                    withAnimation {
                        draft.currentStep -= 1
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(String(localized: "common.back", comment: "Back"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.button)
                            .fill(Color.adaptiveSecondaryBackground)
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                handleNextOrSave()
            } label: {
                HStack {
                    Text(draft.currentStep == 3 ? String(localized: "common.save", comment: "Save") : String(localized: "common.next", comment: "Next"))
                    if draft.currentStep < 3 {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.button)
                        .fill(
                            LinearGradient(
                                colors: [Color.cardGoals, Color.cardGoals.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!canProceed)
        }
        .padding()
        .background(Color.adaptiveBackground)
    }

    // MARK: - Helper Methods

    private func applyTemplate(_ template: GoalTemplate) {
        draft.title = template.title
        draft.emoji = template.emoji
        draft.category = template.category
        draft.targetDate = template.suggestedTargetDate
        draft.description = template.description
        draft.currentStep = 1

        withAnimation {
            showingTemplateSelection = false
        }

        HapticFeedback.success()
    }

    @available(iOS 26.0, *)
    private func generateAIDescription() {
        isLoadingAI = true

        Task {
            if let suggestion = await viewModel.generateGoalSuggestion(category: draft.category) {
                await MainActor.run {
                    draft.description = suggestion
                    isLoadingAI = false
                    HapticFeedback.success()
                }
            } else {
                await MainActor.run {
                    isLoadingAI = false
                    HapticFeedback.error()
                }
            }
        }
    }

    private func handleNextOrSave() {
        if draft.currentStep == 3 {
            saveGoal()
        } else {
            withAnimation {
                draft.currentStep += 1
            }
            HapticFeedback.selection()
        }
    }

    private func saveGoal() {
        // Final validation
        guard titleError == nil,
              dateError == nil,
              descriptionError == nil else {
            HapticFeedback.error()
            return
        }

        // Save goal
        viewModel.addGoal(
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category,
            targetDate: draft.targetDate,
            context: modelContext
        )

        // Clear draft
        draftManager.clearDraftGoal()

        // Success feedback
        HapticFeedback.success()

        // Dismiss
        dismiss()
    }

    private var canProceed: Bool {
        switch draft.currentStep {
        case 1:
            return titleError == nil && !draft.title.isEmpty
        case 2:
            return dateError == nil && descriptionError == nil
        case 3:
            return true
        default:
            return false
        }
    }

    private func categoryIcon(_ category: GoalCategory) -> String {
        switch category {
        case .health: return "❤️"
        case .fitness: return "💪"
        case .career: return "💼"
        case .social: return "👥"
        case .personal: return "🌟"
        case .other: return "📌"
        }
    }

    private func categoryName(_ category: GoalCategory) -> String {
        switch category {
        case .health: return String(localized: "goal.category.health", comment: "Health")
        case .fitness: return String(localized: "goal.category.fitness", comment: "Fitness")
        case .career: return String(localized: "goal.category.career", comment: "Career")
        case .social: return String(localized: "goal.category.social", comment: "Social")
        case .personal: return String(localized: "goal.category.personal", comment: "Personal")
        case .other: return String(localized: "goal.category.other", comment: "Other")
        }
    }
}

