//
//  FriendDetailComponents.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Friend Detail View için ek componentler
//

import SwiftUI
import SwiftData

// MARK: - İletişim Kalitesi Trend Kartı

struct CommunicationTrendCard: View {
    let friend: Friend

    private var trendInfo: (emoji: String, title: String, description: String, color: Color) {
        guard let history = friend.contactHistory, history.count >= 3 else {
            return ("➖", "Yetersiz Veri", "Henüz yeterli iletişim yok", .gray)
        }

        let sorted = history.sorted(by: { $0.date > $1.date })
        let recentCount = min(5, sorted.count / 2)
        let oldCount = sorted.count - recentCount

        let recentContacts = sorted.prefix(recentCount).count
        let oldContacts = sorted.suffix(oldCount).count

        let recentAvg = Double(recentCount) / Double(max(1, recentCount))
        let oldAvg = Double(oldCount) / Double(max(1, oldCount))

        if recentAvg > oldAvg * 1.2 {
            return ("📈", "Artıyor", "İletişim sıklığınız artıyor", .green)
        } else if recentAvg < oldAvg * 0.8 {
            return ("📉", "Azalıyor", "İletişim sıklığınız azalıyor", .orange)
        } else {
            return ("➡️", "Stabil", "İletişim düzeniniz stabil", .blue)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Emoji Icon
            Text(trendInfo.emoji)
                .font(.system(size: 32))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "friend.communication.frequency", comment: "Communication frequency"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(trendInfo.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(trendInfo.color)

                Text(trendInfo.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [trendInfo.color.opacity(0.1), trendInfo.color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(trendInfo.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Ruh Hali Trend Kartı

struct MoodTrendCard: View {
    let friend: Friend

    private var moodInfo: (emojis: [String], average: String, color: Color) {
        guard let history = friend.contactHistory?.compactMap({ $0.mood }),
              !history.isEmpty else {
            return ([], "Veri Yok", .gray)
        }

        let recent = history.suffix(5)
        let emojis = recent.map { $0.emoji }

        let totalScore = recent.reduce(0.0) { sum, mood in
            switch mood {
            case .great: return sum + 1.0
            case .good: return sum + 0.75
            case .okay: return sum + 0.5
            case .notGreat: return sum + 0.25
            }
        }

        let avg = totalScore / Double(recent.count)
        let avgText: String
        let avgColor: Color

        if avg >= 0.85 {
            avgText = "Harika"
            avgColor = .green
        } else if avg >= 0.65 {
            avgText = "İyi"
            avgColor = .blue
        } else if avg >= 0.45 {
            avgText = "Normal"
            avgColor = .orange
        } else {
            avgText = "Zor"
            avgColor = .red
        }

        return (emojis, avgText, avgColor)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Mood Emojis
            VStack(spacing: 4) {
                if moodInfo.emojis.isEmpty {
                    Text("😐")
                        .font(.system(size: 32))
                } else {
                    HStack(spacing: 2) {
                        ForEach(moodInfo.emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 16))
                        }
                    }
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "friend.communication.quality", comment: "Communication quality"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(moodInfo.average)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(moodInfo.color)

                Text(String(localized: "friend.last.5.meetings", comment: "Last 5 meetings"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [moodInfo.color.opacity(0.1), moodInfo.color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(moodInfo.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Yaklaşan Özel Günler Kartı

struct UpcomingSpecialDatesCard: View {
    let friend: Friend

    private var upcomingDates: [(date: SpecialDate, days: Int)] {
        guard let specialDates = friend.specialDates else { return [] }

        return specialDates
            .filter { $0.daysUntil <= 30 && $0.daysUntil >= 0 }
            .sorted { $0.daysUntil < $1.daysUntil }
            .prefix(2)
            .map { ($0, $0.daysUntil) }
    }

    var body: some View {
        if !upcomingDates.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundStyle(.orange)
                    Text(String(localized: "friend.upcoming.special.dates", comment: "Upcoming special dates"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }

                // Dates List
                ForEach(upcomingDates, id: \.date.id) { item in
                    HStack(spacing: 12) {
                        // Emoji
                        Text(item.date.emoji ?? "📅")
                            .font(.title2)

                        // Info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.date.title)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(String(format: NSLocalizedString("friend.days.away.format", comment: "X days away"), item.days))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Countdown Badge
                        Text("\(item.days)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.orange))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Partner İlişki Süresi Kartı

struct PartnerRelationshipDurationCard: View {
    let friend: Friend

    private var durationText: String {
        guard let duration = friend.relationshipDuration else { return "Bilinmiyor" }

        var parts: [String] = []

        if duration.years > 0 {
            parts.append("\(duration.years) yıl")
        }
        if duration.months > 0 {
            parts.append("\(duration.months) ay")
        }
        if duration.days > 0 && duration.years == 0 {
            parts.append("\(duration.days) gün")
        }

        return parts.isEmpty ? "Yeni başladı" : parts.joined(separator: " ")
    }

    private var totalDaysText: String {
        guard let days = friend.relationshipDays else { return "" }
        return "toplam \(days) gün"
    }

    var body: some View {
        if friend.isPartner && friend.relationshipStartDate != nil {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .foregroundStyle(.pink)
                    Text(String(localized: "friend.relationship.duration", comment: "Relationship duration"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.pink)
                }

                Text(durationText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(totalDaysText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.pink.opacity(0.15), Color.pink.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pink.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Partner Yıldönümü Kartı

struct PartnerAnniversaryCard: View {
    let friend: Friend

    private var anniversaryInfo: (days: Int, text: String) {
        guard let days = friend.daysUntilAnniversary else { return (0, "") }

        if days == 0 {
            return (0, "Bugün yıldönümünüz!")
        } else if days == 1 {
            return (1, "Yarın yıldönümünüz!")
        } else if days <= 7 {
            return (days, "\(days) gün sonra yıldönümü")
        } else if days <= 30 {
            return (days, "\(days) gün sonra yıldönümü")
        } else {
            return (days, "\(days) gün sonra")
        }
    }

    var body: some View {
        if friend.isPartner && friend.anniversaryDate != nil {
            HStack(spacing: 12) {
                // Icon
                Text("🎉")
                    .font(.system(size: 32))

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "special.dates.anniversary", comment: "Anniversary"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(anniversaryInfo.text)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(anniversaryInfo.days <= 7 ? .red : .purple)
                }

                Spacer()

                // Countdown Badge
                if anniversaryInfo.days <= 30 {
                    Text("\(anniversaryInfo.days)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(
                                anniversaryInfo.days <= 7 ? Color.red : Color.purple
                            )
                        )
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.1),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Sevgi Dili Özet Kartı

struct LoveLanguageSummaryCard: View {
    let friend: Friend

    var body: some View {
        if friend.isPartner, let loveLanguage = friend.loveLanguage {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(loveLanguage.emoji)
                        .font(.title2)
                    Text("Sevgi Dili")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                }

                // Love Language Name
                Text(loveLanguage.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Description
                Text(loveLanguage.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Quick Tips (First 2)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(loveLanguage.tips.prefix(2), id: \.self) { tip in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(tip)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color.pink.opacity(0.12),
                        Color.purple.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.4), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Ortak İlgi Alanları View

struct SharedInterestsView: View {
    let friend: Friend

    private var interests: [String] {
        guard let interestsString = friend.sharedInterests,
              !interestsString.isEmpty else { return [] }
        return interestsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
    }

    private var activities: [String] {
        guard let activitiesString = friend.favoriteActivities,
              !activitiesString.isEmpty else { return [] }
        return activitiesString.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
    }

    var body: some View {
        if !interests.isEmpty || !activities.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Text(String(localized: "friend.shared.interests.activities", comment: "Shared interests & activities"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                // Interests
                if !interests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "friend.interests", comment: "Interests"))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(interests, id: \.self) { interest in
                                    InterestChip(text: interest, color: .blue)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Activities
                if !activities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favori Aktiviteler")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(activities, id: \.self) { activity in
                                    InterestChip(text: activity, color: .green)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Interest Chip Component

struct InterestChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}
