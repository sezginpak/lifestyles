//
//  FullAchievementsView.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Tüm başarıları gösteren full-screen gallery
//

import SwiftUI
import SwiftData

struct FullAchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let achievements: [Achievement]

    @State private var selectedCategory: AchievementCategory? = nil
    @State private var selectedAchievement: Achievement? = nil
    @State private var searchText = ""

    // Layout
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var filteredAchievements: [Achievement] {
        var filtered = achievements

        // Category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort: earned first, then by progress
        return filtered.sorted { first, second in
            if first.isEarned && !second.isEarned { return true }
            if !first.isEarned && second.isEarned { return false }
            return first.progressPercentage > second.progressPercentage
        }
    }

    private var earnedCount: Int {
        achievements.filter { $0.isEarned }.count
    }

    private var completionPercentage: Int {
        guard !achievements.isEmpty else { return 0 }
        return Int((Double(earnedCount) / Double(achievements.count)) * 100)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Header
                    statsHeader
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Search Bar
                    searchBar
                        .padding(.horizontal)

                    // Category Filters
                    categoryFilters

                    // Achievement Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredAchievements) { achievement in
                            ModernAchievementCard(
                                achievement: achievement,
                                onTap: {
                                    selectedAchievement = achievement
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "achievement.all.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.close", comment: "Close button")) {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailSheet(achievement: achievement)
            }
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        VStack(spacing: 16) {
            // Trophy with Circle Progress
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)

                // Progress Circle
                Circle()
                    .trim(from: 0, to: CGFloat(completionPercentage) / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: completionPercentage)

                // Trophy Center
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(String(localized: "achievement.completion.percentage", defaultValue: "%\(completionPercentage)", comment: "Completion percentage"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }

            // Stats Row
            HStack(spacing: 24) {
                statItem(value: "\(earnedCount)", label: "Kazanıldı", color: .green)
                statItem(value: "\(achievements.count - earnedCount)", label: "Kilitli", color: .orange)
                statItem(value: "\(achievements.count)", label: "Toplam", color: .blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        )
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(String(localized: "achievement.search.placeholder", comment: ""), text: $searchText)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Category Filters

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryPill(
                    category: nil,
                    isSelected: selectedCategory == nil,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedCategory = nil
                        }
                    }
                )

                ForEach([AchievementCategory.goal, .habit, .streak, .consistency, .special], id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    let service = AchievementService.shared
    let achievements = service.getAllAchievements(goals: [], habits: [], currentStreak: 0, friends: [])

    FullAchievementsView(achievements: achievements)
        .modelContainer(for: [Goal.self, Habit.self])
}
