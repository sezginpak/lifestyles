//
//  AIInsightCard.swift
//  LifeStyles
//
//  AI Insight card with streaming text animation
//  Created by Claude on 25.10.2025.
//

import SwiftUI

// MARK: - Mood AI Insight Card

struct MoodAIInsightCard: View {
    let analysis: MoodAnalysis?
    let isLoading: Bool
    let onRegenerate: () -> Void
    let onShare: () -> Void

    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    @State private var isAnimating: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            header

            // Content
            if isLoading {
                loadingState
            } else if let analysis = analysis {
                contentView(analysis: analysis)
            } else {
                emptyState
            }
        }
        .padding(Spacing.large)
        .glassmorphismCard(
            cornerRadius: CornerRadius.relaxed
        )
        .overlay(
            // Gradient border animation
            RoundedRectangle(cornerRadius: CornerRadius.relaxed, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.purple.opacity(0.5), .blue.opacity(0.5), .purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .opacity(isLoading ? 1 : 0)
        )
        .cardShadow()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: Spacing.small) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.variableColor.iterative, isActive: isLoading)

                Text(String(localized: "ai.analysis", comment: "AI Analysis"))
                    .cardTitle()
            }

            Spacer()

            // Action buttons
            if analysis != nil && !isLoading {
                HStack(spacing: Spacing.small) {
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }

                    Button(action: onRegenerate) {
                        Image(systemName: "arrow.clockwise")
                            .font(.callout)
                            .foregroundStyle(.purple)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                            )
                    }
                }
            }
        }
    }

    // MARK: - Content View

    private func contentView(analysis: MoodAnalysis) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Summary with streaming effect
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(isAnimating ? displayedText : analysis.summary)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(analysis.weeklyTrend)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )

            // Insights
            if !analysis.insights.isEmpty {
                insightsSection(analysis.insights)
            }

            // Recommendations
            if !analysis.recommendations.isEmpty {
                recommendationsSection(analysis.recommendations)
            }

            // Timestamp
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(String(format: NSLocalizedString("mood.generated.time", comment: "Generated time"), analysis.generatedAt.formatted(.relative(presentation: .named))))
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .onAppear {
            if !isAnimating {
                startStreamingAnimation(text: analysis.summary)
            }
        }
    }

    // MARK: - Insights Section

    private func insightsSection(_ insights: [AIInsight]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(String(localized: "mood.highlights", comment: "Highlights"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.small) {
                ForEach(insights.prefix(3)) { insight in
                    insightRow(insight)
                }
            }
        }
    }

    private func insightRow(_ insight: AIInsight) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Image(systemName: insight.icon)
                .font(.callout)
                .foregroundStyle(Color(hex: insight.color) ?? .purple)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill((Color(hex: insight.color) ?? .purple).opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                if !insight.title.isEmpty && insight.title != "Insight" {
                    Text(insight.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Text(insight.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.compact, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.5))
        )
    }

    // MARK: - Recommendations Section

    private func recommendationsSection(_ recommendations: [ActionSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(String(localized: "mood.recommendations", comment: "Recommendations"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.small) {
                ForEach(recommendations.prefix(3)) { recommendation in
                    recommendationRow(recommendation)
                }
            }
        }
    }

    private func recommendationRow(_ recommendation: ActionSuggestion) -> some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: recommendation.icon)
                .font(.body)
                .foregroundStyle(.purple)

            Text(recommendation.title)
                .font(.callout)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.compact, style: .continuous)
                .fill(Color.purple.opacity(0.05))
        )
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.large) {
            // Animated sparkles
            HStack(spacing: Spacing.small) {
                ForEach(0..<3) { index in
                    Image(systemName: "sparkle")
                        .font(.title2)
                        .foregroundStyle(.purple.opacity(0.7))
                        .symbolEffect(.pulse)
                        .animation(.easeInOut(duration: 1).repeatForever().delay(Double(index) * 0.2), value: isLoading)
                }
            }

            VStack(spacing: Spacing.small) {
                Text(String(localized: "ai.analyzing", comment: "AI Analyzing"))
                    .font(.callout)
                    .fontWeight(.medium)

                Text(String(localized: "mood.data.evaluating", comment: "Your mood data is being evaluated"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Loading bars
            VStack(spacing: Spacing.micro) {
                ForEach(0..<3) { index in
                    loadingBar(delay: Double(index) * 0.3)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    private func loadingBar(delay: Double) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: isLoading ? geometry.size.width : 0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(delay), value: isLoading)
                    , alignment: .leading
                )
        }
        .frame(height: 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundStyle(.purple.opacity(0.7))

            Text(String(localized: "mood.ai.analysis.ready", comment: "AI Analysis Ready"))
                .font(.callout)
                .fontWeight(.medium)

            Text(String(localized: "ai.analyze.mood", comment: "Let's analyze your mood data"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Analiz Oluştur") {
                onRegenerate()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    // MARK: - Streaming Animation

    private func startStreamingAnimation(text: String) {
        isAnimating = true
        displayedText = ""
        currentIndex = 0

        let words = text.components(separatedBy: " ")

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentIndex < words.count {
                displayedText += (currentIndex == 0 ? "" : " ") + words[currentIndex]
                currentIndex += 1
            } else {
                timer.invalidate()
                isAnimating = false
            }
        }
    }
}

// MARK: - Hero Variant (Larger, More Prominent)

struct MoodAIInsightHeroCard: View {
    let analysis: MoodAnalysis?
    let isLoading: Bool
    let onRegenerate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            if isLoading {
                heroLoadingState
            } else if let analysis = analysis {
                heroContent(analysis: analysis)
            } else {
                heroEmptyState
            }
        }
        .padding(Spacing.xlarge)
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.15),
                        Color.blue.opacity(0.15),
                        Color.pink.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Glassmorphism effect
                RoundedRectangle(cornerRadius: CornerRadius.rounded, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.rounded, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.purple.opacity(0.4), .blue.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.rounded, style: .continuous))
        .shadow(color: .purple.opacity(0.1), radius: 20, y: 10)
    }

    private func heroContent(analysis: MoodAnalysis) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Icon + Title
            HStack(spacing: Spacing.small) {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(String(localized: "ai.insight", comment: "AI Insight"))
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: onRegenerate) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
            }

            // Summary
            Text(analysis.summary)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(3)

            // Quick stats
            HStack(spacing: Spacing.large) {
                quickStat(icon: "lightbulb.fill", label: "\(analysis.insights.count) insight", color: .yellow)
                quickStat(icon: "chart.bar.fill", label: "\(analysis.patterns.count) pattern", color: .blue)
                quickStat(icon: "target", label: "\(analysis.recommendations.count) öneri", color: .green)
            }
        }
    }

    private func quickStat(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.micro) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var heroLoadingState: some View {
        VStack(spacing: Spacing.large) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)

            Text(String(localized: "ai.analyzing.mood", comment: "Analyzing your mood data..."))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var heroEmptyState: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundStyle(.purple.opacity(0.7))

            Text(String(localized: "mood.ai.analysis.ready", comment: "AI Analysis Ready"))
                .font(.title3)
                .fontWeight(.semibold)

            Button("Analiz Başlat") {
                onRegenerate()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Standard") {
    ScrollView {
        VStack(spacing: Spacing.large) {
            MoodAIInsightCard(
                analysis: MoodAnalysis(
                    summary: "Son günlerde genel olarak dengeli bir ruh hali sergiliyorsunuz. Pozitif anlar daha baskın.",
                    weeklyTrend: "Bu hafta mood'unuz hafif yükseliş eğiliminde.",
                    insights: [
                        AIInsight(title: "Pozitif Enerji", description: "Kayıtlarınızın %70'i pozitif mood içeriyor!", type: .positive, icon: "star.fill", color: "10B981"),
                        AIInsight(title: "Düzenli Takip", description: "Bu ay 12 kez mood kaydettiniz. Harika!", type: .neutral, icon: "chart.line.uptrend.xyaxis", color: "6366F1")
                    ],
                    patterns: [],
                    recommendations: [
                        ActionSuggestion(title: "Sabah Yürüyüşü", description: "Her sabah 15 dakika yürüyün", actionType: .activity, icon: "figure.walk"),
                        ActionSuggestion(title: "Arkadaş Görüşmesi", description: "Bu hafta bir arkadaşınızla buluşun", actionType: .social, icon: "person.2.fill")
                    ],
                    generatedAt: Date()
                ),
                isLoading: false,
                onRegenerate: {},
                onShare: {}
            )

            MoodAIInsightCard(
                analysis: nil,
                isLoading: true,
                onRegenerate: {},
                onShare: {}
            )
        }
        .padding()
    }
}

#Preview("Hero") {
    MoodAIInsightHeroCard(
        analysis: MoodAnalysis(
            summary: "Son günlerde genel olarak dengeli bir ruh hali sergiliyorsunuz.",
            weeklyTrend: "Bu hafta mood'unuz hafif yükseliş eğiliminde.",
            insights: [
                AIInsight(title: "Pozitif", description: "Test", type: .positive, icon: "star.fill", color: "10B981")
            ],
            patterns: [],
            recommendations: [
                ActionSuggestion(title: "Test", description: "Test", actionType: .activity, icon: "figure.walk")
            ],
            generatedAt: Date()
        ),
        isLoading: false,
        onRegenerate: {}
    )
    .padding()
}
