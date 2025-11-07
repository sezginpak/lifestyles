//
//  TagComponents.swift
//  LifeStyles
//
//  Created by Claude on 03.11.2025.
//  Contact Tag UI components (for ContactTag model)
//

import SwiftUI
import SwiftData

// MARK: - Contact Tag Chip Component

struct ContactTagChip: View {
    let tag: ContactTag
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let emoji = tag.emoji {
                Text(emoji)
                    .font(.caption)
            }

            Text(tag.name)
                .font(.caption)
                .fontWeight(.medium)

            if let onRemove = onRemove {
                Button {
                    HapticFeedback.light()
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(tag.color).opacity(0.15))
        .foregroundStyle(Color(tag.color))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color(tag.color).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Contact Tag Picker View

struct ContactTagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Binding var selectedTags: [ContactTag]

    @State private var availableTags: [ContactTag] = []
    @State private var searchText = ""
    @State private var showingCreateTag = false

    var filteredTags: [ContactTag] {
        if searchText.isEmpty {
            return availableTags
        }
        return availableTags.filter { tag in
            tag.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedTags: [TagCategory: [ContactTag]] {
        Dictionary(grouping: filteredTags) { $0.category }
    }

    var body: some View {
        NavigationStack {
            List {
                if !selectedTags.isEmpty {
                    Section(String(localized: "section.selected.tags", comment: "Selected tags")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedTags) { tag in
                                    ContactTagChip(tag: tag, onRemove: {
                                        withAnimation {
                                            selectedTags.removeAll { $0.id == tag.id }
                                        }
                                    })
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                ForEach(TagCategory.allCases, id: \.self) { category in
                    if let tags = groupedTags[category], !tags.isEmpty {
                        Section {
                            ForEach(tags) { tag in
                                TagRowView(
                                    tag: tag,
                                    isSelected: selectedTags.contains { $0.id == tag.id }
                                ) {
                                    toggleTag(tag)
                                }
                            }
                        } header: {
                            Label(category.displayName, systemImage: category.icon)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Etiket ara...")
            .navigationTitle(String(localized: "nav.tags", comment: "Tags"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "tag.done", comment: "")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateTag = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTag) {
                CreateTagView(onSave: { newTag in
                    availableTags.append(newTag)
                    selectedTags.append(newTag)
                })
            }
            .onAppear {
                loadTags()
            }
        }
    }

    private func loadTags() {
        let descriptor = FetchDescriptor<ContactTag>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        do {
            availableTags = try modelContext.fetch(descriptor)

            // Eğer hiç tag yoksa, önceden tanımlı tag'leri oluştur
            if availableTags.isEmpty {
                let predefinedTags = ContactTag.createPredefinedTags()
                for tag in predefinedTags {
                    modelContext.insert(tag)
                }
                try modelContext.save()
                availableTags = predefinedTags
            }
        } catch {
            print("❌ Tag'ler yüklenemedi: \(error)")
        }
    }

    private func toggleTag(_ tag: ContactTag) {
        HapticFeedback.light()

        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            withAnimation {
                selectedTags.remove(at: index)
            }
        } else {
            withAnimation {
                selectedTags.append(tag)
            }

            // Usage count'u artır
            tag.incrementUsage()
            try? modelContext.save()
        }
    }
}

// MARK: - Tag Row View

struct TagRowView: View {
    let tag: ContactTag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                if let emoji = tag.emoji {
                    Text(emoji)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.name)
                        .fontWeight(.medium)

                    if tag.usageCount > 0 {
                        Text(String(localized: "tag.usage.count", defaultValue: "\(tag.usageCount)× used", comment: "Tag usage"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Tag View

struct CreateTagView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onSave: (ContactTag) -> Void

    @State private var name = ""
    @State private var emoji = ""
    @State private var selectedColor = "blue"
    @State private var selectedCategory: TagCategory = .general

    let colorOptions = ["blue", "green", "red", "purple", "orange", "pink", "gray", "yellow"]

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "section.tag.info", comment: "Tag info")) {
                    TextField(String(localized: "placeholder.tag.name", comment: "Tag name"), text: $name)
                    TextField(String(localized: "tag.emoji.optional", comment: ""), text: $emoji)
                }

                Section(String(localized: "section.category", comment: "Category")) {
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(TagCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(String(localized: "section.color", comment: "Color")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                selectedColor == color ? Color.primary : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        ContactTagChip(tag: ContactTag(
                            name: name.isEmpty ? "Önizleme" : name,
                            emoji: emoji.isEmpty ? nil : emoji,
                            color: selectedColor,
                            category: selectedCategory
                        ))
                        Spacer()
                    }
                } header: {
                    Text(String(localized: "tag.preview", comment: "Preview header"))
                }
            }
            .navigationTitle(String(localized: "tag.new.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "button.cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "button.save", comment: "Save button")) {
                        saveTag()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveTag() {
        let newTag = ContactTag(
            name: name,
            emoji: emoji.isEmpty ? nil : emoji,
            color: selectedColor,
            category: selectedCategory
        )

        modelContext.insert(newTag)

        do {
            try modelContext.save()
            HapticFeedback.success()
            onSave(newTag)
            dismiss()
        } catch {
            print("❌ Tag kaydedilemedi: \(error)")
        }
    }
}
