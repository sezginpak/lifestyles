//
//  MoodAnalyticsViewNew.swift
//  LifeStyles
//
//  Modern mood analytics with AI insights (Haiku powered)
//  Created by Claude on 25.10.2025.
//

import SwiftUI
import SwiftData

// MARK: - Mood Analytics View Model

@Observable
class MoodAnalyticsViewModel {
    // Services
    private let aiService = MoodAIServiceHaiku.shared

    // State
    var isLoadingAnalysis: Bool = false
    var aiAnalysis: MoodAnalysis?
    var error: Error?

    // MARK: - Load Analytics

    func loadAnalytics(entries: [MoodEntry], context: ModelContext) async {
        isLoadingAnalysis = true
        defer { isLoadingAnalysis = false }

        do {
            let analysis = await aiService.analyzeMoodData(entries: entries, context: context)
            await MainActor.run {
                self.aiAnalysis = analysis
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }

    func regenerateAnalysis(entries: [MoodEntry], context: ModelContext) async {
        // Clear cache
        aiService.clearCache()

        // Reload
        await loadAnalytics(entries: entries, context: context)
    }
}

// MARK: - Mood Analytics View (New)

struct MoodAnalyticsViewNew: View {
    let entries: [MoodEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = MoodAnalyticsViewModel()
    @State private var showShareSheet = false
    @State private var showPaywall = false

    // Premium kontrolü için PurchaseManager
    private var purchaseManager = PurchaseManager.shared

    init(entries: [MoodEntry]) {
        self.entries = entries
    }

    // Entries'in tarih aralığını hesapla
    private var dayRange: Int {
        guard let firstDate = entries.map({ $0.date }).min(),
              let lastDate = entries.map({ $0.date }).max() else {
            return 0
        }
        let days = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
        return days
    }

    // Premium kontrolü - 30+ gün premium gerektirir
    private var requiresPremium: Bool {
        return dayRange > 30
    }

    var body: some View {
        ScrollView {
            if requiresPremium && !purchaseManager.isPremium {
                // Premium paywall for 30+ days analytics
                premiumPaywallSection
            } else {
                VStack(spacing: Spacing.small) {
                    // Hero AI Insight Card - ULTRA KOMPAKT
                    MoodAIInsightCard(
                        analysis: viewModel.aiAnalysis,
                        isLoading: viewModel.isLoadingAnalysis,
                        onRegenerate: {
                            Task {
                                await viewModel.regenerateAnalysis(entries: entries, context: modelContext)
                            }
                        },
                        onShare: {
                            // Share functionality
                        }
                    )

                    // Mood Trend Chart - ULTRA KOMPAKT
                    MoodTrendChart(entries: entries)
                        .frame(height: 120) // Daha da küçült

                    // Detailed AI Insights (if available) - ULTRA KOMPAKT
                    if let analysis = viewModel.aiAnalysis, !viewModel.isLoadingAnalysis {
                        detailedInsightsSection(analysis)
                    }
                }
                .padding(Spacing.small)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mood Analizi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {
                        Task {
                            await viewModel.regenerateAnalysis(entries: entries, context: modelContext)
                        }
                    }) {
                        Label("Yeniden Analiz Et", systemImage: "arrow.clockwise")
                    }

                    Button(action: { showShareSheet = true }) {
                        Label("Paylaş", systemImage: "square.and.arrow.up")
                    }

                    Button(action: exportAnalytics) {
                        Label("Dışa Aktar", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            if viewModel.aiAnalysis == nil && !viewModel.isLoadingAnalysis {
                await viewModel.loadAnalytics(entries: entries, context: modelContext)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let analysis = viewModel.aiAnalysis {
                ShareSheet(items: [generateShareText(analysis)])
            }
        }
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
    }

    // MARK: - Detailed Insights Section

    private func detailedInsightsSection(_ analysis: MoodAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Section header - ULTRA KOMPAKT
            HStack {
                Text("Detaylı Analiz")
                    .font(.caption)
                    .fontWeight(.bold)

                Spacer()

                Text(analysis.generatedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }

            // Insights cards - ULTRA KOMPAKT (Max 2)
            if !analysis.insights.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Öne Çıkanlar")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(analysis.insights.prefix(2)) { insight in
                        insightDetailCard(insight)
                    }
                }
            }

            // Patterns cards - ULTRA KOMPAKT (Max 1)
            if !analysis.patterns.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pattern")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(analysis.patterns.prefix(1)) { pattern in
                        patternDetailCard(pattern)
                    }
                }
            }

            // Recommendations - ULTRA KOMPAKT (Max 2)
            if !analysis.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Öneriler")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(analysis.recommendations.prefix(2)) { recommendation in
                        recommendationDetailCard(recommendation)
                    }
                }
            }
        }
        .padding(Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func insightDetailCard(_ insight: AIInsight) -> some View {
        HStack(alignment: .top, spacing: 6) {
            // Icon - ULTRA KOMPAKT
            Image(systemName: insight.icon)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: insight.color) ?? .purple)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill((Color(hex: insight.color) ?? .purple).opacity(0.1))
                )

            // Content - ULTRA KOMPAKT
            Text(insight.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private func patternDetailCard(_ pattern: MoodPattern) -> some View {
        HStack(alignment: .top, spacing: 6) {
            // Emoji - ULTRA KOMPAKT
            Text(pattern.emoji)
                .font(.body)

            // Content - ULTRA KOMPAKT
            VStack(alignment: .leading, spacing: 2) {
                Text(pattern.title)
                    .font(.caption2)
                    .fontWeight(.semibold)

                Text(pattern.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            impactBadge(pattern.impact)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private func recommendationDetailCard(_ recommendation: ActionSuggestion) -> some View {
        HStack(spacing: 6) {
            // Icon - ULTRA KOMPAKT
            Image(systemName: recommendation.icon)
                .font(.system(size: 10))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            // Content - ULTRA KOMPAKT
            Text(recommendation.title)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 8))
                .foregroundStyle(.quaternary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private func impactBadge(_ impact: MoodPattern.PatternImpact) -> some View {
        HStack(spacing: 1) {
            Circle()
                .fill(impactColor(impact))
                .frame(width: 3, height: 3)

            Text(impactText(impact))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(impactColor(impact).opacity(0.1))
        )
    }

    private func impactColor(_ impact: MoodPattern.PatternImpact) -> Color {
        switch impact {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }

    private func impactText(_ impact: MoodPattern.PatternImpact) -> String {
        switch impact {
        case .positive: return "Pozitif"
        case .negative: return "Negatif"
        case .neutral: return "Nötr"
        }
    }

    // MARK: - Premium Paywall Section

    private var premiumPaywallSection: some View {
        VStack(spacing: Spacing.large) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Title & Description
            VStack(spacing: Spacing.small) {
                Text(String(localized: "mood.30plus.analysis", comment: "30+ Days Analysis"))
                    .font(.title2)
                    .fontWeight(.bold)

                Text(String(localized: "mood.premium.long.analysis", comment: "Premium long term analysis"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.large)
            }

            // Features
            VStack(alignment: .leading, spacing: Spacing.medium) {
                premiumFeatureRow(
                    icon: "calendar",
                    title: "Sınırsız Geçmiş",
                    description: "30+ günlük tüm mood verileriniz"
                )

                premiumFeatureRow(
                    icon: "brain.head.profile",
                    title: "Gelişmiş AI Analizi",
                    description: "Uzun dönem pattern'leri ve trendler"
                )

                premiumFeatureRow(
                    icon: "chart.bar.xaxis",
                    title: "Detaylı Raporlar",
                    description: "Kişiselleştirilmiş içgörüler ve öneriler"
                )
            }
            .padding(Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.relaxed, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            // CTA Button
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text(String(localized: "common.premium.upgrade", comment: "Upgrade to Premium"))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.medium)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }

            Spacer()
        }
        .padding(Spacing.large)
    }

    private func premiumFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    // MARK: - Actions

    private func exportAnalytics() {
        guard let analysis = viewModel.aiAnalysis else { return }

        // Generate CSV or JSON export
        let exportText = generateExportText(analysis)

        // Save to file
        let fileName = "mood_analytics_\(Date().formatted(.iso8601)).txt"
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent(fileName)

            do {
                try exportText.write(to: fileURL, atomically: true, encoding: .utf8)
                print("✅ Analytics exported to: \(fileURL.path)")

                // Show success message (you can add toast here)
            } catch {
                print("❌ Export failed: \(error)")
            }
        }
    }

    private func generateShareText(_ analysis: MoodAnalysis) -> String {
        var text = "📊 Mood Analytics\n\n"
        text += "📝 Özet:\n\(analysis.summary)\n\n"
        text += "📈 Haftalık Trend:\n\(analysis.weeklyTrend)\n\n"

        if !analysis.insights.isEmpty {
            text += "💡 Insight'lar:\n"
            for insight in analysis.insights {
                text += "• \(insight.description)\n"
            }
            text += "\n"
        }

        text += "Generated by LifeStyles App"

        return text
    }

    private func generateExportText(_ analysis: MoodAnalysis) -> String {
        var text = "MOOD ANALYTICS REPORT\n"
        text += "Generated: \(Date().formatted())\n"
        text += "="  + String(repeating: "=", count: 50) + "\n\n"

        text += "SUMMARY:\n\(analysis.summary)\n\n"
        text += "WEEKLY TREND:\n\(analysis.weeklyTrend)\n\n"

        if !analysis.insights.isEmpty {
            text += "INSIGHTS:\n"
            for (index, insight) in analysis.insights.enumerated() {
                text += "\(index + 1). \(insight.description)\n"
            }
            text += "\n"
        }

        if !analysis.patterns.isEmpty {
            text += "PATTERNS:\n"
            for (index, pattern) in analysis.patterns.enumerated() {
                text += "\(index + 1). \(pattern.title): \(pattern.description)\n"
            }
            text += "\n"
        }

        if !analysis.recommendations.isEmpty {
            text += "RECOMMENDATIONS:\n"
            for (index, rec) in analysis.recommendations.enumerated() {
                text += "\(index + 1). \(rec.title): \(rec.description)\n"
            }
            text += "\n"
        }

        text += "="  + String(repeating: "=", count: 50) + "\n"
        text += "End of Report\n"

        return text
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MoodAnalyticsViewNew(entries: [
            MoodEntry(date: Date().addingTimeInterval(-1 * 86400), moodType: .happy, intensity: 4),
            MoodEntry(date: Date().addingTimeInterval(-2 * 86400), moodType: .veryHappy, intensity: 5),
            MoodEntry(date: Date().addingTimeInterval(-3 * 86400), moodType: .neutral, intensity: 3),
            MoodEntry(date: Date().addingTimeInterval(-4 * 86400), moodType: .sad, intensity: 2),
            MoodEntry(date: Date().addingTimeInterval(-5 * 86400), moodType: .happy, intensity: 4),
            MoodEntry(date: Date().addingTimeInterval(-6 * 86400), moodType: .excited, intensity: 5),
            MoodEntry(date: Date().addingTimeInterval(-7 * 86400), moodType: .grateful, intensity: 4),
            MoodEntry(date: Date(), moodType: .veryHappy, intensity: 5)
        ])
    }
    .modelContainer(for: [MoodEntry.self], inMemory: true)
}
