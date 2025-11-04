//
//  DashboardComponentsNew.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Modern dashboard componentleri - 4 ring system
//

import SwiftUI

// MARK: - Hero Stats Card (Modern Design)
// Not: Yeni modern tasarım ModernHeroCard.swift dosyasında
// Eski tasarımı korumak için bu typedef bırakıldı

typealias HeroStatsCard = ModernHeroStatsCard

// MARK: - Partner Card - MODERN REDESIGN

struct PartnerCard: View {
    let partner: PartnerInfo
    let onCall: () -> Void
    let onMessage: () -> Void
    let onLogContact: () -> Void

    @State private var isPressed = false
    @State private var showingStats = false

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(hex: "FF6B9D").opacity(0.12),
                    Color(hex: "FF9A9E").opacity(0.08),
                    Color(hex: "FAD0C4").opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 20) {
                // Header: Avatar + Info
                HStack(spacing: 16) {
                    // Modern Avatar with pulse animation
                    ZStack {
                        // Pulse background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF6B9D").opacity(0.3),
                                        Color(hex: "FF6B9D").opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)
                            .scaleEffect(showingStats ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showingStats)

                        // Main avatar
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF6B9D"),
                                        Color(hex: "FF9A9E")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.3), lineWidth: 2)
                            )

                        if let emoji = partner.emoji {
                            Text(emoji)
                                .font(.system(size: 40))
                        } else {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        // Name
                        HStack(spacing: 8) {
                            Text(partner.name)
                                .font(.title2.weight(.heavy))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "FF6B9D"),
                                            Color(hex: "C44569")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .lineLimit(1)

                            Text("💖")
                                .font(.title3)
                        }

                        // Relationship duration
                        Text(partner.relationshipText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        // Last contact badge
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(partner.lastContactText)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color(hex: "FF6B9D"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(hex: "FF6B9D").opacity(0.15))
                        )
                    }

                    Spacer()
                }

                // Stats Row - Compact
                if let anniversaryText = partner.anniversaryText {
                    HStack(spacing: 16) {
                        // Anniversary
                        statBadge(emoji: "🎉", text: anniversaryText, color: "FF6B9D")

                        // Love Language
                        if let loveLanguage = partner.loveLanguage {
                            statBadge(emoji: "💕", text: loveLanguage, color: "FF9A9E")
                        }
                    }
                }

                // Quick Actions - Compact Icons
                HStack(spacing: 12) {
                    actionButton(icon: "phone.fill", color: "3498DB", action: onCall)
                    actionButton(icon: "message.fill", color: "2ECC71", action: onMessage)
                    actionButton(icon: "checkmark.circle.fill", color: "FF6B9D", action: onLogContact)
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.4),
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color(hex: "FF6B9D").opacity(0.15), radius: 20, x: 0, y: 12)
        .shadow(color: .black.opacity(0.08), radius: 30, x: 0, y: 15)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onAppear {
            showingStats = true
        }
    }

    // Helper: Stat Badge
    private func statBadge(emoji: String, text: String, color: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.title3)

            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(hex: color).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // Helper: Action Button
    private func actionButton(icon: String, color: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: color),
                                    Color(hex: color).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color(hex: color).opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Streak & Achievement Card

struct StreakAchievementCard: View {
    let streakInfo: StreakInfo

    var body: some View {
        HStack(spacing: 16) {
            // Sol: Streak Badge
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.title3)
                    Text(String(format: NSLocalizedString("dashboard.streak.days.format", comment: "Day count for streak"), streakInfo.currentStreak))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.orange.opacity(0.15))
                        .overlay(
                            Capsule()
                                .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
                        )
                )

                if streakInfo.bestStreak > streakInfo.currentStreak {
                    Text(String(format: NSLocalizedString("dashboard.best.streak.format", comment: "Best streak count"), streakInfo.bestStreak))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }

            Spacer()

            // Sağ: Son Achievements
            HStack(spacing: 8) {
                ForEach(streakInfo.recentAchievements.prefix(3), id: \.id) { achievement in
                    MiniAchievementBadge(achievement: achievement)
                }

                // Tümünü Gör İkonu
                if streakInfo.recentAchievements.count > 3 {
                    VStack(spacing: 2) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.yellow)

                        Text(String(format: NSLocalizedString("dashboard.more.achievements", comment: "More achievements count"), streakInfo.recentAchievements.count - 3))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.orange.opacity(0.3), .yellow.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .orange.opacity(0.1), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

struct MiniAchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 4) {
            Text(achievement.emoji)
                .font(.title2)

            Text(achievement.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 60)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: achievement.colorHex).opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    Color(hex: achievement.colorHex).opacity(0.25),
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - Sparkline Mini Chart

