//
//  CalendarJournalView.swift
//  LifeStyles
//
//  Calendar view for journal entries
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct CalendarJournalView: View {
    let entries: [JournalEntry]
    let onTap: (JournalEntry) -> Void
    let onToggleFavorite: (JournalEntry) -> Void

    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    var body: some View {
        VStack(spacing: 20) {
            // Calendar header
            calendarHeader

            // Calendar grid
            calendarGrid

            // Selected date entries
            selectedDateEntries
        }
    }

    // MARK: - Calendar Header

    var calendarHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }

            Spacer()

            VStack(spacing: 4) {
                Text(monthYearString(currentMonth))
                    .font(.system(size: 20, weight: .bold))

                Text(String(localized: "journal.count", defaultValue: "\(entriesInCurrentMonth.count) journals", comment: "Journal count"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Calendar Grid

    var calendarGrid: some View {
        VStack(spacing: 8) {
            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Days grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 8
            ) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEntries: hasEntries(on: date),
                            entriesCount: entriesCount(on: date),
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = date
                                }
                                HapticFeedback.light()
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }

    // MARK: - Selected Date Entries

    var selectedDateEntries: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Text(selectedDateString)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                if !entriesOnSelectedDate.isEmpty {
                    Text(String(localized: "journal.count", defaultValue: "\(entriesOnSelectedDate.count) journals", comment: "Journal count"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            if entriesOnSelectedDate.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text(String(localized: "journal.no.entry", comment: ""))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Entries list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(entriesOnSelectedDate) { entry in
                            CompactJournalRow(
                                entry: entry,
                                onTap: {
                                    onTap(entry)
                                },
                                onToggleFavorite: {
                                    onToggleFavorite(entry)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Computed Properties

    var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        // Pazartesi'den başlamak için offset hesapla
        let startOffset = (firstWeekday + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: startOffset)

        var date = monthInterval.start
        while date < monthInterval.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }

        return days
    }

    var entriesInCurrentMonth: [JournalEntry] {
        entries.filter { entry in
            calendar.isDate(entry.date, equalTo: currentMonth, toGranularity: .month)
        }
    }

    var entriesOnSelectedDate: [JournalEntry] {
        entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: selectedDate)
        }.sorted { $0.date > $1.date }
    }

    var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: selectedDate)
    }

    // MARK: - Helpers

    func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date).capitalized
    }

    func hasEntries(on date: Date) -> Bool {
        entries.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func entriesCount(on date: Date) -> Int {
        entries.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEntries: Bool
    let entriesCount: Int
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(String(localized: "journal.calendar.day", defaultValue: "\(calendar.component(.day, from: date))", comment: "Calendar day"))
                    .font(.system(size: 15, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundColor(textColor)

                // Entry indicator
                if hasEntries {
                    HStack(spacing: 2) {
                        ForEach(0..<min(entriesCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? Color.white : Color.brandPrimary)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: isToday ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    var backgroundColor: Color {
        if isSelected {
            return Color.brandPrimary
        } else if hasEntries {
            return Color.brandPrimary.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    var textColor: Color {
        if isSelected {
            return .white
        } else {
            return .primary
        }
    }

    var borderColor: Color {
        isToday ? Color.brandPrimary : Color.clear
    }
}

// MARK: - Compact Journal Row

struct CompactJournalRow: View {
    let entry: JournalEntry
    let onTap: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(entry.journalType.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Text(entry.journalType.emoji)
                        .font(.system(size: 20))
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    if let title = entry.title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    Text(entry.preview)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(timeString)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.6))

                        if !entry.tags.isEmpty {
                            Text(String(localized: "journal.tag.bullet", defaultValue: "• #\(entry.tags.first!)", comment: "Tag with bullet"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(entry.journalType.color)
                        }
                    }
                }

                Spacer()

                // Favorite button
                Button(action: onToggleFavorite) {
                    Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(entry.isFavorite ? .red : .gray.opacity(0.4))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Preview

#Preview {
    let sampleEntries = [
        JournalEntry(
            title: "Güzel Bir Gün",
            content: "Bugün harika geçti!",
            journalType: .general,
            tags: ["sabah"]
        ),
        JournalEntry(
            title: "Minnet",
            content: "Ailem için minnettarım.",
            journalType: .gratitude,
            tags: ["aile"]
        )
    ]

    return CalendarJournalView(
        entries: sampleEntries,
        onTap: { _ in },
        onToggleFavorite: { _ in }
    )
    .background(Color(.systemGroupedBackground))
}
