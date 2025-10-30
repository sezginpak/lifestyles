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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Hero Dashboard
                    HeroDashboardCard(combinedStats: viewModel.combinedStats)
                        .padding(.horizontal)

                    // 2. Weekly & Monthly Stats
                    HStack(spacing: 12) {
                        WeeklyStatsChart(weeklyStats: viewModel.weeklyGoalStats)
                            .frame(maxWidth: .infinity)

                        MonthlyProgressRing(monthlyStats: viewModel.monthlyGoalStats)
                            .frame(width: 140)
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
                                    viewModel.quickCompleteGoal(goal)
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
                                    viewModel.completeGoal(goal)
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
                                    ForEach(viewModel.achievements.prefix(10)) { achievement in
                                        AchievementBadgeCard(achievement: achievement)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // 7. AI Coaching (iOS 26+)
                    if #available(iOS 26.0, *) {
                        AICoachingCard(coaching: "Bugün Health kategorisine odaklan. 3 hedefin deadline yaklaşıyor!")
                            .padding(.horizontal)
                    }

                    // Empty States
                    if viewModel.goals.isEmpty && viewModel.habits.isEmpty {
                        ContentUnavailableView(
                            "Başlayalım!",
                            systemImage: "target",
                            description: Text(String(localized: "goal.empty.description", comment: "Start by adding a new goal or habit"))
                        )
                        .padding(.vertical, 60)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hedefler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.showingAddGoal = true
                        } label: {
                            Label("Yeni Hedef", systemImage: "target")
                        }

                        Button {
                            viewModel.showingAddHabit = true
                        } label: {
                            Label("Yeni Alışkanlık", systemImage: "flame")
                        }

                        Divider()

                        Button {
                            // Achievement gallery
                        } label: {
                            Label("Başarımlar", systemImage: "trophy.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddGoal) {
                AddGoalView(viewModel: viewModel, modelContext: modelContext)
            }
            .sheet(isPresented: $viewModel.showingAddHabit) {
                AddHabitView(viewModel: viewModel, modelContext: modelContext)
            }
            .onAppear {
                viewModel.loadGoals(context: modelContext)
                viewModel.loadHabits(context: modelContext)
            }
        }
    }

    private let achievementService = AchievementService.shared
}

#Preview {
    GoalsViewNew()
        .modelContainer(for: [Goal.self, Habit.self, GoalMilestone.self])
}
