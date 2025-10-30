//
//  MoodJournalView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Ana mood & journal container
//

import SwiftUI
import SwiftData

struct MoodJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MoodJournalViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Tab", selection: $viewModel.selectedTab) {
                    ForEach(MoodJournalViewModel.Tab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $viewModel.selectedTab) {
                    MoodTrackerView(viewModel: viewModel)
                        .tag(MoodJournalViewModel.Tab.mood)

                    JournalListViewNew(viewModel: viewModel)
                        .tag(MoodJournalViewModel.Tab.journal)

                    MoodAnalyticsViewNew(entries: viewModel.moodEntries)
                        .tag(MoodJournalViewModel.Tab.analytics)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(String(localized: "mood.journal.title", comment: "Mood & Journal"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadAllData(context: modelContext)
            }
        }
    }
}

// MARK: - Journal List View (Modern) ✨

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    var body: some View {
        Group {
            if viewModel.filteredJournalEntries.isEmpty {
                MoodEmptyState(
                    icon: "book.fill",
                    title: String(localized: "journal.empty.title", comment: "No journal entries yet"),
                    message: String(localized: "journal.empty.message", comment: "Start by writing your first journal entry"),
                    actionLabel: String(localized: "journal.write.button", comment: "Write Journal"),
                    action: {
                        viewModel.showingJournalEditor = true
                    }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.medium) {
                        ForEach(Array(viewModel.filteredJournalEntries.enumerated()), id: \.element.id) { index, entry in
                            modernJournalCard(entry)
                                .transition(.scale.combined(with: .opacity))
                                .onAppear {
                                    // Stagger animation
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05)) {}
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteWithFeedback(entry)
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        toggleFavoriteWithFeedback(entry)
                                    } label: {
                                        Label(entry.isFavorite ? String(localized: "journal.unfavorite", comment: "Remove from favorites") : String(localized: "journal.favorite", comment: "Add to favorites"), systemImage: entry.isFavorite ? "star.fill" : "star")
                                    }
                                    .tint(.yellow)
                                }
                                .contextMenu {
                                    Button {
                                        viewModel.startEditingJournal(entry)
                                    } label: {
                                        Label(String(localized: "common.edit", comment: "Edit"), systemImage: "pencil")
                                    }

                                    Button {
                                        toggleFavoriteWithFeedback(entry)
                                    } label: {
                                        Label(entry.isFavorite ? String(localized: "journal.unfavorite", comment: "Remove from favorites") : String(localized: "journal.favorite", comment: "Add to favorites"), systemImage: entry.isFavorite ? "star.fill" : "star")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        deleteWithFeedback(entry)
                                    } label: {
                                        Label(String(localized: "common.delete", comment: "Delete"), systemImage: "trash")
                                    }
                                }
                        }
                    }
                    // DS: Updated padding to Spacing.large
                    .padding(Spacing.large)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    HapticFeedback.medium()
                    viewModel.showingJournalEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.brandPrimary, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(viewModel.showingJournalEditor ? 0.95 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: viewModel.showingJournalEditor)
            }
        }
        .sheet(isPresented: $viewModel.showingJournalEditor) {
            JournalEditorView(viewModel: viewModel)
        }
    }

    // MARK: - Modern Card (COMPACT)

    @State private var pressedCardId: UUID?

    private func modernJournalCard(_ entry: JournalEntry) -> some View {
        ZStack(alignment: .topLeading) {
            // Background Gradient (subtle)
            LinearGradient(
                colors: [
                    entry.journalType.color.opacity(0.05),
                    entry.journalType.color.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Header Row - Type Badge + Metadata
                HStack(alignment: .center, spacing: Spacing.small) {
                    // Type Badge with gradient
                    HStack(spacing: 4) {
                        Text(entry.journalType.emoji)
                            .font(.caption)

                        Text(entry.journalType.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(entry.journalType.color)
                    }
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        entry.journalType.color.opacity(0.15),
                                        entry.journalType.color.opacity(0.08)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )

                    Spacer()

                    // Favorite Star (if applicable)
                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // Word Count Badge
                    HStack(spacing: 2) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 9))
                        Text("\(entry.wordCount)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                    )
                }

                // Title (if exists) - Enhanced typography
                if let title = entry.title {
                    Text(title)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)
                }

                // Preview Text - Better readability
                Text(entry.preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(entry.title == nil ? 3 : 2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Bottom Section - Tags + Footer
                VStack(alignment: .leading, spacing: Spacing.small) {
                    // Tags (if exists)
                    if !entry.tags.isEmpty {
                        compactJournalTags(entry.tags, typeColor: entry.journalType.color)
                    }

                    // Footer Metadata
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))

                        Text(entry.formattedDate)
                            .font(.caption2)

                        Text("•")
                            .font(.caption2)

                        Image(systemName: "clock")
                            .font(.system(size: 9))

                        Text(String(format: NSLocalizedString("journal.reading.time.format", comment: "X minutes reading time"), entry.estimatedReadingTime))
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(Spacing.large)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            entry.journalType.color.opacity(0.2),
                            entry.journalType.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(
            color: entry.journalType.color.opacity(pressedCardId == entry.id ? 0.15 : 0.08),
            radius: pressedCardId == entry.id ? 12 : 8,
            x: 0,
            y: pressedCardId == entry.id ? 6 : 4
        )
        .scaleEffect(pressedCardId == entry.id ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: pressedCardId)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                pressedCardId = entry.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    pressedCardId = nil
                }
            }
            HapticFeedback.light()
            viewModel.startEditingJournal(entry)
        }
    }

    // MARK: - Compact Tags Helper

    private func compactJournalTags(_ tags: [String], typeColor: Color) -> some View {
        HStack(spacing: 4) {
            ForEach(tags.prefix(3), id: \.self) { tag in
                HStack(spacing: 2) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 8))
                    Text(tag)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(typeColor)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    typeColor.opacity(0.12),
                                    typeColor.opacity(0.06)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(typeColor.opacity(0.2), lineWidth: 0.5)
                )
            }

            if tags.count > 3 {
                Text(String(format: NSLocalizedString("mood.more.tags", comment: "More tags count"), tags.count - 3))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(typeColor.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(typeColor.opacity(0.08))
                    )
            }
        }
    }

    // MARK: - Actions with Feedback

    private func deleteWithFeedback(_ entry: JournalEntry) {
        HapticFeedback.warning()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            viewModel.deleteJournalEntry(entry, context: modelContext)
        }

        toastManager.warning(
            title: "Journal Silindi",
            message: "Journal başarıyla silindi",
            emoji: "🗑️"
        )
    }

    private func toggleFavoriteWithFeedback(_ entry: JournalEntry) {
        let wasFavorite = entry.isFavorite

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            viewModel.toggleFavorite(entry, context: modelContext)
        }

        HapticFeedback.success()

        toastManager.success(
            title: wasFavorite ? "Favoriden Çıkarıldı" : "Favorilere Eklendi",
            message: wasFavorite ? "Journal favorilerden çıkarıldı" : "Journal favorilere eklendi",
            emoji: wasFavorite ? "⭐" : "⭐"
        )
    }
}

