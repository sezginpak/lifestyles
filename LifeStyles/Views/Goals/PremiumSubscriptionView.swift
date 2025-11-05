//
//  PremiumSubscriptionView.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Premium abonelik satın alma ekranı
//

import SwiftUI

struct PremiumSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .monthly

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .yellow.opacity(0.3), radius: 20)

                        Text(String(localized: "premium.title"))
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(String(localized: "premium.subtitle"))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    // Features List
                    VStack(alignment: .leading, spacing: 20) {
                        PremiumFeatureCard(
                            icon: "chart.bar.fill",
                            title: String(localized: "premium.feature.advanced.charts"),
                            description: String(localized: "premium.feature.advanced.charts.desc"),
                            color: .blue
                        )

                        PremiumFeatureCard(
                            icon: "sparkles",
                            title: String(localized: "premium.feature.ai.insights"),
                            description: String(localized: "premium.feature.ai.insights.desc"),
                            color: .purple
                        )

                        PremiumFeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: String(localized: "premium.feature.trend.analysis"),
                            description: String(localized: "premium.feature.trend.analysis.desc"),
                            color: .green
                        )

                        PremiumFeatureCard(
                            icon: "target",
                            title: String(localized: "premium.feature.goal.predictions"),
                            description: String(localized: "premium.feature.goal.predictions.desc"),
                            color: .orange
                        )

                        PremiumFeatureCard(
                            icon: "icloud.fill",
                            title: String(localized: "premium.feature.unlimited.sync"),
                            description: String(localized: "premium.feature.unlimited.sync.desc"),
                            color: .cyan
                        )

                        PremiumFeatureCard(
                            icon: "bell.badge.fill",
                            title: String(localized: "premium.feature.smart.reminders"),
                            description: String(localized: "premium.feature.smart.reminders.desc"),
                            color: .red
                        )
                    }
                    .padding(.horizontal)

                    // Subscription Plans
                    VStack(spacing: 12) {
                        Text(String(localized: "premium.choose.plan"))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        SubscriptionPlanCard(
                            plan: .monthly,
                            isSelected: selectedPlan == .monthly
                        ) {
                            selectedPlan = .monthly
                        }

                        SubscriptionPlanCard(
                            plan: .yearly,
                            isSelected: selectedPlan == .yearly
                        ) {
                            selectedPlan = .yearly
                        }
                    }
                    .padding(.horizontal)

                    // CTA Button
                    VStack(spacing: 12) {
                        Button {
                            // TODO: Implement subscription purchase
                            HapticFeedback.success()
                        } label: {
                            Text(String(localized: "premium.cta.start.trial"))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Text(String(localized: "premium.trial.info"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            // TODO: Restore purchases
                        } label: {
                            Text(String(localized: "premium.restore.purchases"))
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(String(localized: "premium.navigation.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct PremiumFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

enum SubscriptionPlan {
    case monthly
    case yearly

    var title: String {
        switch self {
        case .monthly:
            return String(localized: "premium.plan.monthly")
        case .yearly:
            return String(localized: "premium.plan.yearly")
        }
    }

    var price: String {
        switch self {
        case .monthly:
            return "₺99,99"
        case .yearly:
            return "₺599,99"
        }
    }

    var period: String {
        switch self {
        case .monthly:
            return String(localized: "premium.period.month")
        case .yearly:
            return String(localized: "premium.period.year")
        }
    }

    var savings: String? {
        switch self {
        case .monthly:
            return nil
        case .yearly:
            return String(localized: "premium.savings.yearly")
        }
    }
}

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(plan.price) / \(plan.period)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PremiumSubscriptionView()
}
