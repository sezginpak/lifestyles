//
//  MiniCalendarView.swift
//  LifeStyles
//
//  Extracted from FriendDetailTabs.swift - Phase 5
//  Mini calendar showing last 30 days of contact activity
//

import SwiftUI

struct MiniCalendarView: View {
    let history: [ContactHistory]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "friend.last.30.days", comment: "Last 30 days"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(getLast30Days(), id: \.self) { date in
                    let hasContact = checkContactOnDate(date)
                    Circle()
                        .fill(hasContact ? Color.green : Color(.systemGray5))
                        .frame(height: 28)
                        .overlay(
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption2)
                                .foregroundStyle(hasContact ? .white : .secondary)
                        )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helper Functions

    private func getLast30Days() -> [Date] {
        (0..<30).compactMap { dayOffset in
            Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())
        }.reversed()
    }

    private func checkContactOnDate(_ date: Date) -> Bool {
        history.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}