// MARK: - Journal Step Enum

enum JournalStep: Int, CaseIterable {
    case type = 0
    case title = 1
    case content = 2
    case tags = 3
    case review = 4

    var title: String {
        switch self {
        case .type: return String(localized: "journal.step.type", defaultValue: "Journal Tipi", comment: "Step: Journal Type")
        case .title: return String(localized: "journal.step.title", defaultValue: "Başlık", comment: "Step: Title")
        case .content: return String(localized: "journal.step.content", defaultValue: "İçerik", comment: "Step: Content")
        case .tags: return String(localized: "journal.step.tags", defaultValue: "Etiketler", comment: "Step: Tags")
        case .review: return String(localized: "journal.step.review", defaultValue: "Önizleme", comment: "Step: Review")
        }
    }

    var icon: String {
        switch self {
        case .type: return "doc.text"
        case .title: return "text.cursor"
        case .content: return "pencil.line"
        case .tags: return "tag"
        case .review: return "checkmark.circle"
        }
    }

    var canSkip: Bool {
        switch self {
        case .title, .tags: return true
        default: return false
        }
    }
}

// MARK: - OLD Step Progress Bar (Kept for backward compatibility)

struct OldStepProgressBar: View {
    let currentStep: JournalStep
    let totalSteps: Int

