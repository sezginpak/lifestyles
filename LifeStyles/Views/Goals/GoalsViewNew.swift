//
//  GoalsViewNew.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  YENİ modern hedefler ekranı - karma (Goals + Habits)
//

import SwiftUI
import SwiftData

struct GoalsViewNew: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GoalsViewModel()
    @State private var hasLoadedData = false
    @State private var showingPremiumSheet = false

    // Services
    private var achievementService: AchievementService {
        AchievementService.shared
    }

    private var premiumManager: PremiumManager {
        PremiumManager.shared
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Loading State
                        if viewModel.isLoading {
                            loadingContent
                        } else if viewModel.goals.isEmpty && viewModel.habits.isEmpty {
                            // Empty State
                            emptyStateContent
                        } else {
                            // Normal Content
                            normalContent
                        }
                    }
                    .padding(.vertical)
                }

                // Error Overlay
                if viewModel.showError, let errorMessage = viewModel.errorMessage {
                    GoalErrorStateView(
                        title: "Bir Hata Oluştu",
                        message: errorMessage,
                        retryAction: {
                            viewModel.loadGoals(context: modelContext)
                            viewModel.loadHabits(context: modelContext)
                        }
                    )
                }
            }
            .navigationTitle(String(localized: "goals.tab.title", comment: "Goals"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Add Goal
                        Button {
                            viewModel.showingAddGoal = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }

                        // Add Habit
                        Button {
                            viewModel.showingAddHabit = true
                        } label: {
                            Image(systemName: "star.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddGoal) {
                AddGoalView(viewModel: viewModel, modelContext: modelContext)
            }
            .sheet(isPresented: $viewModel.showingAddHabit) {
                AddHabitView(viewModel: viewModel, modelContext: modelContext)
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumSubscriptionView()
            }
            .task {
                // Sadece ilk kez veri yükle
                if !hasLoadedData {
                    viewModel.loadGoals(context: modelContext)
                    viewModel.loadHabits(context: modelContext)
                    hasLoadedData = true
                }
            }
            .refreshable {
                // Refresh için güvenli yeniden yükleme
                await refreshData()
            }
            .confetti(isPresented: $viewModel.showConfetti, count: 50)
        }
    }

    // MARK: - Loading Content

    private var loadingContent: some View {
        VStack(spacing: 20) {
            DashboardSkeletonCard()
                .padding(.horizontal)

            ForEach(0..<3, id: \.self) { _ in
                GoalSkeletonCard()
                    .padding(.horizontal)
            }

            ForEach(0..<2, id: \.self) { _ in
                HabitSkeletonCard()
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Empty State Content

    private var emptyStateContent: some View {
        VStack(spacing: 40) {
            EmptyStateView(
                icon: "target",
                title: "Henüz Hedef Yok",
                message: "İlk hedefini ekleyerek başla! Hedefler seni motivasyonlu tutmana yardımcı olacak.",
                actionTitle: "Hedef Ekle",
                action: {
                    viewModel.showingAddGoal = true
                }
            )

            EmptyStateView(
                icon: "star",
                title: "Henüz Alışkanlık Yok",
                message: "Günlük alışkanlıklar ekleyerek kendini geliştirmeye başla!",
                actionTitle: "Alışkanlık Ekle",
                action: {
                    viewModel.showingAddHabit = true
                }
            )
        }
        .padding()
    }

    // MARK: - Normal Content

    private var normalContent: some View {
        VStack(spacing: 20) {
                    // 1. Hero Dashboard
                    HeroDashboardCard(combinedStats: viewModel.combinedStats)
                        .padding(.horizontal)

                    // 2. Filter Bar
                    FilterBar(
                        searchText: $viewModel.searchText,
                        selectedCategory: $viewModel.selectedCategoryFilter,
                        selectedPriority: $viewModel.selectedPriorityFilter,
                        dateFilter: $viewModel.dateFilter
                    )
                    .padding(.horizontal)

                    // 3. Weekly & Monthly Stats
                    HStack(spacing: 12) {
                        WeeklyStatsChart(weeklyStats: viewModel.weeklyGoalStats)
                            .frame(maxWidth: .infinity)

                        MonthlyProgressRing(monthlyStats: viewModel.monthlyGoalStats)
                            .frame(width: 140)
                            .premiumLocked(
                                !premiumManager.isPremium,
                                title: String(localized: "premium.feature.trend.analysis")
                            ) {
                                showingPremiumSheet = true
                            }
                    }
                    .padding(.horizontal)

                    // 3. Today's Focus
                    if !viewModel.todaysFocus.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "goal.todays.focus", comment: "Today's focus"))
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.todaysFocus) { goal in
                                GoalRingCard(goal: goal) {
                                    viewModel.quickCompleteGoal(goal, context: modelContext)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // 4. Active Goals
                    if !viewModel.activeGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(format: NSLocalizedString("goals.active.count", comment: "Active Goals"), viewModel.activeGoals.count))
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.activeGoals.prefix(5)) { goal in
                                GoalRingCard(goal: goal) {
                                    viewModel.completeGoal(goal, context: modelContext)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // 5. Active Habits
                    if !viewModel.activeHabits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(format: NSLocalizedString("goal.habits.count.format", comment: "Habits (X)"), viewModel.activeHabits.count))
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.activeHabits.prefix(3)) { habit in
                                HabitStreakCard(habit: habit) {
                                    viewModel.toggleHabitCompletion(habit: habit, context: modelContext)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // 5.5. Premium Analytics Card
                    PremiumAnalyticsCard()
                        .padding(.horizontal)

                    // 6. Achievements
                    if !viewModel.achievements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(String(localized: "goal.achievements", comment: "Achievements"))
                                    .font(.headline)

                                Spacer()

                                Text(String(format: NSLocalizedString("goals.achievement.progress", comment: "Achievement progress current/total"), achievementService.earnedCount, achievementService.totalCount))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // İlk 3 achievement'ı göster
                                    ForEach(viewModel.achievements.prefix(3)) { achievement in
                                        AchievementBadgeCard(achievement: achievement)
                                    }

                                    // Geri kalanı premium
                                    if viewModel.achievements.count > 3 {
                                        ForEach(viewModel.achievements.dropFirst(3).prefix(7)) { achievement in
                                            AchievementBadgeCard(achievement: achievement)
                                                .premiumLocked(
                                                    !premiumManager.isPremium,
                                                    title: String(localized: "premium.achievements.unlock")
                                                ) {
                                                    showingPremiumSheet = true
                                                }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // 7. AI Coaching (iOS 26+) - Premium Feature
                    if #available(iOS 26.0, *) {
                        AICoachingCard(coaching: "Bugün Health kategorisine odaklan. 3 hedefin deadline yaklaşıyor!")
                            .padding(.horizontal)
                            .premiumLocked(
                                !premiumManager.isPremium,
                                title: String(localized: "premium.feature.ai.insights")
                            ) {
                                showingPremiumSheet = true
                            }
                    }
        }
    }

    // MARK: - Refresh Helper
    @MainActor
    private func refreshData() async {
        // Stats'ı güncelle, model context'i tekrar set etme
        viewModel.calculateWeeklyStats()
        viewModel.calculateMonthlyStats()
        viewModel.updateCombinedStats()
        viewModel.checkAndAwardAchievements(context: modelContext)
    }
}

#Preview {
    GoalsViewNew()
        .modelContainer(for: [Goal.self, Habit.self, GoalMilestone.self])
}
