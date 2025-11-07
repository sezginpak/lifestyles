//
//  SocialAnalyticsSection.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import SwiftUI
import Charts

/// Sosyal/iletişim analytics section
struct SocialAnalyticsSection: View {
    let data: SocialAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text(String(localized: "analytics.social.title", defaultValue: "İletişim Analizleri", comment: "Social analytics section title"))
                    .font(.title2.weight(.bold))
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AnalyticsMiniCard(
                    title: String(localized: "analytics.social.totalContacts", defaultValue: "Toplam Kişi", comment: "Total contacts title"),
                    value: "\(data.totalContacts)",
                    icon: "person.2.fill",
                    color: .blue
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.social.active", defaultValue: "Aktif", comment: "Active contacts title"),
                    value: "\(data.activeContacts)",
                    icon: "person.wave.2.fill",
                    color: .green
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.social.needsAttention", defaultValue: "Dikkat Gerekli", comment: "Needs attention title"),
                    value: "\(data.needsAttentionCount)",
                    icon: "exclamationmark.circle.fill",
                    color: .orange
                )

                AnalyticsMiniCard(
                    title: String(localized: "analytics.social.responseRate", defaultValue: "Yanıt Oranı", comment: "Response rate title"),
                    value: "%\(Int(data.responseRate * 100))",
                    icon: "checkmark.circle.fill",
                    color: .purple
                )
            }

            // Most contacted person
            if let mostContacted = data.mostContactedPerson {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                        .frame(width: 50, height: 50)
                        .background(.yellow.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "analytics.social.mostContacted", defaultValue: "En Çok Görüşülen", comment: "Most contacted person label"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(mostContacted)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Weekly trend
            if !data.weeklyContactTrend.isEmpty {
                let chartPoints = data.weeklyContactTrend.map {
                    TrendLineChart.ChartDataPoint(date: $0.date, value: $0.value)
                }

                TrendLineChart(
                    title: String(localized: "analytics.social.weeklyTrend", defaultValue: "Haftalık İletişim Trendi", comment: "Weekly contact trend chart title"),
                    dataPoints: chartPoints,
                    color: .blue
                )
            }

            // Relationship type breakdown
            if !data.contactsByRelationType.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "analytics.social.byRelationType", defaultValue: "İlişki Türlerine Göre", comment: "Contacts by relationship type title"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(Array(data.contactsByRelationType.sorted(by: { $0.value > $1.value })), id: \.key) { type, count in
                        relationshipRow(type: type, count: count, total: data.totalContacts)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    @ViewBuilder
    private func relationshipRow(type: String, count: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(type)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(String(localized: "component.count", defaultValue: "\(count)", comment: "Generic count")).font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(count) / CGFloat(total),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        SocialAnalyticsSection(
            data: SocialAnalytics(
                totalContacts: 42,
                activeContacts: 28,
                averageContactFrequency: 2.5,
                mostContactedPerson: "Ahmet Yılmaz",
                contactsByRelationType: [
                    "Yakın Arkadaş": 15,
                    "Aile": 10,
                    "İş Arkadaşı": 12,
                    "Tanıdık": 5
                ],
                responseRate: 0.67,
                weeklyContactTrend: [
                    SocialAnalytics.DatePoint(date: Date().addingTimeInterval(-6*86400), value: 3),
                    SocialAnalytics.DatePoint(date: Date().addingTimeInterval(-5*86400), value: 5),
                    SocialAnalytics.DatePoint(date: Date().addingTimeInterval(-4*86400), value: 4),
                    SocialAnalytics.DatePoint(date: Date().addingTimeInterval(-3*86400), value: 7),
                    SocialAnalytics.DatePoint(date: Date().addingTimeInterval(-2*86400), value: 6),
                    SocialAnalytics.DatePoint(date: Date().addingTimeInterval(-1*86400), value: 8),
                    SocialAnalytics.DatePoint(date: Date(), value: 5)
                ],
                needsAttentionCount: 8
            )
        )
        .padding()
    }
}
