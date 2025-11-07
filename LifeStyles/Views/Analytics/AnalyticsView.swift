//
//  AnalyticsView.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import SwiftUI
import SwiftData

/// Ana analytics view
struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AnalyticsViewModel()
    @State private var showingPremiumSheet = false

    private var premiumManager: PremiumManager {
        PremiumManager.shared
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                // Content
                Group {
                    switch viewModel.viewState {
                    case .loading:
                        AnalyticsSkeletonView()
                    case .loaded:
                        contentView
                    case .error(let message):
                        errorView(message: message)
                    case .empty:
                        emptyView
                    }
                }
            }
            .navigationTitle(String(localized: "analytics.main.title", defaultValue: "Analizler", comment: "Analytics view navigation title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await viewModel.refreshData(context: modelContext)
                            }
                        } label: {
                            Label(String(localized: "analytics.main.refresh_button", defaultValue: "Yenile", comment: "Refresh button label"), systemImage: "arrow.clockwise")
                        }

                        Button {
                            viewModel.showExportSheet = true
                        } label: {
                            Label(String(localized: "analytics.main.create_report_button", defaultValue: "Rapor Oluştur", comment: "Create report button label"), systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Picker(String(localized: "analytics.main.time_range_picker", defaultValue: "Zaman Aralığı", comment: "Time range picker label"), selection: $viewModel.selectedTimeRange) {
                            ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                                Text(range.localizedTitle).tag(range)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                exportSheet
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumSubscriptionView()
            }
            .task {
                if viewModel.viewState == .loading {
                    await viewModel.loadData(context: modelContext)
                }
            }
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Last refresh info
                if let lastRefresh = viewModel.lastRefreshDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text(String(localized: "analytics.main.last_update", defaultValue: "Son güncelleme: \(lastRefresh, format: .relative(presentation: .named))", comment: "Last refresh timestamp"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                // Overview Section
                if let overview = viewModel.overviewData {
                    OverviewSection(data: overview)
                        .padding(.horizontal)
                }

                // Social Analytics
                if let social = viewModel.socialData {
                    SocialAnalyticsSection(data: social)
                        .padding(.horizontal)
                }

                // Mood Analytics
                if let mood = viewModel.moodData {
                    MoodAnalyticsSection(data: mood)
                        .padding(.horizontal)
                }

                // Mood Correlations (Friend, Goal, Location)
                if !viewModel.friendCorrelations.isEmpty ||
                   !viewModel.goalCorrelations.isEmpty ||
                   !viewModel.locationCorrelations.isEmpty {
                    moodCorrelationsSection
                }

                // Goal Analytics (mini version)
                if let goals = viewModel.goalData {
                    goalSection(goals)
                }

                // Habit Analytics (mini version)
                if let habits = viewModel.habitData {
                    habitSection(habits)
                }

                // Location Analytics (mini version)
                if let location = viewModel.locationData {
                    locationSection(location)
                }

                // Correlations - PREMIUM
                if let correlations = viewModel.correlationData {
                    correlationSection(correlations)
                        .premiumLocked(
                            !premiumManager.isPremium,
                            title: String(localized: "premium.feature.trend.analysis")
                        ) {
                            showingPremiumSheet = true
                        }
                }

                // AI Insights (iOS 26+) - PREMIUM
                if viewModel.isAIAvailable {
                    if #available(iOS 26.0, *) {
                        AIInsightsSection(
                            insights: viewModel.aiInsights,
                            patterns: viewModel.detectedPatterns,
                            predictions: viewModel.predictions,
                            friendCorrelations: viewModel.friendMoodCorrelations
                        )
                        .padding(.horizontal)
                        .premiumLocked(
                            !premiumManager.isPremium,
                            title: String(localized: "premium.feature.ai.insights")
                        ) {
                            showingPremiumSheet = true
                        }
                    }
                }

                // Bottom spacing
                Color.clear.frame(height: 20)
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.refreshData(context: modelContext)
        }
    }

    @ViewBuilder
    private func goalSection(_ data: GoalPerformanceAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(.green)
                Text(String(localized: "analytics.main.goal_performance_title", defaultValue: "Hedef Performansı", comment: "Goal performance section title"))
                    .font(.title2.weight(.bold))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.goal_completed", defaultValue: "Tamamlanan", comment: "Completed goals card title"),
                    value: "\(data.completedGoals)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.goal_success_rate", defaultValue: "Başarı Oranı", comment: "Success rate card title"),
                    value: "%\(Int(data.completionRate * 100))",
                    icon: "chart.bar.fill",
                    color: .blue
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.goal_active", defaultValue: "Aktif Hedef", comment: "Active goals card title"),
                    value: "\(data.activeGoals)",
                    icon: "flag.fill",
                    color: .orange
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.goal_upcoming", defaultValue: "Yaklaşan", comment: "Upcoming deadlines card title"),
                    value: "\(data.upcomingDeadlines)",
                    icon: "calendar.badge.exclamationmark",
                    color: .red
                )
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func habitSection(_ data: HabitPerformanceAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "repeat")
                    .foregroundStyle(.purple)
                Text(String(localized: "analytics.main.habit_performance_title", defaultValue: "Alışkanlık Performansı", comment: "Habit performance section title"))
                    .font(.title2.weight(.bold))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.habit_total", defaultValue: "Toplam", comment: "Total habits card title"),
                    value: "\(data.totalHabits)",
                    icon: "list.bullet",
                    color: .purple
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.habit_best_streak", defaultValue: "En Uzun Seri", comment: "Best streak card title"),
                    value: "\(data.bestStreak)",
                    icon: "flame.fill",
                    color: .orange
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.habit_completion", defaultValue: "Tamamlanma", comment: "Completion rate card title"),
                    value: "%\(Int(data.averageCompletionRate * 100))",
                    icon: "checkmark.seal.fill",
                    color: .green
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.habit_active", defaultValue: "Aktif", comment: "Active habits card title"),
                    value: "\(data.activeHabits)",
                    icon: "bolt.fill",
                    color: .yellow
                )
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func locationSection(_ data: LocationAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(.red)
                Text(String(localized: "analytics.main.location_title", defaultValue: "Mobilite & Konum", comment: "Location section title"))
                    .font(.title2.weight(.bold))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.location_unique_places", defaultValue: "Benzersiz Yer", comment: "Unique places card title"),
                    value: "\(data.uniquePlaces)",
                    icon: "mappin.circle.fill",
                    color: .red
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.main.location_mobility_score", defaultValue: "Mobilite Skoru", comment: "Mobility score card title"),
                    value: "\(Int(data.mobilityScore))",
                    icon: "figure.walk",
                    color: .green
                )

                if let mostVisited = data.mostVisitedPlace {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .frame(width: 36, height: 36)
                            .background(.yellow.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "analytics.main.location_most_visited", defaultValue: "En Çok Ziyaret", comment: "Most visited place label"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(mostVisited)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var moodCorrelationsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(.pink)
                Text(String(localized: "analytics.mood.correlations_title", defaultValue: "Ruh Hali Korelasyonları", comment: "Mood correlations section title"))
                    .font(.title2.weight(.bold))
            }
            .padding(.horizontal)

            // Friend Correlations
            if !viewModel.friendCorrelations.isEmpty {
                FriendCorrelationSection(correlations: viewModel.friendCorrelations)
                    .padding(.horizontal)
            }

            // Goal Correlations
            if !viewModel.goalCorrelations.isEmpty {
                GoalCorrelationSection(correlations: viewModel.goalCorrelations)
                    .padding(.horizontal)
            }

            // Location Correlations
            if !viewModel.locationCorrelations.isEmpty {
                LocationCorrelationSection(correlations: viewModel.locationCorrelations)
                    .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func correlationSection(_ data: CorrelationData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(.blue)
                Text(String(localized: "analytics.main.correlation_title", defaultValue: "Veri Korelasyonları", comment: "Correlation section title"))
                    .font(.title2.weight(.bold))
            }

            CorrelationMatrix(
                title: String(localized: "analytics.main.correlation_relationships", defaultValue: "Faktörler Arası İlişkiler", comment: "Correlation matrix title"),
                correlations: [
                    CorrelationMatrix.CorrelationItem(
                        label1: String(localized: "analytics.main.correlation_mood", defaultValue: "Ruh Hali", comment: "Mood label"),
                        label2: String(localized: "analytics.main.correlation_contacts", defaultValue: "İletişim", comment: "Contacts label"),
                        value: data.moodVsContacts,
                        description: String(localized: "analytics.main.correlation_mood_contacts_desc", defaultValue: "Arkadaşlarla görüşmek ruh halini etkiliyor", comment: "Mood-contacts correlation description")
                    ),
                    CorrelationMatrix.CorrelationItem(
                        label1: String(localized: "analytics.main.correlation_mood", defaultValue: "Ruh Hali", comment: "Mood label"),
                        label2: String(localized: "analytics.main.correlation_goals", defaultValue: "Hedefler", comment: "Goals label"),
                        value: data.moodVsGoals,
                        description: String(localized: "analytics.main.correlation_mood_goals_desc", defaultValue: "Hedef tamamlamak mutluluk veriyor", comment: "Mood-goals correlation description")
                    ),
                    CorrelationMatrix.CorrelationItem(
                        label1: String(localized: "analytics.main.correlation_mood", defaultValue: "Ruh Hali", comment: "Mood label"),
                        label2: String(localized: "analytics.main.correlation_location", defaultValue: "Konum", comment: "Location label"),
                        value: data.moodVsLocation,
                        description: String(localized: "analytics.main.correlation_mood_location_desc", defaultValue: "Dışarıda olmak ruh halini iyileştiriyor", comment: "Mood-location correlation description")
                    )
                ]
            )
        }
        .padding(.horizontal)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text(String(localized: "analytics.main.loading_message", defaultValue: "Analizler hazırlanıyor...", comment: "Loading message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text(String(localized: "analytics.main.error_title", defaultValue: "Hata Oluştu", comment: "Error title"))
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(String(localized: "analytics.main.error_retry_button", defaultValue: "Yeniden Dene", comment: "Retry button label")) {
                Task {
                    await viewModel.loadData(context: modelContext)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(String(localized: "analytics.main.empty_title", defaultValue: "Henüz Veri Yok", comment: "Empty state title"))
                    .font(.headline)

                Text(String(localized: "analytics.main.empty_message", defaultValue: "Uygulamayı kullanmaya başladığınızda burada analizlerinizi görebileceksiniz.", comment: "Empty state message"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    @ViewBuilder
    private var exportSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text(String(localized: "analytics.main.export_sheet_title", defaultValue: "Analytics Raporu", comment: "Export sheet title"))
                    .font(.title2.weight(.bold))

                Text(String(localized: "analytics.main.export_sheet_message", defaultValue: "Tüm analytics verileriniz bir rapor olarak dışa aktarılacak.", comment: "Export sheet message"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Divider()

                Button {
                    if let url = viewModel.saveReportToFile() {
                        // Share sheet
                        let activityVC = UIActivityViewController(
                            activityItems: [url],
                            applicationActivities: nil
                        )

                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            rootVC.present(activityVC, animated: true)
                        }

                        viewModel.showExportSheet = false
                    }
                } label: {
                    Label(String(localized: "analytics.main.export_button", defaultValue: "Raporu Dışa Aktar", comment: "Export report button label"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Button(String(localized: "analytics.main.export_cancel_button", defaultValue: "İptal", comment: "Cancel export button label")) {
                    viewModel.showExportSheet = false
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle(String(localized: "analytics.main.export_nav_title", defaultValue: "Dışa Aktar", comment: "Export navigation title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
        .modelContainer(for: [
            Friend.self,
            MoodEntry.self,
            Goal.self,
            Habit.self,
            LocationLog.self
        ])
}
