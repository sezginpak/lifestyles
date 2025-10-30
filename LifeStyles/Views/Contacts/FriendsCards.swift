//
//  FriendsCards.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from FriendsView.swift - Friend cards and filters
//

import SwiftUI
import SwiftData

// MARK: - Filter Chip

struct FriendFilterChip: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                LinearGradient(colors: [Color.brandPrimary, Color.accentSecondary], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color(.secondarySystemBackground), Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? Color.brandPrimary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Partner Hero Card

struct PartnerHeroCard: View {
    let partner: Friend

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("💑")
                            .font(.title2)

                        Text(partner.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    if let duration = partner.relationshipDuration {
                        Text(String(format: NSLocalizedString("friend.relationship.duration.format", comment: "X years, Y months, Z days together"), duration.years, duration.months, duration.days))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // İlişki süresi badge
                if let days = partner.relationshipDays {
                    VStack(spacing: 2) {
                        Text("\(days)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(String(localized: "time.days", comment: "days"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(Circle())
                }
            }

            // Yıldönümü countdown
            if let daysUntil = partner.daysUntilAnniversary {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)

                    Text(String(format: NSLocalizedString("friend.anniversary.days.remaining.format", comment: "X days until anniversary"), daysUntil))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    if daysUntil <= 30 {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .padding(12)
                .background(Color.pink.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Love Language
            if let loveLanguage = partner.loveLanguage {
                HStack {
                    Text(loveLanguage.emoji)
                    Text(loveLanguage.displayName)
                        .font(.subheadline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.15), Color.red.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.3), Color.red.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .pink.opacity(0.2), radius: 15, x: 0, y: 8)
    }
}

// MARK: - İstatistik Kartı

struct FriendsStatsCard: View {
    let needsAttention: Int
    let totalFriends: Int
    let importantFriends: Int

    var body: some View {
        HStack(spacing: 16) {
            FriendStatItem(
                value: needsAttention,
                label: "İletişim Gerekiyor",
                color: needsAttention > 0 ? Color.red : Color.green
            )

            Divider()
                .frame(height: 50)

            FriendStatItem(
                value: totalFriends,
                label: "Toplam Arkadaş",
                color: Color.blue
            )

            Divider()
                .frame(height: 50)

            FriendStatItem(
                value: importantFriends,
                label: "Önemli",
                color: Color.orange
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Arkadaş Kartı

struct FriendCard: View {
    let friend: Friend
    let viewModel: FriendsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Avatar
                FriendAvatarView(friend: friend, size: 50, showBadge: false)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(friend.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if friend.isImportant {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    Text(friend.frequency.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Durum göstergesi
                VStack(alignment: .trailing, spacing: 2) {
                    if friend.needsContact {
                        Text(String(format: NSLocalizedString("friend.days.overdue.format", comment: "X days"), friend.daysOverdue))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                        Text(String(localized: "friend.overdue", comment: "overdue"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(format: NSLocalizedString("friend.days.remaining.format", comment: "X days"), friend.daysRemaining))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                        Text(String(localized: "friend.remaining", comment: "remaining"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Son iletişim tarihi
            if let lastContact = friend.lastContactDate {
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: NSLocalizedString("friends.last.label", comment: "Last:"), formatDate(lastContact)))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: NSLocalizedString("friends.next.label", comment: "Next:"), formatDate(friend.nextContactDate)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Hızlı İletişim Tamamla Butonu
            if friend.needsContact {
                Button {
                    HapticFeedback.success()
                    viewModel.markAsContacted(friend)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(String(localized: "friend.contact.completed", comment: "Contact completed"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(friend.needsContact ? Color.red.opacity(0.05) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(friend.needsContact ? Color.red.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

