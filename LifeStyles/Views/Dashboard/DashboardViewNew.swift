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
    @State private var showingFullDailyInsight = false
    @State private var showConfetti = false
    @State private var selectedSuggestion: GoalSuggestion?

    // Computed data
    @State private var dashboardSummary: DashboardSummary = .empty()
    @State private var partnerInfo: PartnerInfo? = nil
    @State private var streakInfo: StreakInfo = .empty()

    // Navigation states (YENİ)
    @State private var selectedTab: Int? = nil
    @State private var showingAddGoalSheet = false
    @State private var showingAddHabitSheet = false
    @State private var goalsViewModel = GoalsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Hero Stats Card (4 Ring)
                    HeroStatsCard(summary: dashboardSummary)
                        .padding(.horizontal)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Dashboard özet kartı")

                    // 1.5. Trial Countdown Widget (if trial active)
                    TrialCountdownWidget()
                        .padding(.horizontal)

                    // 2. Mood Widget
                    DashboardMoodWidget()

                    // 2.5. Daily Insight (Claude Haiku) - Sabah/Öğle/Akşam dinamik
                    dailyInsightSection

                    // 3. Partner Card (Varsa)
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
            }
            .refreshable {
                await viewModel.refreshAll(context: modelContext)

                // Computed data'ları güncelle - refreshAll tamamlandıktan sonra
                await MainActor.run {
                    dashboardSummary = viewModel.getDashboardSummary(context: modelContext)
                    partnerInfo = viewModel.getPartnerInfo(context: modelContext)
                    streakInfo = viewModel.getStreakInfo(context: modelContext)
                }

                HapticFeedback.success()
            }
            .background(Color(.systemGroupedBackground))
            .overlay(alignment: .bottomTrailing) {
                // Floating AI Chat Button
                NavigationLink(destination: GeneralAIChatView()) {
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
                            .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)

                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .simultaneousGesture(TapGesture().onEnded {
                    HapticFeedback.medium()
                })
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("LifeStyles")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingFullDailyInsight) {
                if let insight = viewModel.dailyInsightText {
                    FullDailyInsightSheet(
                        insight: insight,
                        timeOfDay: viewModel.dailyInsightTimeOfDay
                    )
                }
            }
            .sheet(isPresented: $viewModel.showLimitReachedSheet) {
                if let limitType = viewModel.limitReachedType {
                    LimitReachedSheet(limitType: limitType)
                }
            }
            .sheet(isPresented: $showingAddGoalSheet) {
                AddGoalView(viewModel: goalsViewModel, modelContext: modelContext)
            }
            .sheet(isPresented: $showingAddHabitSheet) {
                AddHabitView(viewModel: goalsViewModel, modelContext: modelContext)
            }
            .task {
                // Async olarak veri yükle
                await loadDashboardData()
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // Tab değiştiğinde ContentView'a bildir (TODO: Environment ile implement edilecek)
                if let tab = newValue {
                    NotificationCenter.default.post(name: NSNotification.Name("ChangeTab"), object: tab)
                }
            }
        }
    }

    // MARK: - Computed Properties for Card Data

    private var goalsCardData: CompactStatData {
        CompactStatData(
            icon: "target",
            title: String(localized: "dashboard.stats.goals", comment: "Goals"),
            color: "667EEA",
            mainValue: "%\(Int(viewModel.goalCompletionRate * 100))",
            subValue: String(
                localized: "dashboard.stats.completion",
                comment: "Completion"
            ),
            progressValue: viewModel.goalCompletionRate,
            badge: viewModel.overdueGoals > 0
                ? String(
                    format: NSLocalizedString(
                        "dashboard.stats.overdue.format",
                        comment: "X overdue"
                    ),
                    viewModel.overdueGoals
                )
                : nil,
            trendData: viewModel.getGoalsTrendData(context: modelContext),
            destination: .goals,
            quickActions: [
                QuickAction(icon: "plus", color: "667EEA", action: .addGoal)
            ]
        )
    }

    private var communicationCardData: CompactStatData {
        CompactStatData(
            icon: "person.2.fill",
            title: String(
                localized: "dashboard.stats.communication",
                comment: "Communication"
            ),
            color: "3498DB",
            mainValue: "\(viewModel.contactsThisWeek)",
            subValue: String(
                localized: "dashboard.stats.this.week",
                comment: "This week"
            ),
            progressValue: nil,
            badge: viewModel.contactTrendPercentage != 0
                ? "\(viewModel.contactTrendPercentage >= 0 ? "+" : "")\(Int(viewModel.contactTrendPercentage))%"
                : nil,
            trendData: viewModel.getContactsTrendData(context: modelContext),
            destination: .friends,
            quickActions: partnerInfo != nil
                ? [QuickAction(icon: "phone.fill", color: "3498DB", action: .callPartner)]
                : nil
        )
    }

    private var habitsCardData: CompactStatData {
        let completionRate = viewModel.totalHabitsToday > 0
            ? Double(viewModel.completedHabitsToday) / Double(viewModel.totalHabitsToday)
            : 0

        return CompactStatData(
            icon: "flame.fill",
            title: String(localized: "dashboard.stats.habits", comment: "Habits"),
            color: "E74C3C",
            mainValue: "\(viewModel.completedHabitsToday)/\(viewModel.totalHabitsToday)",
            subValue: String(localized: "dashboard.stats.today", comment: "Today"),
            progressValue: completionRate,
            badge: String(
                format: NSLocalizedString(
                    "dashboard.stats.weekly.format",
                    comment: "X% weekly"
                ),
                Int(viewModel.weeklyHabitCompletionRate * 100)
            ),
            trendData: viewModel.getHabitsTrendData(context: modelContext),
            destination: .habits,
            quickActions: [
                QuickAction(icon: "checkmark", color: "E74C3C", action: .completeHabit)
            ]
        )
    }

    private var mobilityCardData: CompactStatData {
        CompactStatData(
            icon: "location.fill",
            title: String(localized: "dashboard.stats.mobility", comment: "Mobility"),
            color: "2ECC71",
            mainValue: "\(viewModel.mobilityScore)",
            subValue: String(localized: "dashboard.stats.score", comment: "Score"),
            progressValue: Double(viewModel.mobilityScore) / 100.0,
            badge: String(
                format: NSLocalizedString(
                    "dashboard.stats.locations.format",
                    comment: "X locations"
                ),
                viewModel.uniqueLocationsThisWeek
            ),
            trendData: viewModel.getMobilityTrendData(context: modelContext),
            destination: .location,
            quickActions: [
                QuickAction(icon: "mappin.and.ellipse", color: "2ECC71", action: .logLocation)
            ]
        )
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
                    data: goalsCardData,
                    onTap: {
                        selectedTab = 3 // Goals tab
                    },
                    onQuickAction: { action in
                        handleQuickAction(action)
                    }
                )

                // İletişim
                DashboardCompactStatCard(
                    data: communicationCardData,
                    onTap: {
                        selectedTab = 1 // Friends tab
                    },
                    onQuickAction: { action in
                        handleQuickAction(action)
                    }
                )

                // Alışkanlıklar
                DashboardCompactStatCard(
                    data: habitsCardData,
                    onTap: {
                        selectedTab = 3 // Goals tab (habits are there)
                    },
                    onQuickAction: { action in
                        handleQuickAction(action)
                    }
                )

                // Mobilite
                DashboardCompactStatCard(
                    data: mobilityCardData,
                    onTap: {
                        selectedTab = 2 // Location tab
                    },
                    onQuickAction: { action in
                        handleQuickAction(action)
                    }
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Smart Suggestions

    var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Akıllı Öneriler")
                    .font(.title3.bold())

                Spacer()

                // AI Yenile Butonu
                Button {
                    HapticFeedback.light()
                    Task {
                        await viewModel.loadAISuggestions(context: modelContext)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                        Text("AI")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.purple.opacity(0.15))
                    )
                }
            }
            .padding(.horizontal)

            // Suggestion Cards
            VStack(spacing: 16) {
                ForEach(Array(viewModel.smartGoalSuggestions.prefix(3).enumerated()), id: \.element.id) { index, suggestion in
                    SmartSuggestionCard(
                        suggestion: suggestion,
                        progress: viewModel.getAcceptedSuggestionProgress(
                            for: suggestion.title,
                            context: modelContext
                        ),
                        onAccept: {
                            // Confetti animation
                            showConfetti = true

                            // Accept
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                viewModel.acceptSuggestion(suggestion, context: modelContext)
                            }
                        },
                        onDismiss: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                viewModel.dismissSuggestion(suggestion, context: modelContext)
                            }
                        },
                        onTap: {
                            // TODO: Öneri detay sayfası eklenecek
                            print("📌 Öneri tıklandı: \(suggestion.title)")
                        }
                    )
                    .padding(.horizontal)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
        }
        .confetti(isPresented: $showConfetti, count: 30)
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

    // MARK: - Daily Insight Section (Yeni Tasarım)

    @ViewBuilder
    var dailyInsightSection: some View {
        if viewModel.isLoadingDailyInsight {
                // Modern loading card
                DailyInsightCard(
                    insight: "",
                    timeOfDay: viewModel.dailyInsightTimeOfDay,
                    isLoading: true
                )
                .padding(.horizontal)

            } else if let insight = viewModel.dailyInsightText {
                // Modern Daily Insight kartı
                DailyInsightCard(
                    insight: insight,
                    timeOfDay: viewModel.dailyInsightTimeOfDay,
                    onRefresh: {
                        await viewModel.refreshDailyInsight(context: modelContext)
                    },
                    onExpand: {
                        showingFullDailyInsight = true
                    }
                )
                .padding(.horizontal)

            } else if let error = viewModel.dailyInsightError {
                // Error state (kompakt)
                HStack(spacing: Spacing.small) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.callout)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "insight.could.not.generate", comment: "Could not generate insight"))
                            .font(.subheadline.weight(.medium))

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button("Tekrar Dene") {
                        Task {
                            await viewModel.refreshDailyInsight(context: modelContext)
                        }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
                }
                .padding(Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.normal)
                        .fill(.orange.opacity(0.1))
                )
                .padding(.horizontal)
        } else {
            EmptyView()
        }
    }

    // MARK: - Quick Action Handler

    private func handleQuickAction(_ action: QuickAction) {
        switch action.action {
        case .addGoal:
            showingAddGoalSheet = true
        case .callPartner:
            if let partner = partnerInfo {
                callPartner(partner)
            }
        case .completeHabit:
            showingAddHabitSheet = true // TODO: Bugünün alışkanlıklarını göster
        case .logLocation:
            selectedTab = 2 // Location tab'e git
        case .custom(let customAction):
            customAction()
        }
    }

    // MARK: - Helper Functions

    @MainActor
    private func loadDashboardData() async {
        // ViewModel'deki veri yükleme fonksiyonunu çağır
        await viewModel.loadDashboardDataAsync(context: modelContext)

        // Computed data'ları güncelle
        dashboardSummary = viewModel.getDashboardSummary(context: modelContext)
        partnerInfo = viewModel.getPartnerInfo(context: modelContext)
        streakInfo = viewModel.getStreakInfo(context: modelContext)
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

                        Text(String(localized: "dashboard.claude.haiku", comment: "Claude Haiku model name"))
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
