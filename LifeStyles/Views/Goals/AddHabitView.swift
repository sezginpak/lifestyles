//
//  AddHabitView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI
import SwiftData

/// Multi-step alışkanlık ekleme wizard view
struct AddHabitView: View {
    @Bindable var viewModel: GoalsViewModel
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @State private var draftManager = DraftManager.shared

    // Draft state
    @State private var draft: HabitDraft

    // Validation errors
    @State private var nameError: String?
    @State private var targetCountError: String?
    @State private var descriptionError: String?

    // UI state
    @State private var showingEmojiPicker = false
    @State private var showingTemplateSelection = true
    @State private var isLoadingAI = false
    @State private var reminderEnabled = false

    init(viewModel: GoalsViewModel, modelContext: ModelContext) {
        self.viewModel = viewModel
        self.modelContext = modelContext

        let loadedDraft = DraftManager.shared.loadDraftHabit() ?? .empty
        _draft = State(initialValue: loadedDraft)
        _showingTemplateSelection = State(initialValue: DraftManager.shared.loadDraftHabit() == nil)
        _reminderEnabled = State(initialValue: loadedDraft.reminderTime != nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.accentSecondary.opacity(0.1), Color.accentSecondary.opacity(0.05), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if !showingTemplateSelection {
                        HabitProgressIndicator(currentStep: draft.currentStep, totalSteps: 4)
                            .padding()
                    }

                    ScrollView {
                        VStack(spacing: AppConstants.Spacing.large) {
                            if showingTemplateSelection {
                                templateSelectionView
                            } else {
                                switch draft.currentStep {
                                case 1: step1BasicInfoView
                                case 2: step2DetailsView
                                case 3: step3PreviewView
                                default: EmptyView()
                                }
                            }
                        }
                        .padding()
                    }

                    if !showingTemplateSelection {
                        navigationButtons
                    }
                }
            }
            .navigationTitle(showingTemplateSelection ? "Alışkanlık Şablonu" : "Yeni Alışkanlık")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $draft.emoji)
            }
            .onChange(of: draft) { _, newDraft in
                draftManager.saveDraftHabit(newDraft)
            }
        }
    }

    // MARK: - Template Selection
    private var templateSelectionView: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            VStack(spacing: AppConstants.Spacing.small) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient(colors: [.accentSecondary, .accentSecondary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(String(localized: "habit.template.select", comment: "Select template header"))
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(String(localized: "habit.template.description", comment: "Template description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical)

            Button {
                withAnimation { showingTemplateSelection = false; draft.currentStep = 1 }
                HapticFeedback.selection()
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                    VStack(alignment: .leading) {
                        Text(String(localized: "habit.blank.title", comment: "Blank habit")).font(.headline)
                        Text(String(localized: "habit.blank.description", comment: "Start from scratch")).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card).fill(Color.adaptiveSecondaryBackground))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(String(localized: "habit.popular.templates", comment: "Popular templates")).font(.headline).padding(.horizontal, AppConstants.Spacing.small)
                ForEach(HabitTemplatesData.popularTemplates) { template in
                    HabitTemplateRow(template: template) { applyTemplate(template) }
                }
            }
        }
    }

    // MARK: - Step 1
    private var step1BasicInfoView: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            VStack(spacing: AppConstants.Spacing.small) {
                Text(String(localized: "friend.basic.info", comment: "Basic info")).font(.title2.weight(.bold))
                Text(String(localized: "habit.basic.info.description", comment: "Basic info description")).font(.subheadline).foregroundStyle(.secondary)
            }

            Button { showingEmojiPicker = true; HapticFeedback.selection() } label: {
                VStack(spacing: AppConstants.Spacing.small) {
                    Text(draft.emoji).font(.system(size: 64)).frame(width: 100, height: 100).background(Circle().fill(Color.accentSecondary.opacity(0.15)))
                    Text(String(localized: "friend.change.emoji", comment: "Change emoji")).font(.caption).foregroundStyle(Color.accentSecondary)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(String(localized: "habit.name.label", comment: "Habit name")).font(.subheadline.weight(.semibold))
                TextField("Örn: Sabah meditasyonu", text: $draft.name)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium).fill(Color.adaptiveSecondaryBackground))
                    .overlay(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium).stroke(nameError != nil ? Color.red : Color.clear, lineWidth: 1))
                    .onChange(of: draft.name) { _, newValue in nameError = HabitValidation.validateName(newValue) }
                if let error = nameError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(String(localized: "habit.frequency.label", comment: "Frequency")).font(.subheadline.weight(.semibold))
                Picker(String(localized: "habit.frequency.label", comment: "Frequency"), selection: $draft.frequency) {
                    Text(String(localized: "habit.frequency.daily", comment: "Daily")).tag(HabitFrequency.daily)
                    Text(String(localized: "habit.frequency.weekly", comment: "Weekly")).tag(HabitFrequency.weekly)
                    Text(String(localized: "habit.frequency.monthly", comment: "Monthly")).tag(HabitFrequency.monthly)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Step 2
    private var step2DetailsView: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            VStack(spacing: AppConstants.Spacing.small) {
                Text(String(localized: "common.details", comment: "Details")).font(.title2.weight(.bold))
                Text(String(localized: "habit.details.description", comment: "Details description")).font(.subheadline).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text(String(localized: "habit.target.count", comment: "Target count")).font(.subheadline.weight(.semibold))
                Stepper(value: $draft.targetCount, in: 1...100) {
                    HStack {
                        Text(String(format: NSLocalizedString("habit.target.format", comment: "Target format"), draft.targetCount))
                        Spacer()
                        Text(targetCountLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: draft.targetCount) { _, newValue in targetCountError = HabitValidation.validateTargetCount(newValue) }
                if let error = targetCountError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                HStack {
                    Text(String(localized: "habit.description.optional", comment: "Description optional")).font(.subheadline.weight(.semibold))
                    Spacer()
                    if #available(iOS 26.0, *) {
                        Button { generateAIDescription() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text(String(localized: "habit.ai.suggestion", comment: "AI suggestion"))
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.brandPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.brandPrimary.opacity(0.1)))
                        }
                        .disabled(isLoadingAI)
                    }
                }

                TextEditor(text: $draft.description)
                    .frame(height: 100)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium).fill(Color.adaptiveSecondaryBackground))
                    .onChange(of: draft.description) { _, newValue in descriptionError = HabitValidation.validateDescription(newValue) }

                if isLoadingAI {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text(String(localized: "habit.ai.generating", comment: "AI generating")).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Step 3
    private var step3PreviewView: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            VStack(spacing: AppConstants.Spacing.small) {
                Text(String(localized: "habit.preview.save", comment: "Preview and save")).font(.title2.weight(.bold))
                Text(String(localized: "habit.preview.description", comment: "Preview description")).font(.subheadline).foregroundStyle(.secondary)
            }

            HabitPreviewCard(draft: draft)

            VStack(spacing: AppConstants.Spacing.medium) {
                Toggle(isOn: $reminderEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "friend.reminder", comment: "Reminder")).font(.subheadline.weight(.semibold))
                        Text(String(localized: "habit.reminder.description", comment: "Reminder description")).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .tint(Color.accentSecondary)
                .onChange(of: reminderEnabled) { _, enabled in
                    if enabled && draft.reminderTime == nil {
                        var components = DateComponents()
                        components.hour = 9
                        components.minute = 0
                        draft.reminderTime = Calendar.current.date(from: components)
                    } else if !enabled {
                        draft.reminderTime = nil
                    }
                }

                if reminderEnabled, let _ = draft.reminderTime {
                    DatePicker("Hatırlatma Saati", selection: Binding(
                        get: { draft.reminderTime ?? Date() },
                        set: { draft.reminderTime = $0 }
                    ), displayedComponents: .hourAndMinute)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card).fill(Color.adaptiveSecondaryBackground))
        }
    }

    // MARK: - Navigation
    private var navigationButtons: some View {
        HStack(spacing: AppConstants.Spacing.medium) {
            if draft.currentStep > 1 {
                Button {
                    withAnimation { draft.currentStep -= 1 }
                    HapticFeedback.selection()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(String(localized: "common.back", comment: "Back"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.button).fill(Color.adaptiveSecondaryBackground))
                }
                .buttonStyle(.plain)
            }

            Button { handleNextOrSave() } label: {
                HStack {
                    Text(draft.currentStep == 3 ? "Kaydet" : "İleri")
                    if draft.currentStep < 3 { Image(systemName: "chevron.right") }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.button).fill(LinearGradient(colors: [.accentSecondary, .accentSecondary.opacity(0.8)], startPoint: .leading, endPoint: .trailing)))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!canProceed)
        }
        .padding()
        .background(Color.adaptiveBackground)
    }

    // MARK: - Helpers
    private func applyTemplate(_ template: HabitTemplate) {
        draft.name = template.name
        draft.emoji = template.emoji
        draft.frequency = template.frequency
        draft.targetCount = template.targetCount
        draft.description = template.description
        draft.reminderTime = template.suggestedReminderTime
        reminderEnabled = template.defaultReminderHour != nil
        draft.currentStep = 1
        withAnimation { showingTemplateSelection = false }
        HapticFeedback.success()
    }

    @available(iOS 26.0, *)
    private func generateAIDescription() {
        isLoadingAI = true
        Task {
            if let suggestion = await viewModel.generateHabitSuggestion() {
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
            saveHabit()
        } else {
            withAnimation { draft.currentStep += 1 }
            HapticFeedback.selection()
        }
    }

    private func saveHabit() {
        guard nameError == nil, targetCountError == nil, descriptionError == nil else {
            HapticFeedback.error()
            return
        }

        viewModel.addHabit(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            frequency: draft.frequency,
            targetCount: draft.targetCount,
            reminderTime: draft.reminderTime,
            context: modelContext
        )

        draftManager.clearDraftHabit()
        HapticFeedback.success()
        dismiss()
    }

    private var canProceed: Bool {
        switch draft.currentStep {
        case 1: return nameError == nil && !draft.name.isEmpty
        case 2: return targetCountError == nil && descriptionError == nil
        case 3: return true
        default: return false
        }
    }

    private var targetCountLabel: String {
        switch draft.frequency {
        case .daily: return "\(draft.targetCount) kez/gün"
        case .weekly: return "\(draft.targetCount) kez/hafta"
        case .monthly: return "\(draft.targetCount) kez/ay"
        }
    }
}

