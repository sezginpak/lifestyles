//
//  NewJournalEditorView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Enhanced journal editor with template, image, markdown support
//

import SwiftUI
import SwiftData

struct NewJournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    // Editor state
    @State private var currentStep: EditorStep = .template
    @State private var selectedTemplate: JournalTemplate?
    @State private var selectedType: JournalType = .general
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var hasMarkdown: Bool = false
    @State private var selectedTags: [String] = []
    @State private var linkToMood: Bool = false
    @State private var isSaving: Bool = false

    // Image state
    @State private var imageData: Data?
    @State private var imageCaption: String = ""
    @State private var showingImagePicker = false

    enum EditorStep: Int, CaseIterable {
        case template = 0
        case type = 1
        case title = 2
        case content = 3
        case image = 4
        case tags = 5
        case review = 6

        var title: String {
            switch self {
            case .template: return "Şablon"
            case .type: return "Tip"
            case .title: return "Başlık"
            case .content: return "İçerik"
            case .image: return "Fotoğraf"
            case .tags: return "Etiketler"
            case .review: return "Önizleme"
            }
        }

        var icon: String {
            switch self {
            case .template: return "doc.text.magnifyingglass"
            case .type: return "doc.text"
            case .title: return "text.cursor"
            case .content: return "pencil.line"
            case .image: return "photo"
            case .tags: return "tag"
            case .review: return "checkmark.circle"
            }
        }

        var canSkip: Bool {
            switch self {
            case .template, .title, .image, .tags: return true
            default: return false
            }
        }
    }

    var isEditMode: Bool {
        viewModel.editingJournalEntry != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress (disabled - needs EditorStep to JournalStep mapping)
                // StepProgressBar(currentStep: currentStep)

                // Content
                TabView(selection: $currentStep) {
                    templateStep.tag(EditorStep.template)
                    typeStep.tag(EditorStep.type)
                    titleStep.tag(EditorStep.title)
                    contentStep.tag(EditorStep.content)
                    imageStep.tag(EditorStep.image)
                    tagsStep.tag(EditorStep.tags)
                    reviewStep.tag(EditorStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation
                navigationButtons
                    .padding(Spacing.large)
                    .background(.ultraThinMaterial)
            }
            .navigationTitle(isEditMode ? "Journal Düzenle" : "Yeni Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(imageData: $imageData, isPresented: $showingImagePicker)
            }
        }
    }

    // MARK: - Step 0: Template Selection

    private var templateStep: some View {
        VStack(spacing: Spacing.large) {
            VStack(spacing: Spacing.small) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brandPrimary, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(String(localized: "journal.use.template.question", comment: "Would you like to use a template?"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(String(localized: "journal.guided.writing.desc", comment: "Guided writing description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Spacing.xlarge)

            // Template picker button
            Button {
                let picker = TemplatePickerView(selectedTemplate: $selectedTemplate)
                // Present as sheet
                // Note: This would need a proper sheet presentation in real implementation
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text(selectedTemplate == nil ? "Şablon Seç" : selectedTemplate!.name)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(Color.brandPrimary.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            if let template = selectedTemplate {
                templatePreview(template)
            }

            Spacer()
        }
        .padding(Spacing.large)
    }

    private func templatePreview(_ template: JournalTemplate) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text(template.emoji)
                    .font(.title2)
                Text(template.name)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    selectedTemplate = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            Text(template.templateDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !template.prompts.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.micro) {
                    Text(String(localized: "mood.questions", comment: "Questions:"))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(Array(template.prompts.prefix(3).enumerated()), id: \.offset) { _, prompt in
                        HStack(alignment: .top, spacing: 4) {
                            Text("•")
                                .font(.caption2)
                            Text(prompt)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(Spacing.medium)
        .glassmorphismCard()
    }

    // MARK: - Step 1: Type

    private var typeStep: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                headerView(
                    icon: "doc.text",
                    title: "Journal tipi seç",
                    subtitle: "İçeriğin kategorisini belirle"
                )

                LazyVStack(spacing: Spacing.medium) {
                    ForEach(JournalType.allCases, id: \.self) { type in
                        typeCard(type)
                    }
                }
            }
            .padding(Spacing.large)
        }
    }

    private func typeCard(_ type: JournalType) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedType = type
            }
            HapticFeedback.light()
        } label: {
            HStack(spacing: Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [type.color, type.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: type.icon)
                        .font(.body)
                        .foregroundStyle(.white)
                }

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

                if selectedType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(type.color)
                }
            }
            .padding(Spacing.large)
            .glassmorphismCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Title

    private var titleStep: some View {
        ScrollView {
            VStack(spacing: Spacing.xlarge) {
                headerView(
                    icon: "text.cursor",
                    title: "Başlık ekle",
                    subtitle: "İsteğe bağlı - geç seçeneğini kullanabilirsin",
                    color: selectedType.color
                )

                TextField(String(localized: "journal.placeholder.title", comment: "Title placeholder"), text: $title)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(Spacing.large)
                    .glassmorphismCard()

                Spacer()
            }
            .padding(Spacing.large)
        }
    }

    // MARK: - Step 3: Content

    private var contentStep: some View {
        VStack(spacing: Spacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "journal.write.content", comment: "Write your content"))
                        .font(.headline)
                        .fontWeight(.bold)

                    if let template = selectedTemplate {
                        Text(template.placeholderText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(selectedType.aiPrompt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(selectedType.emoji)
                    .font(.title2)
            }
            .padding(.horizontal, Spacing.large)
            .padding(.top, Spacing.medium)

            MarkdownEditor(
                text: $content,
                hasMarkdown: $hasMarkdown,
                placeholder: selectedTemplate?.placeholderText ?? selectedType.aiPrompt,
                minHeight: 300
            )
            .glassmorphismCard()
            .padding(.horizontal, Spacing.large)

            Spacer()
        }
    }

    // MARK: - Step 4: Image

    private var imageStep: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                headerView(
                    icon: "photo",
                    title: "Fotoğraf ekle",
                    subtitle: "Görsel ile journal'ını zenginleştir (opsiyonel)",
                    color: selectedType.color
                )

                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    // Image preview
                    VStack(spacing: Spacing.medium) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

                        TextField(String(localized: "journal.placeholder.photo.caption", comment: "Photo caption placeholder"), text: $imageCaption)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                            .padding(Spacing.medium)
                            .glassmorphismCard()

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                self.imageData = nil
                                imageCaption = ""
                            }
                        } label: {
                            Label(String(localized: "button.remove.photo", comment: "Remove photo button"), systemImage: "trash")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }
                } else {
                    // Image picker button
                    Button {
                        showingImagePicker = true
                    } label: {
                        VStack(spacing: Spacing.medium) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 64))
                                .foregroundStyle(selectedType.color)

                            Text(String(localized: "journal.select.photo", comment: "Select Photo"))
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text(String(localized: "journal.select.from.gallery", comment: "Select photo from gallery"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .glassmorphismCard()
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(Spacing.large)
        }
    }

    // MARK: - Step 5: Tags

    private var tagsStep: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                headerView(
                    icon: "tag.fill",
                    title: "Etiket ekle",
                    subtitle: "Journal'ını kategorize et (opsiyonel)",
                    color: selectedType.color
                )

                TagPickerView(
                    selectedTags: $selectedTags,
                    suggestions: viewModel.tagSuggestions,
                    allEntries: viewModel.journalEntries
                )

                Spacer()
            }
            .padding(Spacing.large)
        }
        .onAppear {
            viewModel.loadTagSuggestions(for: selectedType, existingTags: selectedTags)
        }
    }

    // MARK: - Step 6: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                headerView(
                    icon: "checkmark.circle.fill",
                    title: "Önizleme ve Kaydet",
                    subtitle: "Journal'ını kontrol et",
                    color: .success
                )

                VStack(alignment: .leading, spacing: Spacing.large) {
                    // Template
                    if let template = selectedTemplate {
                        reviewRow(
                            icon: template.icon,
                            label: "Şablon",
                            value: "\(template.emoji) \(template.name)",
                            color: template.color
                        )
                        Divider()
                    }

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

                    // Content preview
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        HStack {
                            Image(systemName: hasMarkdown ? "text.badge.checkmark" : "doc.text")
                                .foregroundStyle(.secondary)
                            Text(String(localized: "journal.content.label", comment: "Content"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            if hasMarkdown {
                                Text(String(localized: "journal.markdown", comment: "(Markdown)"))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            Text(String(localized: "journal.character.count", defaultValue: "\(content.count) characters", comment: "Character count"))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Text(content.prefix(150) + (content.count > 150 ? "..." : ""))
                            .font(.subheadline)
                            .lineLimit(4)
                    }

                    // Image
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.small) {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                                Text(String(localized: "journal.photo.label", comment: "Photo"))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }

                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous))

                            if !imageCaption.isEmpty {
                                Text(imageCaption)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Tags
                    if !selectedTags.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.small) {
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundStyle(.secondary)
                                Text(String(localized: "mood.tags", comment: "Tags"))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }

                            FlowLayout(spacing: 6) {
                                ForEach(selectedTags, id: \.self) { tag in
                                    Text(String(localized: "journal.tag.format", defaultValue: "#\(tag)", comment: "Tag format"))
                                        .font(.caption)
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

                    // Mood link
                    if viewModel.currentMood != nil && !isEditMode {
                        Divider()

                        Toggle(isOn: $linkToMood) {
                            HStack(spacing: Spacing.small) {
                                Text(viewModel.currentMood?.moodType.emoji ?? "😊")
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(localized: "journal.link.to.todays.mood", comment: "Link to todays mood"))
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
                    borderColor: selectedType.color.opacity(0.3)
                )
            }
            .padding(Spacing.large)
        }
    }

    // MARK: - Helper Views

    private func headerView(icon: String, title: String, subtitle: String, color: Color = .brandPrimary) -> some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(color)

            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
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
        }
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: Spacing.medium) {
            // Back
            if currentStep != .template {
                Button {
                    withAnimation {
                        currentStep = EditorStep(rawValue: currentStep.rawValue - 1) ?? .template
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

            // Next / Save
            Button {
                if currentStep == .review {
                    saveJournal()
                } else {
                    withAnimation {
                        currentStep = EditorStep(rawValue: currentStep.rawValue + 1) ?? .review
                    }
                    HapticFeedback.medium()
                }
            } label: {
                HStack(spacing: 6) {
                    if currentStep == .review {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
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
                                colors: canProceed || currentStep.canSkip ? [
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
            }
            .disabled(currentStep == .review ? !canProceed || isSaving : false)
            .buttonStyle(.plain)
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case .template, .type, .title, .image, .tags: return true
        case .content: return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .review: return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // MARK: - Actions

    private func setupEditor() {
        if let entry = viewModel.editingJournalEntry {
            selectedType = entry.journalType
            title = entry.title ?? ""
            content = entry.content
            hasMarkdown = entry.hasMarkdown
            selectedTags = entry.tags
            imageData = entry.imageData
            imageCaption = entry.imageCaption ?? ""
            selectedTemplate = entry.template

            // Skip template step in edit mode
            currentStep = .type
        }
    }

    private func saveJournal() {
        guard !isSaving else { return }

        isSaving = true
        HapticFeedback.medium()

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                // Compress image
                var compressedImageData: Data?
                var thumbnailData: Data?

                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    compressedImageData = ImageCompressionService.compress(uiImage)
                    thumbnailData = ImageCompressionService.createThumbnail(uiImage)
                }

                if let entry = viewModel.editingJournalEntry {
                    // Update
                    entry.title = title.isEmpty ? nil : title
                    entry.content = content
                    entry.journalType = selectedType
                    entry.tags = selectedTags
                    entry.hasMarkdown = hasMarkdown
                    entry.markdownContent = hasMarkdown ? content : nil
                    entry.imageData = compressedImageData
                    entry.imageThumbnailData = thumbnailData
                    entry.imageCaption = imageCaption.isEmpty ? nil : imageCaption
                    entry.template = selectedTemplate
                    entry.templateId = selectedTemplate?.id
                    entry.touch()

                    try? modelContext.save()

                    toastManager.success(
                        title: "Journal Güncellendi",
                        message: "Değişiklikler kaydedildi",
                        emoji: "✏️"
                    )
                } else {
                    // Create new
                    let newEntry = JournalEntry(
                        title: title.isEmpty ? nil : title,
                        content: content,
                        journalType: selectedType,
                        tags: selectedTags,
                        moodEntry: linkToMood ? viewModel.currentMood : nil,
                        imageData: compressedImageData,
                        imageCaption: imageCaption.isEmpty ? nil : imageCaption,
                        imageThumbnailData: thumbnailData,
                        markdownContent: hasMarkdown ? content : nil,
                        hasMarkdown: hasMarkdown,
                        templateId: selectedTemplate?.id,
                        template: selectedTemplate
                    )

                    modelContext.insert(newEntry)
                    try? modelContext.save()

                    // Increment template usage
                    selectedTemplate?.incrementUsage()
                    try? modelContext.save()

                    toastManager.success(
                        title: "Journal Kaydedildi",
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
        currentStep = .template
        selectedTemplate = nil
        selectedType = .general
        title = ""
        content = ""
        hasMarkdown = false
        selectedTags = []
        linkToMood = false
        imageData = nil
        imageCaption = ""
        isSaving = false
    }
}

// MARK: - Step Progress Bar

// StepProgressBar moved to Components/StepProgressBar.swift
