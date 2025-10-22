//
//  SpecialDatesSection.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI
import SwiftData

struct SpecialDatesSection: View {
    @Environment(\.modelContext) private var modelContext

    let friend: Friend
    @State private var showingAddDate = false

    private var sortedSpecialDates: [SpecialDate] {
        (friend.specialDates ?? []).sorted { $0.daysUntil < $1.daysUntil }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(String(localized: "special.dates.title", comment: "Special dates section title"))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingAddDate = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.pink.gradient)
                }
            }

            // Yıldönümü Kartı
            if let _ = friend.anniversaryDate {
                anniversaryCard
            }

            // Özel Günler Listesi
            if !sortedSpecialDates.isEmpty {
                VStack(spacing: 12) {
                    ForEach(sortedSpecialDates) { date in
                        SpecialDateCard(specialDate: date)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteSpecialDate(date)
                                } label: {
                                    Label(String(localized: "common.delete", comment: "Delete"), systemImage: "trash")
                                }
                            }
                    }
                }
            } else if friend.anniversaryDate == nil {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text(String(localized: "special.dates.empty", comment: "No special dates added yet"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        showingAddDate = true
                    } label: {
                        Text(String(localized: "special.dates.add", comment: "Add special date"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.pink.opacity(0.2))
                            .foregroundStyle(.pink)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingAddDate) {
            AddSpecialDateView(friend: friend)
        }
    }

    // MARK: - Anniversary Card

    private var anniversaryCard: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Text("💕")
                    .font(.title)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "special.dates.anniversary", comment: "Anniversary"))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let days = friend.daysUntilAnniversary {
                    if days == 0 {
                        Text(String(localized: "common.today.celebration", comment: "Today! 🎉"))
                            .font(.caption)
                            .foregroundStyle(.pink)
                            .fontWeight(.semibold)
                    } else if days <= 30 {
                        Text(String(format: NSLocalizedString("common.days.remaining.format", comment: "X days remaining"), days))
                            .font(.caption)
                            .foregroundStyle(.pink)
                    } else {
                        Text(String(format: NSLocalizedString("common.days.remaining.format", comment: "X days remaining"), days))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let anniversary = friend.anniversaryDate {
                    Text(formatDate(anniversary))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Days Count Badge
            if let days = friend.daysUntilAnniversary, days > 0 {
                VStack(spacing: 2) {
                    Text("\(days)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.pink)

                    Text(String(localized: "time.days", comment: "days"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color.pink.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.1), Color.red.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    friend.daysUntilAnniversary ?? 999 <= 7 ? Color.pink.opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
    }

    // MARK: - Helper Functions

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    private func deleteSpecialDate(_ date: SpecialDate) {
        modelContext.delete(date)
        try? modelContext.save()
        HapticFeedback.success()
    }
}

// MARK: - Special Date Card

struct SpecialDateCard: View {
    let specialDate: SpecialDate

    var body: some View {
        HStack(spacing: 12) {
            // Emoji/Icon
            if let emoji = specialDate.emoji {
                Text(emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Circle())
            } else {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Circle())
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(specialDate.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(formatDate(specialDate.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let notes = specialDate.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Days Until Badge
            VStack(spacing: 2) {
                let days = specialDate.daysUntil

                if days == 0 {
                    Text(String(localized: "common.today", comment: "Today"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                } else {
                    Text("\(days)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(days <= 7 ? .orange : .secondary)

                    Text(String(localized: "time.days", comment: "days"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                days <= 7 ? Color.orange.opacity(0.1) : Color(.tertiarySystemBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var days: Int {
        specialDate.daysUntil
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Add Special Date View

struct AddSpecialDateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let friend: Friend

    @State private var title: String = ""
    @State private var selectedDate: Date = Date()
    @State private var emoji: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "special.dates.info", comment: "Special date info")) {
                    TextField(String(localized: "common.title", comment: "Title"), text: $title)
                    DatePicker(String(localized: "common.date", comment: "Date"), selection: $selectedDate, displayedComponents: .date)
                    TextField(String(localized: "common.emoji.optional", comment: "Emoji (optional)"), text: $emoji)
                }

                Section {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                } header: {
                    Text(String(localized: "common.notes", comment: "Notes"))
                } footer: {
                    Text(String(localized: "special.dates.notes.footer", comment: "You can optionally add notes about this special day."))
                }
            }
            .navigationTitle(String(localized: "special.dates.add", comment: "Add special date"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.save", comment: "Save")) {
                        saveSpecialDate()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveSpecialDate() {
        let specialDate = SpecialDate(
            title: title,
            date: selectedDate,
            emoji: emoji.isEmpty ? nil : emoji,
            notes: notes.isEmpty ? nil : notes
        )
        specialDate.friend = friend

        modelContext.insert(specialDate)

        do {
            try modelContext.save()
            HapticFeedback.success()
            dismiss()
        } catch {
            print("❌ Özel gün kaydedilemedi: \(error)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Friend.self, SpecialDate.self, configurations: config)

    let friend = Friend(
        name: "Sevgilim",
        relationshipType: .partner,
        anniversaryDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
    )

    let date1 = SpecialDate(title: "İlk Buluşma", date: Date(), emoji: "❤️", notes: "Kahve içtik")
    let date2 = SpecialDate(title: "Doğum Günü", date: Calendar.current.date(byAdding: .day, value: 15, to: Date())!, emoji: "🎂")
    date1.friend = friend
    date2.friend = friend

    container.mainContext.insert(friend)
    container.mainContext.insert(date1)
    container.mainContext.insert(date2)

    return ScrollView {
        SpecialDatesSection(friend: friend)
            .padding()
    }
    .modelContainer(container)
}
