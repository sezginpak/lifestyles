//
//  LimitReachedSheet.swift
//  LifeStyles
//
//  AI Usage Limit Reached Paywall
//  Created by Claude on 25.10.2025.
//

import SwiftUI

// MARK: - Limit Type

enum LimitType {
    case dailyInsight
    case activitySuggestion
    case goalSuggestion
    case chat

    var title: String {
        switch self {
        case .dailyInsight:
            return "Daily Insight Limiti"
        case .activitySuggestion:
            return "Aktivite Önerisi Limiti"
        case .goalSuggestion:
            return "Hedef Önerisi Limiti"
        case .chat:
            return "Chat Limiti"
        }
    }

    var icon: String {
        switch self {
        case .dailyInsight:
            return "sunrise.fill"
        case .activitySuggestion:
            return "figure.run"
        case .goalSuggestion:
            return "target"
        case .chat:
            return "message.fill"
        }
    }

    func message(isInTrial: Bool, trialDaysRemaining: Int) -> String {
        let softPrefix = String(localized: "limit.reached.soft.message")

        if isInTrial {
            let trialMessage = "\nDeneme sürenizde \(trialDaysRemaining) gün kaldı ve sınırsız erişiminiz var!"
            return softPrefix + trialMessage
        }

        switch self {
        case .dailyInsight:
            return softPrefix + "\nPremium ile sınırsız Daily Insight alabilirsiniz."
        case .activitySuggestion:
            return softPrefix + "\nPremium ile sınırsız aktivite önerisi alabilirsiniz."
        case .goalSuggestion:
            return softPrefix + "\nPremium ile sınırsız hedef önerisi alabilirsiniz."
        case .chat:
            return softPrefix + "\nPremium ile sınırsız AI sohbeti yapabilirsiniz."
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .dailyInsight:
            return [Color(red: 1.0, green: 0.75, blue: 0.4), Color(red: 1.0, green: 0.85, blue: 0.6)]
        case .activitySuggestion:
            return [.blue, .cyan]
        case .goalSuggestion:
            return [.purple, .pink]
        case .chat:
            return [.green, .mint]
        }
    }
}

// MARK: - Limit Reached Sheet

struct LimitReachedSheet: View {
    let limitType: LimitType
    @Environment(\.dismiss) private var dismiss
    @State private var showFullPaywall = false
    @State private var animateIcon = false
    @State private var purchaseManager = PurchaseManager.shared

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: limitType.gradientColors.map { $0.opacity(0.1) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: limitType.gradientColors.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: limitType.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: limitType.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: animateIcon)
                }
                .padding(.top, 20)

                // Title & Message
                VStack(spacing: 12) {
                    Text(limitType.title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text(limitType.message(
                        isInTrial: purchaseManager.isInTrial,
                        trialDaysRemaining: purchaseManager.trialDaysRemaining
                    ))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Trial Banner (if not started trial yet)
                if !purchaseManager.hasUserStartedTrial() && !purchaseManager.isInTrial {
                    TrialBanner()
                        .padding(.horizontal, 24)
                }

                // Usage Info
                UsageInfoCard(limitType: limitType)
                    .padding(.horizontal, 24)

                // Premium Features Preview
                VStack(spacing: 12) {
                    Text(String(localized: "premium.unlimited.usage", comment: "Unlimited Usage with Premium"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    VStack(spacing: 10) {
                        LimitFeatureRow(icon: "checkmark.circle.fill", text: "Sınırsız Daily Insights", color: .green)
                        LimitFeatureRow(icon: "checkmark.circle.fill", text: "Sınırsız AI Önerileri", color: .green)
                        LimitFeatureRow(icon: "checkmark.circle.fill", text: "Sınırsız Chat", color: .green)
                        LimitFeatureRow(icon: "checkmark.circle.fill", text: "Gelişmiş Analitikler", color: .green)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    // Upgrade Button
                    Button {
                        HapticFeedback.medium()
                        showFullPaywall = true
                    } label: {
                        HStack {
                            if !purchaseManager.hasUserStartedTrial() {
                                Image(systemName: "sparkles")
                                Text(String(localized: "premium.trial.3days"))
                                    .font(.headline)
                            } else {
                                Image(systemName: "crown.fill")
                                Text(String(localized: "premium.upgrade.button", comment: "Upgrade to Premium button"))
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                    }

                    // Dismiss Button
                    Button {
                        HapticFeedback.light()
                        dismiss()
                    } label: {
                        Text(String(localized: "premium.try.tomorrow", comment: "Try again tomorrow"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateIcon = true
            }
        }
        .sheet(isPresented: $showFullPaywall) {
            PremiumPaywallView()
        }
    }
}

// MARK: - Usage Info Card

struct UsageInfoCard: View {
    let limitType: LimitType
    @State private var usageManager = AIUsageManager.shared

    private var usageText: String {
        switch limitType {
        case .dailyInsight:
            return "1/1 kullanıldı"
        case .activitySuggestion:
            return "\(usageManager.todayActivitySuggestionCount)/3 kullanıldı"
        case .goalSuggestion:
            return "\(usageManager.todayGoalSuggestionCount)/3 kullanıldı"
        case .chat:
            return "\(usageManager.todayMessageCount)/5 kullanıldı"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "premium.todays.usage", comment: "Today's Usage"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(usageText)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(localized: "premium.reset", comment: "Reset"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(String(localized: "premium.tomorrow.midnight", comment: "Tomorrow at midnight"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Feature Row

struct LimitFeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}

// MARK: - Trial Banner

struct TrialBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "premium.trial.3days"))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(String(localized: "premium.price.after.trial"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "arrow.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(.blue)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview

#Preview("Daily Insight Limit") {
    LimitReachedSheet(limitType: .dailyInsight)
}

#Preview("Activity Suggestion Limit") {
    LimitReachedSheet(limitType: .activitySuggestion)
}

#Preview("Goal Suggestion Limit") {
    LimitReachedSheet(limitType: .goalSuggestion)
}

#Preview("Chat Limit") {
    LimitReachedSheet(limitType: .chat)
}
