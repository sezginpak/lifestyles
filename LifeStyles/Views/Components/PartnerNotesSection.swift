//
//  PartnerNotesSection.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI
import SwiftData

struct PartnerNotesSection: View {
    @Environment(\.modelContext) private var modelContext

    let friend: Friend
    @State private var selectedCategory: NoteCategory? = nil
    @State private var showingAddNote = false

    private var filteredNotes: [PartnerNote] {
        if let category = selectedCategory {
            return friend.partnerNotes.filter { $0.category == category }
        }
        return friend.partnerNotes
    }

    private var notesByCategory: [NoteCategory: [PartnerNote]] {
        Dictionary(grouping: friend.partnerNotes) { $0.category }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(String(localized: "partner.notes", comment: "Partner Notes"))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingAddNote = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.purple.gradient)
                }
            }

            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Tümü
                    NoteCategoryChip(
                        title: "Tümü",
                        emoji: "📋",
                        count: friend.partnerNotes.count,
                        isSelected: selectedCategory == nil
                    ) {
                        withAnimation {
                            selectedCategory = nil
                        }
                    }

                    // Kategoriler
                    ForEach(NoteCategory.allCases, id: \.self) { category in
                        let count = notesByCategory[category]?.count ?? 0
                        if count > 0 {
                            NoteCategoryChip(
                                title: category.displayName,
                                emoji: category.emoji,
                                count: count,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }
            }

            // Notes List
            if !filteredNotes.isEmpty {
                VStack(spacing: 10) {
                    ForEach(filteredNotes) { note in
                        PartnerNoteCard(note: note, friend: friend)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteNote(note)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            } else {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text(selectedCategory == nil ? "Henüz not eklenmemiş" : "Bu kategoride not yok")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        showingAddNote = true
                    } label: {
                        Text("Not Ekle")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingAddNote) {
            AddPartnerNoteView(friend: friend)
        }
    }

    private func deleteNote(_ note: PartnerNote) {
        var notes = friend.partnerNotes
        notes.removeAll { $0.id == note.id }
        friend.partnerNotes = notes

        do {
            try modelContext.save()
            HapticFeedback.success()
        } catch {
            print("❌ Not silinemedi: \(error)")
        }
    }
}

// MARK: - Note Category Chip

struct NoteCategoryChip: View {
    let title: String
    let emoji: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.body)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ?
                Color.purple.opacity(0.2) :
                Color(.tertiarySystemBackground)
            )
            .foregroundStyle(isSelected ? .purple : .secondary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Partner Note Card

struct PartnerNoteCard: View {
    let note: PartnerNote
    let friend: Friend

    private var categoryColor: Color {
        switch note.category {
        case .favorite: return .yellow
        case .hobby: return .purple
        case .dislike: return .red
        case .important: return .orange
        case .other: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category Indicator
            Text(note.category.emoji)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(categoryColor.opacity(0.1))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.category.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(categoryColor)

                    Spacer()

                    Text(formatDate(note.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(note.content)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(categoryColor.opacity(0.2), lineWidth: 1)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Add Partner Note View

struct AddPartnerNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let friend: Friend

    @State private var selectedCategory: NoteCategory = .favorite
    @State private var content: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Kategori") {
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(NoteCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.emoji)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    TextEditor(text: $content)
                        .frame(height: 120)
                } header: {
                    Text("Not")
                } footer: {
                    Text(String(localized: "partner.notes.placeholder", comment: "Write information you want to remember about your partner here"))
                }
            }
            .navigationTitle("Not Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
                        saveNote()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveNote() {
        let note = PartnerNote(
            category: selectedCategory,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        var notes = friend.partnerNotes
        notes.append(note)
        friend.partnerNotes = notes

        do {
            try modelContext.save()
            HapticFeedback.success()
            dismiss()
        } catch {
            print("❌ Not kaydedilemedi: \(error)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Friend.self, configurations: config)

    let friend = Friend(
        name: "Sevgilim",
        relationshipType: .partner
    )

    friend.partnerNotes = [
        PartnerNote(category: .favorite, content: "En sevdiği yemek: Sushi 🍣"),
        PartnerNote(category: .favorite, content: "Favori film: Inception"),
        PartnerNote(category: .hobby, content: "Fotoğrafçılık yapmayı seviyor 📸"),
        PartnerNote(category: .dislike, content: "Deniz mahsulleri sevmiyor"),
        PartnerNote(category: .important, content: "Kahve sade içiyor ☕"),
        PartnerNote(category: .other, content: "Her sabah 7'de kalkıyor")
    ]

    container.mainContext.insert(friend)

    return ScrollView {
        PartnerNotesSection(friend: friend)
            .padding()
    }
    .modelContainer(container)
}
