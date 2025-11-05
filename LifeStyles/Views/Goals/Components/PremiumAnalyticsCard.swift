//
//  PremiumAnalyticsCard.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Premium abonelik teşvik kartı - Gelişmiş analizler
//

import SwiftUI

struct PremiumAnalyticsCard: View {
    @State private var showingSubscription = false

    var body: some View {
        Button {
            showingSubscription = true
        } label: {
            VStack(spacing: 0) {
                // Premium Badge
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(String(localized: "premium.badge.title"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.1),
                            Color.orange.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: "premium.analytics.title"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(String(localized: "premium.analytics.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        PremiumFeatureRow(
                            icon: "chart.bar.fill",
                            title: String(localized: "premium.feature.advanced.charts"),
                            color: .blue
                        )

                        PremiumFeatureRow(
                            icon: "sparkles",
                            title: String(localized: "premium.feature.ai.insights"),
                            color: .purple
                        )

                        PremiumFeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: String(localized: "premium.feature.trend.analysis"),
                            color: .green
                        )

                        PremiumFeatureRow(
                            icon: "target",
                            title: String(localized: "premium.feature.goal.predictions"),
                            color: .orange
                        )
                    }

                    // CTA Button
                    HStack {
                        Spacer()

                        Text(String(localized: "premium.cta.start.trial"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())

                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSubscription) {
            PremiumSubscriptionView()
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}

#Preview {
    PremiumAnalyticsCard()
        .padding()
        .background(Color(.systemGroupedBackground))
}
