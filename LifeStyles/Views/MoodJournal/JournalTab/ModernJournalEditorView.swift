//
//  ModernJournalEditorView.swift
//  LifeStyles
//
//  Modern, streamlined journal editor (ekleme + düzenleme)
//  Created by Claude on 05.11.2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ModernJournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    // Editor state
    @State private var selectedType: JournalType = .general
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var linkToMood: Bool = true
    @State private var isSaving: Bool = false

    // Image state
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var imageCaption: String = ""

    // UI state
    @State private var showingImagePicker = false
    @State private var showingTagPicker = false
    @FocusState private var titleFocused: Bool
    @FocusState private var contentFocused: Bool
    @FocusState private var captionFocused: Bool

    var isEditMode: Bool {
        viewModel.editingJournalEntry != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Type selector
                    typeSelector

                    // Title input
                    titleInput

                    // Image section
                    imageSection

                    // Content input
                    contentInput

                    // Tags section
                    tagsSection

                    // Mood link toggle (sadece yeni journal'da)
                    if !isEditMode && viewModel.currentMood != nil {
                        moodLinkToggle
                    }

                    // Save button
                    saveButton
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditMode ? "Journal Düzenle" : "Yeni Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        cleanup()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .onAppear {
                setupEditor()
            }
        }
    }

    // MARK: - Type Selector

    var typeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "journal.editor.type", comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(JournalType.allCases, id: \.self) { type in
                        TypeButton(
                            type: type,
                            isSelected: selectedType == type,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedType = type
                                }
                                HapticFeedback.light()
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Title Input

    var titleInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "journal.editor.title.optional", comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            TextField(String(localized: "journal.add.title.placeholder", comment: ""), text: $title)
                .font(.system(size: 18, weight: .medium))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    titleFocused ? selectedType.color.opacity(0.3) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                )
                .focused($titleFocused)
        }
    }

    // MARK: - Image Section

    var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "journal.editor.photo.optional", comment: ""))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                if imageData != nil {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            imageData = nil
                            selectedPhoto = nil
                            imageCaption = ""
                        }
                    } label: {
                        Text(String(localized: "journal.editor.remove", comment: ""))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }

            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                // Image preview
                VStack(spacing: 12) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(selectedType.color.opacity(0.2), lineWidth: 1)
                        )

                    TextField(String(localized: "journal.photo.description.placeholder", comment: ""), text: $imageCaption)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .focused($captionFocused)
                }
            } else {
                // Photo picker button
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 24))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [selectedType.color, selectedType.color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "journal.editor.photo.add", comment: ""))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(String(localized: "journal.editor.gallery", comment: ""))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .onChange(of: selectedPhoto) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            imageData = data
                        }
                    }
                }
            }
        }
    }

    // MARK: - Content Input

    var contentInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "journal.editor.content", comment: ""))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(localized: "journal.character.count", defaultValue: "\(content.count) characters", comment: "Character count"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text(selectedType.aiPrompt)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $content)
                    .font(.system(size: 16))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
                    .padding(12)
                    .focused($contentFocused)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                contentFocused ? selectedType.color.opacity(0.3) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )

            // Word count and reading time
            HStack(spacing: 16) {
                Label(String(localized: "journal.word.count.label", defaultValue: "\(wordCount) words", comment: "Word count label"), systemImage: "doc.text")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Label(String(localized: "journal.reading.time.label", defaultValue: "\(estimatedReadingTime) min read", comment: "Reading time label"), systemImage: "clock")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Tags Section

    var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "journal.editor.tags.optional", comment: ""))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    showingTagPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text(String(localized: "journal.editor.add", comment: ""))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedType.color)
                }
            }

            if selectedTags.isEmpty {
                HStack {
                    Image(systemName: "tag")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text(String(localized: "journal.editor.tags.empty", comment: ""))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTags.sorted(), id: \.self) { tag in
                            TagBadge(
                                tag: tag,
                                color: selectedType.color,
                                onRemove: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        _ = selectedTags.remove(tag)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .sheet(isPresented: $showingTagPicker) {
            TagPickerSheet(
                selectedTags: $selectedTags,
                suggestions: viewModel.tagSuggestions,
                journalType: selectedType
            )
            .onAppear {
                viewModel.loadTagSuggestions(for: selectedType, existingTags: Array(selectedTags))
            }
        }
    }

    // MARK: - Mood Link Toggle

    var moodLinkToggle: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $linkToMood) {
                HStack(spacing: 12) {
                    if let mood = viewModel.currentMood {
                        Text(mood.moodType.emoji)
                            .font(.system(size: 32))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "journal.editor.link.mood", comment: ""))
                            .font(.system(size: 15, weight: .semibold))

                        if let mood = viewModel.currentMood {
                            Text(String(localized: "journal.mood.datetime", defaultValue: "\(mood.moodType.displayName) • \(mood.formattedDate)", comment: "Mood datetime"))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .tint(selectedType.color)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                linkToMood ? selectedType.color.opacity(0.2) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    // MARK: - Save Button

    var saveButton: some View {
        Button {
            saveJournal()
        } label: {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))

                    Text(isEditMode ? "Güncelle" : "Kaydet")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: canSave ? [
                                selectedType.color,
                                selectedType.color.opacity(0.8)
                            ] : [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(
                color: canSave ? selectedType.color.opacity(0.3) : Color.clear,
                radius: 12,
                y: 6
            )
        }
        .disabled(!canSave || isSaving)
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var wordCount: Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    var estimatedReadingTime: Int {
        max(1, wordCount / 200)
    }

    // MARK: - Actions

    private func setupEditor() {
        if let entry = viewModel.editingJournalEntry {
            selectedType = entry.journalType
            title = entry.title ?? ""
            content = entry.content
            selectedTags = Set(entry.tags)
            imageData = entry.imageData
            imageCaption = entry.imageCaption ?? ""
        } else {
            // Auto-focus content for new journal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                contentFocused = true
            }
        }
    }

    private func saveJournal() {
        guard !isSaving else { return }

        isSaving = true
        HapticFeedback.success()

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)

            await MainActor.run {
                // Compress image
                var compressedImageData: Data?
                var thumbnailData: Data?

                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    compressedImageData = ImageCompressionService.compress(uiImage)
                    thumbnailData = ImageCompressionService.createThumbnail(uiImage)
                }

                if let entry = viewModel.editingJournalEntry {
                    // Update existing entry
                    entry.title = title.isEmpty ? nil : title
                    entry.content = content
                    entry.journalType = selectedType
                    entry.tags = Array(selectedTags)
                    entry.imageData = compressedImageData
                    entry.imageThumbnailData = thumbnailData
                    entry.imageCaption = imageCaption.isEmpty ? nil : imageCaption
                    entry.touch()

                    try? modelContext.save()

                    toastManager.success(
                        title: "Güncellendi",
                        message: "Journal başarıyla güncellendi",
                        emoji: "✏️"
                    )
                } else {
                    // Create new entry
                    let newEntry = JournalEntry(
                        title: title.isEmpty ? nil : title,
                        content: content,
                        journalType: selectedType,
                        tags: Array(selectedTags),
                        moodEntry: linkToMood ? viewModel.currentMood : nil,
                        imageData: compressedImageData,
                        imageCaption: imageCaption.isEmpty ? nil : imageCaption,
                        imageThumbnailData: thumbnailData
                    )

                    modelContext.insert(newEntry)
                    try? modelContext.save()

                    toastManager.success(
                        title: "Kaydedildi",
                        message: "\(selectedType.emoji) \(selectedType.displayName) journal'ı oluşturuldu",
                        emoji: "📝"
                    )
                }

                viewModel.loadAllData(context: modelContext)
                isSaving = false
                cleanup()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
    }

    private func cleanup() {
        viewModel.editingJournalEntry = nil
        selectedType = .general
        title = ""
        content = ""
        selectedTags = []
        linkToMood = true
        imageData = nil
        selectedPhoto = nil
        imageCaption = ""
        isSaving = false
    }
}

