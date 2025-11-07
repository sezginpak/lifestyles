//
//  JournalDetailView.swift
//  LifeStyles
//
//  Journal görüntüleme ve detay ekranı
//  Created by Claude on 25.10.2025.
//

import SwiftUI
import SwiftData

struct JournalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    let entry: JournalEntry

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    // Header
                    header

                    // Image (if exists)
                    if entry.hasImage, let imageData = entry.imageData,
                       let uiImage = UIImage(data: imageData) {
                        journalImage(uiImage)
                    }

                    // Content
                    content

                    // Tags
                    if !entry.tags.isEmpty {
                        tags
                    }

                    // Metadata
                    metadata

                    // Linked Mood (if exists)
                    if let mood = entry.moodEntry {
                        linkedMood(mood)
                    }
                }
                .padding(Spacing.large)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle(String(localized: "journal.nav.detail", comment: "Journal detail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        // Edit
                        Button {
                            viewModel.startEditingJournal(entry)
                            dismiss()
                        } label: {
                            Label(String(localized: "button.edit", comment: "Edit button"), systemImage: "pencil")
                        }

                        // Favorite Toggle
                        Button {
                            toggleFavorite()
                        } label: {
                            Label(
                                entry.isFavorite ? "Favoriden Çıkar" : "Favorilere Ekle",
                                systemImage: entry.isFavorite ? "star.slash.fill" : "star.fill"
                            )
                        }

                        // Share
                        Button {
                            shareJournal()
                        } label: {
                            Label(String(localized: "button.share", comment: "Share button"), systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        // Delete
                        Button(role: .destructive) {
                            deleteJournal()
                        } label: {
                            Label(String(localized: "button.delete", comment: "Delete button"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.brandPrimary, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Type badge
            HStack(spacing: Spacing.small) {
                Text(entry.journalType.emoji)
                    .font(.title3)

                Text(entry.journalType.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.journalType.color)

                Spacer()

                // Favorite star
                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.body)
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(entry.journalType.color.opacity(0.1))
            )

            // Title
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            // Date
            Text(entry.formattedDate)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Image

    private func journalImage(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipped()
                .cornerRadius(CornerRadius.medium)

            if let caption = entry.imageCaption, !caption.isEmpty {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "journal.content", comment: "Content"))
                .font(.headline)
                .foregroundStyle(.primary)

            Text(entry.content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(6)
                .textSelection(.enabled)
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.surfaceSecondary)
        )
    }

    // MARK: - Tags

    private var tags: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(String(localized: "mood.tags", comment: "Tags"))
                .font(.headline)
                .foregroundStyle(.primary)

            FlowLayout(spacing: Spacing.small) {
                ForEach(entry.tags, id: \.self) { tag in
                    Text(String(localized: "journal.tag.format", defaultValue: "#\(tag)", comment: "Tag format"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.brandPrimary, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
            }
        }
    }

    // MARK: - Metadata

    private var metadata: some View {
        VStack(spacing: Spacing.small) {
            Divider()

            HStack {
                // Word Count
                HStack(spacing: 4) {
                    Image(systemName: "text.word.spacing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "journal.word.count.label", defaultValue: "\(entry.wordCount) words", comment: "Word count label"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Reading Time
                HStack(spacing: 4) {
                    Image(systemName: "book")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "journal.reading.time", defaultValue: "\(entry.estimatedReadingTime) min", comment: "Reading time"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Updated Date
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: NSLocalizedString("journal.updated", comment: "Updated time"), entry.updatedAt.formatted(.relative(presentation: .named))))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
        }
    }

    // MARK: - Linked Mood

    private func linkedMood(_ mood: MoodEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(String(localized: "journal.linked.mood", comment: "Linked Mood"))
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: Spacing.medium) {
                Text(mood.moodType.emoji)
                    .font(.title)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mood.moodType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= mood.intensity ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(mood.moodType.color)
                        }
                    }
                }

                Spacer()
            }
            .padding(Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(mood.moodType.color.opacity(0.1))
            )
        }
    }

    // MARK: - Actions

    private func toggleFavorite() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            viewModel.toggleFavorite(entry, context: modelContext)
        }

        HapticFeedback.success()

        toastManager.success(
            title: entry.isFavorite ? "Favorilere Eklendi" : "Favoriden Çıkarıldı",
            message: entry.isFavorite ? "Journal favorilere eklendi" : "Journal favorilerden çıkarıldı",
            emoji: "⭐"
        )
    }

    private func shareJournal() {
        // Share functionality
        let shareText = """
        \(entry.title ?? entry.journalType.displayName)

        \(entry.content)

        \(entry.formattedDate)
        """

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }

        HapticFeedback.light()
    }

    private func deleteJournal() {
        HapticFeedback.warning()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            viewModel.deleteJournalEntry(entry, context: modelContext)
        }

        toastManager.warning(
            title: "Journal Silindi",
            message: "Journal başarıyla silindi",
            emoji: "🗑️"
        )

        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: JournalEntry.self, MoodEntry.self,
        configurations: config
    )

    let entry = JournalEntry(
        title: "Harika bir gün",
        content: "Bugün çok güzel bir gündü. Koştum, arkadaşlarımla görüştüm ve yeni bir şeyler öğrendim.",
        journalType: .general,
        tags: ["mutluluk", "başarı"],
        isFavorite: true
    )

    container.mainContext.insert(entry)

    return JournalDetailView(
        viewModel: MoodJournalViewModel(),
        entry: entry
    )
    .modelContainer(container)
}
