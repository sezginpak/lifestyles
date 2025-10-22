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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Tag'ler", systemImage: "tag.fill")
                    .font(.subheadline.weight(.medium))

                Spacer()

                if !selectedTags.isEmpty {
                    Text("\(selectedTags.count) seçili")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

                TextField("Özel tag ekle", text: $customTag)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        addCustomTag()
                    }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
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
            HStack(spacing: 8) {
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Öneriler")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 8) {
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
                Text("Sık Kullanılan Tag'ler")
                    .font(.caption.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundStyle(.blue)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
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
            HStack(spacing: 4) {
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
            .padding(.horizontal, 12)
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

// MARK: - Flow Layout (for tag wrapping)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowLayoutResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowLayoutResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.origins[index], proposal: .unspecified)
        }
    }

    struct FlowLayoutResult {
        var origins: [CGPoint] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x != 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                origins.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
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
            .navigationTitle("Sık Kullanılan Tag'ler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.tag)
                        .font(.subheadline.weight(.medium))

                    HStack(spacing: 12) {
                        Label("\(stat.count) kez", systemImage: "number")
                        Label(stat.lastUsedText, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