    var body: some View {
        VStack(spacing: Spacing.small) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(JournalStep.allCases, id: \.self) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.brandPrimary : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                }
            }

            // Current step title
            Text(currentStep.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .animation(.none, value: currentStep)
        }
        .padding(.vertical, Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Journal Editor (Compact Step-by-Step) ✨

struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    @State private var currentStep: JournalStep = .type
    @State private var selectedType: JournalType = .general
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedTags: [String] = []
    @State private var linkToMood: Bool = false
    @State private var isSaving: Bool = false

    // Edit mode check
    private var isEditMode: Bool {
        viewModel.editingJournalEntry != nil
    }

    // Step validation
    private var canProceed: Bool {
        switch currentStep {
        case .type: return true
        case .title: return true // Optional
        case .content: return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .tags: return true // Optional
        case .review: return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar
                OldStepProgressBar(currentStep: currentStep, totalSteps: JournalStep.allCases.count)

                // Step Content with TabView for smooth sliding
                TabView(selection: $currentStep) {
                    stepTypeView.tag(JournalStep.type)
                    stepTitleView.tag(JournalStep.title)
                    stepContentView.tag(JournalStep.content)
                    stepTagsView.tag(JournalStep.tags)
                    stepReviewView.tag(JournalStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)

                // Navigation Buttons
                navigationButtons
                    .padding(Spacing.large)
                    .background(.ultraThinMaterial)
            }
            .navigationTitle(isEditMode ? String(localized: "journal.edit.title", comment: "Edit Journal") : String(localized: "journal.write.title", comment: "Write Journal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticFeedback.light()
                        cleanup()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .onAppear {
                setupEditor()
            }
            .onDisappear {
                // Clean up when view disappears
                cleanup()
            }
        }
    }

    // MARK: - Step Views

    private var stepTypeView: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                // Header
                VStack(spacing: Spacing.small) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.brandPrimary, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(String(localized: "journal.type.question", comment: "What type of journal do you want to write?"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "journal.type.instruction", comment: "Start by selecting journal type"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xlarge)

                // Journal Type Cards (Compact)
                VStack(spacing: Spacing.medium) {
                    ForEach(JournalType.allCases, id: \.self) { type in
                        compactTypeCard(type)
                    }
                }
            }
            .padding(Spacing.large)
        }
    }

    private var stepTitleView: some View {
        ScrollView {
            VStack(spacing: Spacing.xlarge) {
                // Compact Header
                VStack(spacing: Spacing.small) {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 40))
                        .foregroundStyle(selectedType.color)

                    Text(String(localized: "journal.add.title", comment: "Add title"))
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(String(localized: "journal.title.optional", comment: "Optional - you can skip"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.large)

                // Title Input
                TextField("Başlık (opsiyonel)", text: $title)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(Spacing.large)
                    .glassmorphismCard(
                        cornerRadius: CornerRadius.medium
                    )

                // Bottom padding for keyboard
                Color.clear.frame(height: 80)
            }
            .padding(Spacing.large)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var stepContentView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    // Compact Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "journal.write.content", comment: "Write your content"))
                                .font(.headline)
                                .fontWeight(.bold)

                            Text(selectedType.aiPrompt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(selectedType.emoji)
                            .font(.title2)
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.top, Spacing.small)

                    // Modern Text Editor - Dynamic height
                    ModernTextEditor(
                        text: $content,
                        placeholder: selectedType.aiPrompt,
                        minHeight: max(200, geometry.size.height * 0.5),
                        showCounter: true,
                        maxCharacters: 5000
                    )
                    .frame(height: max(250, geometry.size.height * 0.65))
                    .padding(.horizontal, Spacing.large)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var stepTagsView: some View {
        ScrollView {
            VStack(spacing: Spacing.medium) {
                // Compact Header
                VStack(spacing: Spacing.small) {
                    Image(systemName: "tag.fill")
                        .font(.largeTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [selectedType.color, selectedType.color.opacity(0.7)],
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
                    selectedTags: $selectedTags,
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

    private var stepReviewView: some View {
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
                    reviewRow(
                        icon: selectedType.icon,
                        label: "Tip",
                        value: "\(selectedType.emoji) \(selectedType.displayName)",
                        color: selectedType.color
                    )

                    Divider()

                    // Title
                    if !title.isEmpty {
                        reviewRow(
                            icon: "text.cursor",
                            label: "Başlık",
                            value: title,
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

                            Text("\(content.count) karakter")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Text(content.prefix(150) + (content.count > 150 ? "..." : ""))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(4)
                    }

                    // Tags
                    if !selectedTags.isEmpty {
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
                                ForEach(selectedTags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(selectedType.color)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(selectedType.color.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }

                    // Mood Link
                    if viewModel.currentMood != nil && !isEditMode {
                        Divider()

                        Toggle(isOn: $linkToMood) {
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

    // MARK: - Helper Views

    private func compactTypeCard(_ type: JournalType) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedType = type
            }
            HapticFeedback.light()
        } label: {
            HStack(spacing: Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [type.color.opacity(0.9), type.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: type.icon)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(type.emoji)
                        Text(type.displayName)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    Text(type.aiPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Checkmark
                if selectedType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(type.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(Spacing.large)
            .glassmorphismCard(
                cornerRadius: CornerRadius.medium
            )
        }
        .buttonStyle(.plain)
    }

    private func reviewRow(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: Spacing.medium) {
            // Back Button
            if currentStep != .type {
                Button {
                    withAnimation {
                        currentStep = JournalStep(rawValue: currentStep.rawValue - 1) ?? .type
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
                if currentStep == .review {
                    saveJournal()
                } else {
                    withAnimation {
                        currentStep = JournalStep(rawValue: currentStep.rawValue + 1) ?? .review
                    }
                    HapticFeedback.medium()

                    // Load tag suggestions when moving to tags step
                    if currentStep == .tags {
                        viewModel.loadTagSuggestions(for: selectedType, existingTags: selectedTags)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if currentStep == .review {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: isEditMode ? "checkmark" : "arrow.down.doc")
                        }
                        Text(isEditMode ? "Güncelle" : "Kaydet")
                    } else {
                        Text(currentStep.canSkip && !canProceed ? "Geç" : "İleri")
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
                                colors: (currentStep == .review && canProceed && !isSaving) || (currentStep != .review && (canProceed || currentStep.canSkip)) ? [
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
                    color: canProceed ? Color.brandPrimary.opacity(0.3) : .clear,
                    radius: 8,
                    y: 2
                )
            }
            .disabled(currentStep == .review ? !canProceed || isSaving : false)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helper Methods

    private func setupEditor() {
        if let entry = viewModel.editingJournalEntry {
            // Edit mode - populate fields
            selectedType = entry.journalType
            title = entry.title ?? ""
            content = entry.content
            selectedTags = entry.tags
        }
        viewModel.loadTagSuggestions(for: selectedType, existingTags: selectedTags)
    }

    private func saveJournal() {
        guard !isSaving else { return }

        isSaving = true
        HapticFeedback.medium()

        Task {
            // Simulate save delay for animation
            try? await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                if let entry = viewModel.editingJournalEntry {
                    // Update existing
                    viewModel.updateJournalEntry(
                        entry,
                        title: title.isEmpty ? nil : title,
                        content: content,
                        tags: selectedTags,
                        context: modelContext
                    )

                    // Success toast
                    toastManager.success(
                        title: "Journal Güncellendi",
                        message: "Değişiklikler kaydedildi",
                        emoji: "✏️"
                    )
                } else {
                    // Create new
                    viewModel.createJournalEntry(
                        content: content,
                        journalType: selectedType,
                        title: title.isEmpty ? nil : title,
                        tags: selectedTags,
                        linkToTodaysMood: linkToMood,
                        context: modelContext
                    )

                    // Success toast
                    toastManager.success(
                        title: "Journal Kaydedildi",
                        message: "\(selectedType.emoji) \(selectedType.displayName) journal'ı oluşturuldu",
                        emoji: "📝"
                    )
                }

                isSaving = false
                cleanup()

                // Delay dismiss for toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
    }

    private func cleanup() {
        viewModel.editingJournalEntry = nil
        // Reset all state
        currentStep = .type
        selectedType = .general
        title = ""
        content = ""
        selectedTags = []
        linkToMood = false
        isSaving = false
    }
}

// MARK: - Analytics View (Basit)

struct MoodAnalyticsView: View {
    @Bindable var viewModel: MoodJournalViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                // Stats Cards (3-column)
                statsSection

                // Compact 7-day Calendar Heatmap
                compactWeekHeatmap

                // Correlations (compact)
                MoodCorrelationsView(
                    goalCorrelations: viewModel.moodCorrelation.goalCorrelations,
                    friendCorrelations: viewModel.moodCorrelation.friendCorrelations,
                    locationCorrelations: viewModel.locationCorrelations
                )

                // AI Insight (iOS 26+)
                if #available(iOS 26.0, *) {
                    compactAIInsightSection
                }
            }
            .padding(Spacing.large)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "journal.stats", comment: "Statistics"))
                .cardTitle()

            // 3-column grid with MiniStatCard
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.medium) {
                MiniStatCard(
                    title: "Streak",
                    value: "\(viewModel.streakData.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )

                MiniStatCard(
                    title: "Ortalama",
                    value: String(format: "%.1f", viewModel.moodStats.averageMood),
                    icon: "star.fill",
                    color: .purple
                )

                MiniStatCard(
                    title: "Bu Hafta",
                    value: "\(viewModel.moodCountThisWeek)",
                    icon: "calendar",
                    color: .blue
                )
            }
        }
    }

    // MARK: - Compact Week Heatmap (7-day horizontal)

    private var compactWeekHeatmap: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "journal.last.7.days", comment: "Last 7 Days"))
                .cardTitle()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(0..<7, id: \.self) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                        let moodDayData = viewModel.heatmapData.first(where: {
                            Calendar.current.isDate($0.date, inSameDayAs: date)
                        })

                        // MoodDayData'dan MoodEntry oluştur
                        let moodEntry: MoodEntry? = {
                            if let moodType = moodDayData?.moodType,
                               let score = moodDayData?.averageScore {
                                return MoodEntry(
                                    moodType: moodType,
                                    intensity: Int(score.rounded()),
                                    note: nil
                                )
                            }
                            return nil
                        }()

                        MoodGridItem(mood: moodEntry, date: date)
                    }
                }
            }
        }
    }

    // MARK: - Compact AI Insight

    @available(iOS 26.0, *)
    private var compactAIInsightSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text(String(localized: "ai.analysis", comment: "AI Analysis"))
                    .cardTitle()
            }

            if viewModel.isLoadingAI {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let insight = viewModel.aiInsight {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(insight.summary)
                        .font(.caption)
                        .fontWeight(.medium)

                    ForEach(insight.suggestions.prefix(3), id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: Spacing.micro) {
                            Text("💡")
                                .font(.caption2)

                            Text(suggestion)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.normal)
                        .fill(Color.purple.opacity(0.1))
                )
            } else {
                Button("Haftalık Analiz Oluştur") {
                    Task {
                        await viewModel.generateWeeklyAnalysis(context: modelContext)
                    }
                }
                .font(.caption)
            }
        }
    }
}

#Preview {
    MoodJournalView()
        .modelContainer(for: [MoodEntry.self, JournalEntry.self])
}
