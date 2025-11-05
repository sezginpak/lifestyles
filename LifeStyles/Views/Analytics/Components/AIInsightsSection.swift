//
//  AIInsightsSection.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import SwiftUI

/// AI içgörüleri section
@available(iOS 26.0, *)
struct AIInsightsSection: View {
    let insights: [AnalyticsAIInsight]
    let patterns: [AnalyticsDetectedPattern]
    let predictions: [AnalyticsPredictiveInsight]
    let friendCorrelations: [AnalyticsFriendMoodCorrelation]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(String(localized: "analytics.ai.title", defaultValue: "AI İçgörüleri", comment: "AI insights section title"))
                    .font(.title2.weight(.bold))

                Spacer()

                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
            }

            // AI Insights
            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "analytics.ai.smart_insights", defaultValue: "💡 Akıllı İçgörüler", comment: "Smart insights subsection title"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(insights) { insight in
                        insightCard(insight)
                    }
                }
            }

            // Detected Patterns
            if !patterns.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "analytics.ai.detected_patterns", defaultValue: "🔍 Tespit Edilen Pattern'ler", comment: "Detected patterns subsection title"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(patterns) { pattern in
                        patternCard(pattern)
                    }
                }
            }

            // Predictions
            if !predictions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "analytics.ai.predictions", defaultValue: "🔮 Tahminler", comment: "Predictions subsection title"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(predictions) { prediction in
                        predictionCard(prediction)
                    }
                }
            }

            // Friend-Mood Correlations
            if !friendCorrelations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "analytics.ai.friend_mood_correlations", defaultValue: "👥 Arkadaş-Ruh Hali Korelasyonları", comment: "Friend-mood correlations subsection title"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(friendCorrelations.prefix(5), id: \.friendName) { correlation in
                        friendCorrelationCard(correlation)
                    }
                }
            }

            // Empty state
            if insights.isEmpty && patterns.isEmpty && predictions.isEmpty {
                emptyAIState
            }
        }
    }

    @ViewBuilder
    private func insightCard(_ insight: AnalyticsAIInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: categoryIcon(insight.category))
                    .font(.title2)
                    .foregroundStyle(categoryColor(insight.category))
                    .frame(width: 44, height: 44)
                    .background(categoryColor(insight.category).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(insight.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Confidence badge
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor(insight.category))
                    .clipShape(Capsule())
            }

            // Suggested action
            if insight.actionable, let action = insight.suggestedAction {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)

                    Text(action)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func patternCard(_ pattern: AnalyticsDetectedPattern) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.description)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        Label(pattern.frequency, systemImage: "clock")
                        Label(String(localized: "analytics.pattern.strength_percent", defaultValue: "\(Int(pattern.strength * 100))% güçlü", comment: "Pattern strength percentage"), systemImage: "chart.bar.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Examples
            if !pattern.examples.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(pattern.examples, id: \.self) { example in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 6, height: 6)

                            Text(example)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func predictionCard(_ prediction: AnalyticsPredictiveInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "crystal.ball.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .background(.blue.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(prediction.prediction)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Label(prediction.timeframe, systemImage: "calendar")
                        Label(String(localized: "analytics.prediction.confidence_percent", defaultValue: "\(Int(prediction.confidence * 100))% güven", comment: "Prediction confidence percentage"), systemImage: "checkmark.seal.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // Recommendation
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)

                        Text(prediction.recommendation)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func friendCorrelationCard(_ correlation: AnalyticsFriendMoodCorrelation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(correlation.friendName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(correlation.insight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", correlation.correlationScore))
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(correlationColor(correlation.correlationScore))

                    Text(String(localized: "analytics.ai.correlation_label", defaultValue: "korelasyon", comment: "Correlation label"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    correlationColor(correlation.correlationScore).opacity(0.6),
                                    correlationColor(correlation.correlationScore)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(abs(correlation.correlationScore)),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyAIState: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text(String(localized: "analytics.ai.empty_title", defaultValue: "AI Analizleri Yükleniyor", comment: "Empty state title for AI insights"))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(String(localized: "analytics.ai.empty_message", defaultValue: "Verileriniz analiz ediliyor. Biraz sonra içgörüler burada görünecek.", comment: "Empty state message for AI insights"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // Helper functions
    private func categoryIcon(_ category: AnalyticsAIInsight.InsightCategory) -> String {
        switch category {
        case .social: return "person.2.fill"
        case .mood: return "face.smiling.fill"
        case .productivity: return "checkmark.circle.fill"
        case .wellness: return "heart.fill"
        case .pattern: return "waveform.path.ecg"
        }
    }

    private func categoryColor(_ category: AnalyticsAIInsight.InsightCategory) -> Color {
        switch category {
        case .social: return .blue
        case .mood: return .orange
        case .productivity: return .green
        case .wellness: return .red
        case .pattern: return .purple
        }
    }

    private func correlationColor(_ value: Double) -> Color {
        if value > 0.6 {
            return .green
        } else if value > 0.3 {
            return .blue
        } else if value > 0 {
            return .gray
        } else if value > -0.3 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    if #available(iOS 26.0, *) {
        ScrollView {
            AIInsightsSection(
                insights: [
                    AnalyticsAIInsight(
                        title: "Pozitif Sosyal Etki",
                        description: "Ahmet ile daha fazla zaman geçirmeyi düşünün",
                        category: .social,
                        confidence: 0.85,
                        actionable: true,
                        suggestedAction: "Ahmet'e mesaj gönderin"
                    )
                ],
                patterns: [
                    AnalyticsDetectedPattern(
                        patternType: .weeklyMoodCycle,
                        description: "Haftalık ruh hali döngüsü tespit edildi",
                        frequency: "Haftalık",
                        strength: 0.75,
                        examples: ["En iyi günleriniz: Cuma", "En zorlu günleriniz: Pazartesi"]
                    )
                ],
                predictions: [
                    AnalyticsPredictiveInsight(
                        prediction: "Önümüzdeki hafta ruh halinizin yüksek kalması bekleniyor",
                        confidence: 0.75,
                        timeframe: "Önümüzdeki hafta",
                        basedOn: ["Son 7 günlük mood trendi", "Sosyal aktivite düzeyi"],
                        recommendation: "Bu pozitif enerjiyi yeni hedefler için kullanın!"
                    )
                ],
                friendCorrelations: [
                    AnalyticsFriendMoodCorrelation(
                        friendName: "Ahmet Yılmaz",
                        correlationScore: 0.75,
                        positiveInteractions: 12,
                        negativeInteractions: 2,
                        averageMoodAfterContact: 4.5,
                        insight: "Ahmet ile görüşmeler genellikle ruh halinizi olumlu etkiliyor! 😊"
                    )
                ]
            )
            .padding()
        }
    }
}