struct SparklineChart: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            let maxValue = data.max() ?? 1.0
            let minValue = data.min() ?? 0.0
            let range = maxValue - minValue

            // Çizgi path
            let path = Path { path in
                guard !data.isEmpty else { return }

                let stepX = width / CGFloat(data.count - 1)

                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                    let y = height - (CGFloat(normalizedValue) * height)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }

            // Gradient fill path
            let fillPath = Path { path in
                guard !data.isEmpty else { return }

                let stepX = width / CGFloat(data.count - 1)

                // Başlangıç
                path.move(to: CGPoint(x: 0, y: height))

                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                    let y = height - (CGFloat(normalizedValue) * height)
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                // Sona kadar
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }

            ZStack {
                // Gradient fill
                fillPath
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Çizgi
                path
                    .stroke(color, lineWidth: 2)
            }
        }
        .frame(height: 30)
    }
}

// MARK: - Dashboard Compact Stat Card

struct DashboardCompactStatCard: View {
    let data: CompactStatData
    var onTap: (() -> Void)? = nil
    var onQuickAction: ((QuickAction) -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticFeedback.medium()
            onTap?()
        } label: {
            ZStack(alignment: .topTrailing) {
                // Main content
                VStack(alignment: .leading, spacing: 10) {
                    // Icon ve Title
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: data.color).opacity(0.15))
                                .frame(width: 40, height: 40)

                            Image(systemName: data.icon)
                                .font(.title3)
                                .foregroundStyle(Color(hex: data.color))
                        }

                        Text(data.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()
                    }

                    Spacer()

                    // Main Value
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(data.mainValue)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        if let badge = data.badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundStyle(badge.hasPrefix("+") ? .green : .red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill((badge.hasPrefix("+") ? Color.green : Color.red).opacity(0.15))
                                )
                        }
                    }

                    // Sub Value
                    Text(data.subValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Sparkline (trend data varsa)
                    if let trendData = data.trendData, !trendData.isEmpty {
                        SparklineChart(data: trendData, color: Color(hex: data.color))
                            .padding(.top, 4)
                    }
                    // Progress Bar (trend yoksa ve progress varsa)
                    else if let progress = data.progressValue {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.secondary.opacity(0.15))

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: data.color),
                                                Color(hex: data.color).opacity(0.7)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progress)
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .padding(16)

                // Quick Actions (sağ üst köşe)
                if let actions = data.quickActions, !actions.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(actions) { action in
                            Button {
                                HapticFeedback.light()
                                onQuickAction?(action)
                            } label: {
                                Image(systemName: action.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: action.color))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(Color(hex: action.color).opacity(0.15))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview

#Preview("Hero Stats Card") {
    VStack {
        HeroStatsCard(
            summary: DashboardSummary(
                goalsRing: DashboardRingData(
                    completed: 3,
                    total: 5,
                    color: "667EEA",
                    icon: "target",
                    label: "Hedefler"
                ),
                habitsRing: DashboardRingData(
                    completed: 2,
                    total: 3,
                    color: "E74C3C",
                    icon: "flame.fill",
                    label: "Alışkanlıklar"
                ),
                socialRing: DashboardRingData(
                    completed: 75,
                    total: 100,
                    color: "3498DB",
                    icon: "person.2.fill",
                    label: "İletişim"
                ),
                activityRing: DashboardRingData(
                    completed: 65,
                    total: 100,
                    color: "2ECC71",
                    icon: "location.fill",
                    label: "Mobilite"
                ),
                overallScore: 72,
                motivationMessage: "Harika bir gün! 💪"
            )
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Partner Card") {
    VStack {
        PartnerCard(
            partner: PartnerInfo(
                name: "Ayşe",
                emoji: "👩🏻‍💼",
                relationshipDays: 730,
                relationshipDuration: (2, 0, 0),
                lastContactDays: 1,
                daysUntilAnniversary: 45,
                anniversaryDate: Date(),
                loveLanguage: "Hediye Dili",
                phoneNumber: "+90 555 123 4567"
            ),
            onCall: {},
            onMessage: {},
            onLogContact: {}
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Stats") {
    VStack {
        HStack(spacing: 12) {
            DashboardCompactStatCard(
                data: CompactStatData(
                    icon: "target",
                    title: "Hedefler",
                    color: "667EEA",
                    mainValue: "%68",
                    subValue: "Tamamlanma",
                    progressValue: 0.68,
                    badge: nil
                )
            )

            DashboardCompactStatCard(
                data: CompactStatData(
                    icon: "person.2.fill",
                    title: "İletişim",
                    color: "3498DB",
                    mainValue: "4",
                    subValue: "Bu hafta",
                    progressValue: nil,
                    badge: "+25%"
                )
            )
        }

        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