// MARK: - Type Button

struct TypeButton: View {
    let type: JournalType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(type.emoji)
                    .font(.system(size: 32))

                Text(type.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : type.color)
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                            LinearGradient(
                                colors: [type.color, type.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [type.color.opacity(0.1), type.color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.clear : type.color.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? type.color.opacity(0.3) : Color.clear,
                radius: 12,
                y: 6
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tag Badge

struct TagBadge: View {
    let tag: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(String(localized: "journal.tag.format", defaultValue: "#\(tag)", comment: "Tag format"))
                .font(.system(size: 14, weight: .medium))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Tag Picker Sheet

struct TagPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: Set<String>
    let suggestions: [String]
    let journalType: JournalType

    @State private var newTag: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Input field
                HStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 16))
                        .foregroundColor(journalType.color)

                    TextField(String(localized: "journal.new.tag.placeholder", comment: ""), text: $newTag)
                        .font(.system(size: 16))
                        .focused($isInputFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            addTag()
                        }

                    if !newTag.isEmpty {
                        Button {
                            addTag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(journalType.color)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)

                // Suggestions
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "journal.editor.tags.suggested", comment: ""))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(suggestions, id: \.self) { tag in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                        }
                                        HapticFeedback.light()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(String(localized: "journal.tag.format", defaultValue: "#\(tag)", comment: "Tag format"))
                                                .font(.system(size: 14, weight: .medium))

                                            if selectedTags.contains(tag) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14))
                                            }
                                        }
                                        .foregroundColor(
                                            selectedTags.contains(tag) ? .white : journalType.color
                                        )
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    selectedTags.contains(tag) ?
                                                        journalType.color :
                                                        journalType.color.opacity(0.15)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
            .padding(.top)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "journal.add.tag.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.ok", comment: "OK button")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedTags.insert(trimmed)
        }
        newTag = ""
        HapticFeedback.success()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: JournalEntry.self, configurations: config)

    return ModernJournalEditorView(viewModel: MoodJournalViewModel())
        .modelContainer(container)
}
