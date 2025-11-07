//
//  TagPickerView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Journal tag picker with suggestions
//

import SwiftUI

struct TagPickerView: View {
    @Binding var selectedTags: [String]
    let suggestions: [String]
    let allEntries: [JournalEntry]

    @State private var customTag: String = ""
    @State private var showingAllTags: Bool = false

    private let tagService = TagSuggestionService.shared

    var body: some View {
        // DS: Updated spacing from 16 to Spacing.large
        VStack(alignment: .leading, spacing: Spacing.large) {
            // Header
            HStack {
                Label(String(localized: "label.tags", comment: "Tags label"), systemImage: "tag.fill")
                    .font(.subheadline.weight(.medium))

                Spacer()

                if !selectedTags.isEmpty {
                    Text(String(format: NSLocalizedString("tags.selected.count.format", comment: "Selected tags count"), selectedTags.count))
                        .metadataText() // DS: Using typography helper
                }
            }

            // Selected tags (removable)
            if !selectedTags.isEmpty {
                selectedTagsView
            }

            // Custom tag input
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)

                TextField(String(localized: "placeholder.custom.tag", comment: "Custom tag"), text: $customTag)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        addCustomTag()
                    }
            }
            // DS: Updated padding to Spacing.large
            .padding(Spacing.large)
            .background(
                // DS: Updated cornerRadius to CornerRadius.compact
                RoundedRectangle(cornerRadius: CornerRadius.compact)
                    .fill(Color(.tertiarySystemBackground))
            )

            // Suggestions
            if !suggestions.isEmpty {
                suggestionsSection
            }

            // Frequent tags
            if !allEntries.isEmpty {
                frequentTagsButton
            }
        }
    }

    // MARK: - Selected Tags

    private var selectedTagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // DS: Updated spacing from 8 to Spacing.small
            HStack(spacing: Spacing.small) {
                ForEach(selectedTags, id: \.self) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: true,
                        onTap: {
                            removeTag(tag)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        // DS: Updated spacing from 8 to Spacing.small
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(String(localized: "tags.suggestions", comment: "Suggestions"))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            // DS: Updated spacing from 8 to Spacing.small
            FlowLayout(spacing: Spacing.small) {
                ForEach(suggestions.filter { !selectedTags.contains($0) }, id: \.self) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: false,
                        onTap: {
                            addTag(tag)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Frequent Tags Button

    private var frequentTagsButton: some View {
        Button {
            showingAllTags = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text(String(localized: "tags.frequently.used", comment: "Frequently Used Tags"))
                    .font(.caption.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundStyle(.blue)
            // DS: Updated padding to Spacing.large
            .padding(Spacing.large)
            .background(
                // DS: Updated cornerRadius to CornerRadius.compact
                RoundedRectangle(cornerRadius: CornerRadius.compact)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .sheet(isPresented: $showingAllTags) {
            FrequentTagsSheet(
                allEntries: allEntries,
                selectedTags: $selectedTags
            )
        }
    }

    // MARK: - Actions

    private func addTag(_ tag: String) {
        guard !selectedTags.contains(tag) else { return }
        withAnimation {
            selectedTags.append(tag)
        }
        HapticFeedback.light()
    }

    private func removeTag(_ tag: String) {
        withAnimation {
            selectedTags.removeAll { $0 == tag }
        }
        HapticFeedback.light()
    }

    private func addCustomTag() {
        let trimmed = customTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !selectedTags.contains(trimmed) else {
            customTag = ""
            return
        }

        withAnimation {
            selectedTags.append(trimmed)
        }
        customTag = ""
        HapticFeedback.success()
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            // DS: Updated spacing from 4 to Spacing.micro
            HStack(spacing: Spacing.micro) {
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                } else {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                }

                Text(tag)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            // DS: Updated padding from 12 and 6 to Spacing.medium and 6
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.tertiarySystemBackground))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : Color(.separator),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Frequent Tags Sheet

struct FrequentTagsSheet: View {
    let allEntries: [JournalEntry]
    @Binding var selectedTags: [String]
    @Environment(\.dismiss) private var dismiss

    private var tagStats: [TagStat] {
        TagSuggestionService.shared.calculateTagStats(from: allEntries)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(tagStats) { stat in
                    TagStatRow(
                        stat: stat,
                        isSelected: selectedTags.contains(stat.tag)
                    ) {
                        toggleTag(stat.tag)
                    }
                }
            }
            .navigationTitle(String(localized: "nav.frequent.tags", comment: "Frequent tags"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.ok", comment: "OK button")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
        HapticFeedback.light()
    }
}

// MARK: - Tag Stat Row

struct TagStatRow: View {
    let stat: TagStat
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)

                // DS: Updated spacing from 4 to Spacing.micro
                VStack(alignment: .leading, spacing: Spacing.micro) {
                    Text(stat.tag)
                        .font(.subheadline.weight(.medium))

                    // DS: Updated spacing from 12 to Spacing.medium
                    HStack(spacing: Spacing.medium) {
                        Label(String(localized: "tag.frequency", defaultValue: "\(stat.count) times", comment: "Tag frequency"), systemImage: "number")
                        Label(stat.lastUsedText, systemImage: "clock")
                    }
                    .metadataText() // DS: Using typography helper
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TagPickerView(
        selectedTags: .constant(["aile", "mutluluk"]),
        suggestions: ["düşünceler", "günlük", "refleksyon", "hedefler"],
        allEntries: []
    )
    .padding()
}
