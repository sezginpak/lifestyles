//
//  ModernInsightsView.swift
//  LifeStyles
//
//  Created by Claude on 31.10.2025.
//

import SwiftUI

struct ModernInsightsView: View {
    let friend: Friend

    @State private var analyticsVM: FriendAnalyticsViewModel

    init(friend: Friend) {
        self.friend = friend
        _analyticsVM = State(initialValue: FriendAnalyticsViewModel(friend: friend))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header Section
                headerSection

                // Consistency Score - Çok önemli, üstte olmalı
                ConsistencyScoreCard(metrics: analyticsVM.consistencyMetrics)

                // Milestone Tracker - Motivasyonel, ikinci sırada
                MilestoneTrackerCard(milestones: analyticsVM.upcomingMilestones)

                // Mood Analysis Section
                moodSection

                // Communication Depth - İletişim kalitesi
                CommunicationDepthCard(metrics: analyticsVM.depthMetrics)

                // Timing Analytics - Zamanlama bilgileri
                TimingAnalyticsCard(analytics: analyticsVM.timingAnalytics)

                // Bottom padding
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("Detaylı Analiz")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Period badge (son 6 ay)
                Text("Son 6 Ay")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            Text("İlişkinizin derinlemesine analizi")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        VStack(spacing: 20) {
            // Section header
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(.pink)

                Text("Ruh Hali Analizi")
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)

            // Mood cards
            if analyticsVM.moodAnalytics.timelineData.isEmpty {
                // Empty state
                emptyMoodState
            } else {
                // Timeline
                FriendMoodTimelineCard(analytics: analyticsVM.moodAnalytics)

                // Streak
                if analyticsVM.moodAnalytics.currentStreak != nil {
                    MoodStreakCard(analytics: analyticsVM.moodAnalytics)
                }

                // Weekday distribution
                if !analyticsVM.moodAnalytics.weekdayDistribution.isEmpty {
                    WeekdayMoodDistributionCard(analytics: analyticsVM.moodAnalytics)
                }
            }
        }
    }

    private var emptyMoodState: some View {
        VStack(spacing: 16) {
            Image(systemName: "face.smiling")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Ruh Hali Takibi")
                .font(.headline)

            Text("Görüşmelerinize ruh hali ekleyerek daha detaylı analiz yapabilirsiniz. Ruh hali takibi, ilişkinizin kalitesini anlamanıza yardımcı olur.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {}) {
                Label("İlk Ruh Halini Ekle", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            .disabled(true) // Placeholder
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModernInsightsView(friend: Friend.preview)
    }
}

// MARK: - Friend Preview Extension

extension Friend {
    static var preview: Friend {
        let friend = Friend(
            name: "Ahmet Yılmaz",
            phoneNumber: "+90 555 123 4567",
            frequency: .weekly
        )
        friend.isImportant = true
        friend.notes = "Çok iyi bir arkadaş"
        friend.avatarEmoji = "🎸"

        // Mock contact history
        let calendar = Calendar.current
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i * 7, to: Date()) ?? Date()
            let history = ContactHistory(date: date)
            history.notes = "Harika bir görüşme yaptık. Yeni projesi hakkında konuştuk."
            history.mood = [ContactMood.great, .good, .okay, .notGreat].randomElement()
            history.friend = friend
            if friend.contactHistory == nil {
                friend.contactHistory = []
            }
            friend.contactHistory?.append(history)
        }

        return friend
    }
}
