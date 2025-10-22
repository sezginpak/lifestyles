//
//  DashboardViewNew.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Modern dashboard - 4 ring system + partner card
//

import SwiftUI
import SwiftData

struct DashboardViewNew: View {
    @Environment(\.modelContext) var modelContext
    @State var viewModel = DashboardViewModel()
    @State var showingSuggestions = false
    @State private var showingGeneralAIChat = false
    @State private var showingFullMorningInsight = false
    @State private var isMorningInsightPressed = false

    // Computed data
    @State private var dashboardSummary: DashboardSummary = .empty()
    @State private var partnerInfo: PartnerInfo? = nil
    @State private var streakInfo: StreakInfo = .empty()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Hero Stats Card (4 Ring)
                        HeroStatsCard(summary: dashboardSummary)
                            .padding(.horizontal)

                        // 2. Mood Widget
                        DashboardMoodWidget()

                        // 2.5. Morning Insight (Claude Haiku)
                        morningInsightSection

                        // 3. AI Insights (iOS 26+)
                        if #available(iOS 26.0, *) {
                            aiInsightsSection
                        }

                        // 4. Partner Card (Varsa)
                        if let partner = partnerInfo {
                            PartnerCard(
                                partner: partner,
                                onCall: {
                                    HapticFeedback.medium()
                                    callPartner(partner)
                                },
                                onMessage: {
                                    HapticFeedback.medium()
                                    messagePartner(partner)
                                },
                                onLogContact: {
                                    HapticFeedback.success()
                                    logPartnerContact()
                                }
                            )
                            .padding(.horizontal)
                        }

                        // 5. Streak & Achievements
                        if streakInfo.currentStreak > 0 || !streakInfo.recentAchievements.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(localized: "dashboard.achievements", comment: "Achievements"))
                                    .font(.headline)
                                    .padding(.horizontal)

                                StreakAchievementCard(streakInfo: streakInfo)
                            }
                        }

                        // 6. Compact Stats Grid (2x2)
                        compactStatsGrid

                        // 7. Smart Suggestions
                        if !viewModel.smartGoalSuggestions.isEmpty {
                            smartSuggestionsSection
                        }

                        // 8. Location Alert
                        if viewModel.needsToGoOutside {
                            locationAlertCard
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .padding(.bottom, 80) // FAB için boşluk
                }
                .background(Color(.systemGroupedBackground))

                // Floating AI Chat Button
                Button {
                    HapticFeedback.medium()
                    showingGeneralAIChat = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)

                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("LifeStyles")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingGeneralAIChat) {
                GeneralAIChatView()
            }
            .sheet(isPresented: $showingFullMorningInsight) {
                FullMorningInsightSheet(insight: viewModel.morningInsight ?? "")
            }
            .onAppear {
                loadDashboardData()
            }
        }
    }

    // MARK: - Compact Stats Grid

    var compactStatsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "dashboard.statistics", comment: "Statistics"))
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Hedefler
                DashboardCompactStatCard(
                    data: CompactStatData(
                        icon: "target",
                        title: String(localized: "dashboard.stats.goals", comment: "Goals"),
                        color: "667EEA",
                        mainValue: "%\(Int(viewModel.goalCompletionRate * 100))",
                        subValue: String(localized: "dashboard.stats.completion", comment: "Completion"),
                        progressValue: viewModel.goalCompletionRate,
                        badge: viewModel.overdueGoals > 0 ? String(format: NSLocalizedString("dashboard.stats.overdue.format", comment: "X overdue"), viewModel.overdueGoals) : nil
                    )
                )

                // İletişim
                DashboardCompactStatCard(
                    data: CompactStatData(
                        icon: "person.2.fill",
                        title: String(localized: "dashboard.stats.communication", comment: "Communication"),
                        color: "3498DB",
                        mainValue: "\(viewModel.contactsThisWeek)",
                        subValue: String(localized: "dashboard.stats.this.week", comment: "This week"),
                        progressValue: nil,
                        badge: viewModel.contactTrendPercentage != 0 ? "\(viewModel.contactTrendPercentage >= 0 ? "+" : "")\(Int(viewModel.contactTrendPercentage))%" : nil
                    )
                )

                // Alışkanlıklar
                DashboardCompactStatCard(
                    data: CompactStatData(
                        icon: "flame.fill",
                        title: String(localized: "dashboard.stats.habits", comment: "Habits"),
                        color: "E74C3C",
                        mainValue: "\(viewModel.completedHabitsToday)/\(viewModel.totalHabitsToday)",
                        subValue: String(localized: "dashboard.stats.today", comment: "Today"),
                        progressValue: viewModel.totalHabitsToday > 0 ? Double(viewModel.completedHabitsToday) / Double(viewModel.totalHabitsToday) : 0,
                        badge: String(format: NSLocalizedString("dashboard.stats.weekly.format", comment: "X% weekly"), Int(viewModel.weeklyHabitCompletionRate * 100))
                    )
                )

                // Mobilite
                DashboardCompactStatCard(
                    data: CompactStatData(
                        icon: "location.fill",
                        title: String(localized: "dashboard.stats.mobility", comment: "Mobility"),
                        color: "2ECC71",
                        mainValue: "\(viewModel.mobilityScore)",
                        subValue: String(localized: "dashboard.stats.score", comment: "Score"),
                        progressValue: Double(viewModel.mobilityScore) / 100.0,
                        badge: String(format: NSLocalizedString("dashboard.stats.locations.format", comment: "X locations"), viewModel.uniqueLocationsThisWeek)
                    )
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Smart Suggestions

    var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.warning, .accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(String(localized: "dashboard.smart.suggestions", comment: "Smart suggestions"))
                    .font(.headline)

                Spacer()

                if viewModel.smartGoalSuggestions.count > 3 {
                    Button {
                        HapticFeedback.light()
                        showingSuggestions = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(String(localized: "common.all", comment: "All"))
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(.brandPrimary)
                    }
                }
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(Array(viewModel.smartGoalSuggestions.prefix(3).enumerated()), id: \.element.id) { _, suggestion in
                    suggestionCard(suggestion: suggestion)
                }
            }
            .padding(.horizontal)
        }
    }

    func suggestionCard(suggestion: GoalSuggestion) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.brandPrimary.opacity(0.2), .accentSecondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(suggestion.category.emoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Text(suggestion.description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 4) {
                Text(suggestion.estimatedDifficulty.emoji)
                    .font(.caption)

                Text("%\(Int(suggestion.relevanceScore * 100))")
                    .font(.caption2.bold())
                    .foregroundColor(.brandPrimary)
            }
            .frame(minWidth: 40)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Location Alert

    var locationAlertCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.warning.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "sun.max.fill")
                    .font(.title3)
                    .foregroundStyle(Color.warning)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "dashboard.time.to.go.out", comment: "Time to go out"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(String(format: NSLocalizedString("dashboard.hours.at.home.format", comment: "Hours at home"), Int(viewModel.hoursAtHomeToday)))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.warning.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Morning Insight Section

    var morningInsightSection: some View {
        Group {
            if viewModel.isLoadingMorningInsight {
                // Loading state
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.purple)

                    Text(String(localized: "dashboard.morning.insight.loading", comment: "Claude is thinking about you..."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)

            } else if let insight = viewModel.morningInsight {
                // Morning insight card
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "sun.horizon.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "dashboard.morning.insight", comment: "Morning Insight"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(String(localized: "dashboard.morning.insight.personalized", comment: "Personalized with Claude Haiku"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        // Refresh button
                        Button {
                            HapticFeedback.light()
                            Task {
                                await viewModel.refreshMorningInsight(context: modelContext)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.callout)
                                .foregroundStyle(.purple.opacity(0.8))
                        }
                    }

                    Divider()

                    // Insight text
                    Text(insight)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .lineLimit(4)

                    // Long press hint
                    Text(String(localized: "dashboard.morning.insight.long.press.hint", comment: "Long press to view full insight"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.orange.opacity(0.3), .pink.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isMorningInsightPressed ? 2 : 1
                            )
                    }
                )
                .shadow(
                    color: isMorningInsightPressed ? .purple.opacity(0.3) : .purple.opacity(0.1),
                    radius: isMorningInsightPressed ? 20 : 10,
                    y: isMorningInsightPressed ? 8 : 5
                )
                .scaleEffect(isMorningInsightPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMorningInsightPressed)
                .padding(.horizontal)
                .onLongPressGesture(minimumDuration: 0.5) {
                    HapticFeedback.medium()
                    showingFullMorningInsight = true
                } onPressingChanged: { pressing in
                    isMorningInsightPressed = pressing
                }

            } else if let error = viewModel.morningInsightError {
                // Error state
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text(String(format: NSLocalizedString("dashboard.morning.insight.error.format", comment: "Could not create insight: %@"), error))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.orange.opacity(0.1))
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - AI Insights Section

    @available(iOS 26.0, *)
    var aiInsightsSection: some View {
        Group {
            if viewModel.isLoadingAI {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.purple)

                    Text(String(localized: "dashboard.ai.analyzing", comment: "AI analyzing"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)

            } else if let insight = viewModel.dailyInsight {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.caption)

                        Text(String(localized: "dashboard.ai.summary", comment: "AI summary"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            Task {
                                await viewModel.refreshAIInsights(context: modelContext)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                                .foregroundStyle(.purple.opacity(0.7))
                        }
                    }

                    Text(insight.summary)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text("⭐")
                                .font(.caption2)
                            Text(insight.topPriority)
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.yellow.opacity(0.12)))

                        Spacer(minLength: 4)

                        HStack(spacing: 4) {
                            Text("❤️")
                                .font(.caption2)
                            Text(insight.motivationMessage)
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.pink.opacity(0.12)))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .purple.opacity(0.3),
                                        .pink.opacity(0.2),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: .purple.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helper Functions

    private func loadDashboardData() {
        viewModel.loadDashboardData(context: modelContext)

        // Dashboard summary
        dashboardSummary = viewModel.getDashboardSummary(context: modelContext)

        // Partner info
        partnerInfo = viewModel.getPartnerInfo(context: modelContext)

        // Streak info
        streakInfo = viewModel.getStreakInfo(context: modelContext)

        // AI Insights (iOS 26+)
        if #available(iOS 26.0, *) {
            Task {
                await viewModel.loadAIInsights(context: modelContext)
            }
        }
    }

    private func callPartner(_ partner: PartnerInfo) {
        guard let phoneNumber = partner.phoneNumber else { return }
        if let url = URL(string: "tel://\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }

    private func messagePartner(_ partner: PartnerInfo) {
        guard let phoneNumber = partner.phoneNumber else { return }
        if let url = URL(string: "sms://\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }

    private func logPartnerContact() {
        // Partner ile iletişim kaydet
        // TODO: Implement contact logging
        print("Partner iletişim kaydedildi")
    }
}

// MARK: - Full Morning Insight Sheet

struct FullMorningInsightSheet: View {
    @Environment(\.dismiss) private var dismiss
    let insight: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Dekoratif header
                    HStack {
                        Image(systemName: "sun.horizon.fill")
                            .font(.largeTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Spacer()

                        Text("Claude Haiku")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.purple.opacity(0.1))
                            )
                    }

                    Divider()

                    // Tam içgörü metni
                    Text(insight)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "dashboard.morning.insight", comment: "Morning Insight"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.close", comment: "Close")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    DashboardViewNew()
        .modelContainer(for: [Friend.self, Goal.self, Habit.self, LocationLog.self])
}
