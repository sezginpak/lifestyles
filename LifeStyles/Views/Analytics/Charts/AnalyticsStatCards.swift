//
//  AnalyticsCards.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import SwiftUI

/// İstatistik kartı component'i (Analytics için)
struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: TrendDirection?

    enum TrendDirection {
        case up
        case down
        case stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        trend: TrendDirection? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()

                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundStyle(trend.color)
                        .padding(6)
                        .background(trend.color.opacity(0.15))
                        .clipShape(Circle())
                }
            }

            // Value
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)

            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Büyük stat card variant
struct LargeStatCard: View {
    let title: String
    let value: String
    let progress: Double // 0-1
    let icon: String
    let color: Color
    let description: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon and value
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
                    .frame(width: 60, height: 60)
                    .background(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(value)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(color)

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Title
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                }
            }
            .frame(height: 12)

            // Description
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

/// Mini stat card (daha kompakt)
struct AnalyticsMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Regular stat cards
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    title: "Aktif Günler",
                    value: "24",
                    subtitle: "Son 30 gün",
                    icon: "calendar",
                    color: .blue,
                    trend: .up
                )

                AnalyticsStatCard(
                    title: "Wellness Skoru",
                    value: "85",
                    subtitle: "Mükemmel",
                    icon: "heart.fill",
                    color: .red,
                    trend: .stable
                )
            }

            // Large stat card
            LargeStatCard(
                title: "Genel Wellness Seviyesi",
                value: "85",
                progress: 0.85,
                icon: "heart.circle.fill",
                color: .red,
                description: "Harika gidiyorsunuz! Consistency skorunuz mükemmel."
            )

            // Mini stat cards
            VStack(spacing: 8) {
                AnalyticsMiniCard(
                    title: "Toplam Arkadaş",
                    value: "42",
                    icon: "person.2.fill",
                    color: .blue
                )

                AnalyticsMiniCard(
                    title: "Ortalama Mood",
                    value: "4.2",
                    icon: "face.smiling",
                    color: .orange
                )

                AnalyticsMiniCard(
                    title: "Tamamlanan Hedef",
                    value: "18",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
    }
}
