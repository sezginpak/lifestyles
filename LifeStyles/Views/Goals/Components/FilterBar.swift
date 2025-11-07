//
//  FilterBar.swift
//  LifeStyles
//
//  Created by Claude on 5.11.2025.
//  Goal ve Habit filtering ve search component'i
//

import SwiftUI

struct FilterBar: View {
    @Binding var searchText: String
    @Binding var selectedCategory: GoalCategory?
    @Binding var selectedPriority: GoalPriority?
    @Binding var dateFilter: DateFilter

    @State private var showingFilters = false

    var activeFilterCount: Int {
        var count = 0
        if selectedCategory != nil { count += 1 }
        if selectedPriority != nil { count += 1 }
        if dateFilter != .all { count += 1 }
        return count
    }

    var body: some View {
        VStack(spacing: 12) {
            // Search Bar & Filter Button
            HStack(spacing: 12) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField(String(localized: "goals.search.placeholder", comment: ""), text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

                // Filter Button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showingFilters.toggle()
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundStyle(activeFilterCount > 0 ? .blue : .secondary)

                        // Badge
                        if activeFilterCount > 0 {
                            Circle()
                                .fill(.red)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text(String(localized: "filter.active.count", defaultValue: "\(activeFilterCount)", comment: "Active filters"))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }

            // Filter Options (Expandable)
            if showingFilters {
                VStack(spacing: 16) {
                    // Category Filter
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "goals.filter.category", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // All Categories
                                GoalFilterChip(
                                    title: "Tümü",
                                    isSelected: selectedCategory == nil,
                                    color: .gray
                                ) {
                                    selectedCategory = nil
                                }

                                ForEach([GoalCategory.health, .social, .career, .personal, .fitness, .other], id: \.self) { category in
                                    GoalFilterChip(
                                        title: category.displayName,
                                        emoji: category.emoji,
                                        isSelected: selectedCategory == category,
                                        color: Color(hex: category.ringColor)
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                    }

                    // Priority Filter
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "goals.filter.priority", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            // All Priorities
                            GoalFilterChip(
                                title: "Tümü",
                                isSelected: selectedPriority == nil,
                                color: .gray
                            ) {
                                selectedPriority = nil
                            }

                            GoalFilterChip(
                                title: "Yüksek",
                                emoji: "🔴",
                                isSelected: selectedPriority == .high,
                                color: .red
                            ) {
                                selectedPriority = .high
                            }

                            GoalFilterChip(
                                title: "Orta",
                                emoji: "🟡",
                                isSelected: selectedPriority == .medium,
                                color: .orange
                            ) {
                                selectedPriority = .medium
                            }

                            GoalFilterChip(
                                title: "Düşük",
                                emoji: "🟢",
                                isSelected: selectedPriority == .low,
                                color: .green
                            ) {
                                selectedPriority = .low
                            }
                        }
                    }

                    // Date Filter
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "goals.filter.date.range", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DateFilter.allCases, id: \.self) { filter in
                                    GoalFilterChip(
                                        title: filter.displayName,
                                        isSelected: dateFilter == filter,
                                        color: .blue
                                    ) {
                                        dateFilter = filter
                                    }
                                }
                            }
                        }
                    }

                    // Clear All Button
                    if activeFilterCount > 0 {
                        Button {
                            withAnimation {
                                selectedCategory = nil
                                selectedPriority = nil
                                dateFilter = .all
                            }
                        } label: {
                            Text(String(localized: "goals.filter.clear", comment: ""))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Filter Chip

struct GoalFilterChip: View {
    let title: String
    var emoji: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.light()
            action()
        } label: {
            HStack(spacing: 4) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.caption)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.2) : Color(.systemGray5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? color : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Filter Enum

enum DateFilter: String, CaseIterable {
    case all = "all"
    case today = "today"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case overdue = "overdue"
    case upcoming = "upcoming"

    var displayName: String {
        switch self {
        case .all: return "Tümü"
        case .today: return "Bugün"
        case .thisWeek: return "Bu Hafta"
        case .thisMonth: return "Bu Ay"
        case .overdue: return "Gecikmiş"
        case .upcoming: return "Yaklaşan (7 gün)"
        }
    }

    func matches(goal: Goal) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDate(goal.targetDate, inSameDayAs: now)
        case .thisWeek:
            let weekStart = calendar.startOfDay(for: now)
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { return false }
            return goal.targetDate >= weekStart && goal.targetDate < weekEnd
        case .thisMonth:
            return calendar.isDate(goal.targetDate, equalTo: now, toGranularity: .month)
        case .overdue:
            return goal.isOverdue
        case .upcoming:
            guard let sevenDaysLater = calendar.date(byAdding: .day, value: 7, to: now) else { return false }
            return goal.targetDate >= now && goal.targetDate <= sevenDaysLater
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        FilterBar(
            searchText: .constant(""),
            selectedCategory: .constant(nil),
            selectedPriority: .constant(nil),
            dateFilter: .constant(.all)
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
