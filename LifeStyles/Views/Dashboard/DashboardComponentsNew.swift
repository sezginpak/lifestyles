//
//  DashboardComponentsNew.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Modern dashboard componentleri - 4 ring system
//

import SwiftUI

// MARK: - Hero Stats Card (4 Ring System)

struct HeroStatsCard: View {
    let summary: DashboardSummary

    var body: some View {
        VStack(spacing: 20) {
            // 4'lü Ring Grid
            HStack(spacing: 12) {
                // Sol Sütun
                VStack(spacing: 12) {
                    // Goals Ring (Sol Üst)
                    MiniRingView(data: summary.goalsRing)

                    // Social Ring (Sol Alt)
                    MiniRingView(data: summary.socialRing)
                }

                // Orta: Overall Score
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 10)
                        .frame(width: 110, height: 110)

                    Circle()
                        .trim(from: 0, to: CGFloat(summary.overallScore) / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: performanceColors(score: summary.overallScore),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: summary.overallScore)

                    VStack(spacing: 4) {
                        Text("\(summary.overallScore)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: performanceColors(score: summary.overallScore),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(String(localized: "dashboard.score", comment: "Score"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Sağ Sütun
                VStack(spacing: 12) {
                    // Habits Ring (Sağ Üst)
                    MiniRingView(data: summary.habitsRing)

                    // Activity Ring (Sağ Alt)
                    MiniRingView(data: summary.activityRing)
                }
            }

            // Motivasyon Mesajı
            Text(summary.motivationMessage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(20)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "667EEA"),
                        Color(hex: "764BA2")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.clear,
                        Color.black.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(hex: "667EEA").opacity(0.3), radius: 20, x: 0, y: 10)
    }

    private func performanceColors(score: Int) -> [Color] {
        switch score {
        case 80...100:
            return [Color(hex: "2ECC71"), Color(hex: "27AE60")]
        case 60..<80:
            return [Color(hex: "3498DB"), Color(hex: "2980B9")]
        case 40..<60:
            return [Color(hex: "F39C12"), Color(hex: "E67E22")]
        default:
            return [Color(hex: "E74C3C"), Color(hex: "C0392B")]
        }
    }
}

// MARK: - Mini Ring View

struct MiniRingView: View {
    let data: DashboardRingData

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: data.progress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: data.color),
                                Color(hex: data.color).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: data.progress)

                Image(systemName: data.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            Text(data.label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))

            Text("\(data.completed)/\(data.total)")
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Partner Card

struct PartnerCard: View {
    let partner: PartnerInfo
    let onCall: () -> Void
    let onMessage: () -> Void
    let onLogContact: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Üst: Avatar + İsim + İlişki Süresi
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FF6B9D"),
                                    Color(hex: "C44569")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    if let emoji = partner.emoji {
                        Text(emoji)
                            .font(.system(size: 36))
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(partner.name)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("❤️")
                            .font(.title3)
                    }

                    Text(partner.relationshipText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(String(format: NSLocalizedString("dashboard.last.contact.format", comment: "Last contact"), partner.lastContactText))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            // İstatistikler
            HStack(spacing: 12) {
                // Yıldönümü
                if let anniversaryText = partner.anniversaryText {
                    VStack(spacing: 4) {
                        Text("🎉")
                            .font(.title3)
                        Text(anniversaryText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "FF6B9D").opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Love Language
                if let loveLanguage = partner.loveLanguage {
                    VStack(spacing: 4) {
                        Text("💕")
                            .font(.title3)
                        Text(loveLanguage)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "C44569").opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // Quick Actions
            HStack(spacing: 8) {
                Button(action: onCall) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                        Text(String(localized: "common.call", comment: "Call"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                    .background(Color(hex: "3498DB"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onMessage) {
                    HStack(spacing: 6) {
                        Image(systemName: "message.fill")
                            .font(.caption)
                        Text(String(localized: "common.message", comment: "Message"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                    .background(Color(hex: "2ECC71"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onLogContact) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text(String(localized: "common.save", comment: "Save"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                    .background(Color(hex: "FF6B9D"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "FF6B9D").opacity(0.15),
                        Color(hex: "C44569").opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(hex: "FF6B9D").opacity(0.4),
                                Color(hex: "C44569").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "FF6B9D").opacity(0.2), radius: 15, x: 0, y: 8)
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
                    Text("\(streakInfo.currentStreak) Gün")
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
                    Text("En İyi: \(streakInfo.bestStreak)")
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

                        Text("+\(streakInfo.recentAchievements.count - 3)")
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

// MARK: - Dashboard Compact Stat Card

struct DashboardCompactStatCard: View {
    let data: CompactStatData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            // Progress Bar (opsiyonel)
            if let progress = data.progressValue {
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
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
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

