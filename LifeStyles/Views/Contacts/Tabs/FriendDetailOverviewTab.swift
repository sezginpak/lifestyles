//
//  FriendDetailOverviewTab.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift - Overview Tab Content
//

import SwiftUI
import SwiftData

/// Overview tab içeriği - Ana özet görünümü
struct FriendDetailOverviewTab: View {
    @Bindable var friend: Friend
    @Environment(\.modelContext) private var modelContext

    // Bindings from parent
    @Binding var showingAddTransaction: Bool
    @Binding var showingAISuggestion: Bool
    @Binding var noteText: String

    // Actions from parent
    let markTransactionAsPaid: (Transaction) -> Void
    let markTransactionAsUnpaid: (Transaction) -> Void
    let deleteTransaction: (Transaction) -> Void
    let saveNotes: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Hero Stats Section - Modern & Visual
            FriendHeroStatsCard(friend: friend)
                .padding(.horizontal)

            // AI Suggestion Card (Modern)
            if showingAISuggestion {
                AIModernSuggestionCard(friend: friend)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Next Contact Card - Enhanced
            NextContactCard(friend: friend)
                .padding(.horizontal)

            // İlişki Sağlığı Kartı
            RelationshipHealthCard(friend: friend)
                .padding(.horizontal)

            // Partner için Özel Kartlar
            if friend.isPartner {
                VStack(spacing: 12) {
                    PartnerRelationshipDurationCard(friend: friend)
                    PartnerAnniversaryCard(friend: friend)
                    LoveLanguageSummaryCard(friend: friend)
                }
                .padding(.horizontal)
            }

            // İletişim & Ruh Hali Trend (Yan Yana)
            HStack(spacing: 12) {
                CommunicationTrendCard(friend: friend)
                MoodTrendCard(friend: friend)
            }
            .padding(.horizontal)

            // Yaklaşan Özel Günler
            UpcomingSpecialDatesCard(friend: friend)
                .padding(.horizontal)

            // Achievement Badges
            if !achievementBadges.isEmpty {
                AchievementSection(friend: friend)
                    .padding(.horizontal)
            }

            // Ortak İlgi Alanları
            SharedInterestsView(friend: friend)
                .padding(.horizontal)

            // Borç/Alacak Section
            TransactionSection(
                friend: friend,
                showingAddTransaction: $showingAddTransaction,
                onMarkAsPaid: markTransactionAsPaid,
                onMarkAsUnpaid: markTransactionAsUnpaid,
                onDelete: deleteTransaction
            )
            .padding(.horizontal)

            // Quick Notes - Modern (Inline for now)
            modernNotesSection
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Helper Properties

    private var achievementBadges: [FriendAchievement] {
        var badges: [FriendAchievement] = []

        if friend.totalContactCount >= 100 {
            badges.append(FriendAchievement(icon: "star.fill", title: "100 İletişim", color: .yellow))
        } else if friend.totalContactCount >= 50 {
            badges.append(FriendAchievement(icon: "star.fill", title: "50 İletişim", color: .orange))
        } else if friend.totalContactCount >= 10 {
            badges.append(FriendAchievement(icon: "star.fill", title: "10 İletişim", color: .blue))
        }

        if currentStreak >= 30 {
            badges.append(FriendAchievement(icon: "flame.fill", title: "30 Gün Seri", color: .red))
        } else if currentStreak >= 7 {
            badges.append(FriendAchievement(icon: "flame.fill", title: "7 Gün Seri", color: .orange))
        }

        if relationshipHealthScore >= 90 {
            badges.append(FriendAchievement(icon: "heart.fill", title: "Mükemmel İlişki", color: .pink))
        }

        if daysSinceCreation >= 365 {
            badges.append(FriendAchievement(icon: "calendar", title: "1 Yıl", color: .purple))
        }

        return badges
    }

    private var currentStreak: Int {
        guard let history = friend.contactHistory, !history.isEmpty else { return 0 }

        let sorted = history.sorted(by: { $0.date > $1.date })
        var streak = 0
        var lastDate = Date()

        for item in sorted {
            let daysDiff = Calendar.current.dateComponents([.day], from: item.date, to: lastDate).day ?? 0
            if daysDiff <= friend.frequency.days + 1 {
                streak += 1
                lastDate = item.date
            } else {
                break
            }
        }

        return streak
    }

    private var relationshipHealthScore: Int {
        var score = 50

        // İletişim düzeni (+30)
        if !friend.needsContact {
            score += 30
        } else {
            score -= friend.daysOverdue * 2
        }

        // İletişim sıklığı (+20)
        if friend.totalContactCount > 10 {
            score += 20
        } else if friend.totalContactCount > 5 {
            score += 10
        }

        // Streak bonus (+20)
        if currentStreak > 7 {
            score += 20
        } else if currentStreak > 3 {
            score += 10
        }

        // Ruh hali ortalaması (+30)
        if let avgMood = averageMoodScore, avgMood > 0.7 {
            score += 30
        } else if let avgMood = averageMoodScore, avgMood > 0.5 {
            score += 15
        }

        return max(0, min(100, score))
    }

    private var averageMoodScore: Double? {
        guard let history = friend.contactHistory?.compactMap({ $0.mood }), !history.isEmpty else { return nil }

        let total = history.reduce(0.0) { sum, mood in
            switch mood {
            case .great: return sum + 1.0
            case .good: return sum + 0.75
            case .okay: return sum + 0.5
            case .notGreat: return sum + 0.25
            }
        }

        return total / Double(history.count)
    }

    private var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: friend.createdAt, to: Date()).day ?? 0
    }

    // MARK: - Notes Section (Inline)

    private var modernNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "friend.notes", comment: ""))
                .font(.headline)
                .foregroundStyle(.primary)

            TextEditor(text: $noteText)
                .frame(height: 100)
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if noteText != (friend.notes ?? "") {
                Button {
                    saveNotes()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(String(localized: "friend.save", comment: ""))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

}

#Preview {
    FriendDetailOverviewTab(
        friend: .preview,
        showingAddTransaction: .constant(false),
        showingAISuggestion: .constant(false),
        noteText: .constant(""),
        markTransactionAsPaid: { _ in },
        markTransactionAsUnpaid: { _ in },
        deleteTransaction: { _ in },
        saveNotes: { }
    )
    .modelContainer(for: [Friend.self, Transaction.self])
}
