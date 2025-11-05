//
//  FriendDetailTabs.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from FriendDetailView.swift - Tab content views
//

import SwiftUI
import SwiftData
import Charts
import FoundationModels
// MARK: - Friend Detail View Extension (Tabs)
extension FriendDetailView {
    var overviewContent: some View {
        FriendDetailOverviewTab(
            friend: friend,
            showingAddTransaction: $showingAddTransaction,
            showingAISuggestion: $showingAISuggestion,
            noteText: $noteText,
            markTransactionAsPaid: markTransactionAsPaid,
            markTransactionAsUnpaid: markTransactionAsUnpaid,
            deleteTransaction: deleteTransaction,
            saveNotes: saveNotes
        )
    }

    // MARK: - Modern Components - MOVED TO FriendDetailOverviewTab.swift

    // MARK: - History Content

    var historyContent: some View {
        FriendDetailHistoryTab(friend: friend)
    }

    // MARK: - Insights Content

    var insightsContent: some View {
        FriendDetailInsightsTab(friend: friend)
    }

    // MARK: - Partner Content

    var partnerContent: some View {
        FriendDetailPartnerTab(friend: friend)
    }

    // MARK: - Chat Content

    var chatContent: some View {
        FriendDetailChatTab(
            friend: friend,
            chatMessages: $chatMessages,
            userInput: $userInput,
            isGeneratingAI: $isGeneratingAI
        )
    }

    // MARK: - Compact Components

    var nextContactCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.needsContact ? "İletişim Gerekiyor!" : "Sonraki İletişim")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(friend.needsContact ? "\(friend.daysOverdue) gün gecikti" : "\(friend.daysRemaining) gün içinde")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(friend.needsContact ? .red : .green)
            }

            Spacer()

            Image(systemName: friend.needsContact ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
                .font(.title2)
                .foregroundStyle(friend.needsContact ? .red : .green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(friend.needsContact ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // aiSuggestionCard - MOVED TO AIModernSuggestionCard.swift

    // achievementSection - MOVED TO AchievementSection.swift

    // MARK: - Transaction Section - Now using TransactionSection component

    var compactNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "common.notes", comment: "Notes"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            TextEditor(text: $noteText)
                .frame(height: 80)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            if noteText != (friend.notes ?? "") {
                Button {
                    saveNotes()
                } label: {
                    Text(String(localized: "common.save", comment: "Save"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)
            }
        }
    }


    var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "friend.communication.trend.3months", comment: "Communication trend"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Chart(getMonthlyData()) { item in
                LineMark(
                    x: .value("Ay", item.month),
                    y: .value("İletişim", item.count)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Ay", item.month),
                    y: .value("İletişim", item.count)
                )
                .foregroundStyle(.blue.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 120)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    var moodDistributionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "friend.mood.distribution", comment: "Mood distribution"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            let moodData = getMoodDistribution()
            if !moodData.isEmpty {
                Chart(moodData) { item in
                    BarMark(
                        x: .value("Sayı", item.count),
                        y: .value("Ruh Hali", item.mood)
                    )
                    .foregroundStyle(by: .value("Ruh Hali", item.mood))
                }
                .frame(height: 100)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    var communicationPatternSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "friend.communication.pattern", comment: "Communication pattern"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            HStack(spacing: 12) {
                PatternCard(
                    icon: "chart.line.uptrend.xyaxis",
                    value: communicationTrend,
                    label: "Trend",
                    color: trendColor
                )

                PatternCard(
                    icon: "clock.fill",
                    value: averageGapDays,
                    label: "Ort. Ara",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }

    var bestTimeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "friend.best.day.contact", comment: "Best day"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(bestDayForContact)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.title3)
                .foregroundStyle(.blue)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }


    // MARK: - Helper Properties (Moved to FriendDetailView+Calculations.swift)
    // All helper properties are now centralized in the extension

    // generateAISuggestion() - MOVED TO AIModernSuggestionCard.swift

    // MARK: - AI Chat Actions - MOVED TO FriendAIChatView.swift

    // MARK: - Actions

    func callFriend() {
        guard let phone = friend.phoneNumber else { return }

        // Telefon numarasını temizle (boşluk, tire, parantez vb.)
        let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        // Telefonu aç (doğru iOS URL scheme: tel: - iki slash yok!)
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)

            // Bildirim gönder
            NotificationService.shared.sendContactCompletedNotification(for: friend)

            // Haptic feedback
            HapticFeedback.medium()
        }
    }

    func sendSMS() {
        guard let phone = friend.phoneNumber else { return }

        // Telefon numarasını temizle (boşluk, tire, parantez vb.)
        let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        // Mesaj uygulamasını aç
        if let url = URL(string: "sms:\(cleanPhone)") {
            UIApplication.shared.open(url)

            // Bildirim gönder
            NotificationService.shared.sendContactCompletedNotification(for: friend)

            // Haptic feedback
            HapticFeedback.medium()
        }
    }

    func markAsContacted() {
        // Detay giriş sheet'ini göster (not, ruh hali eklemek için)
        showingAddHistorySheet = true

        // Haptic feedback
        HapticFeedback.light()
    }

    func saveNotes() {
        friend.notes = noteText.isEmpty ? nil : noteText

        do {
            try modelContext.save()
            HapticFeedback.success()
        } catch {
            print("❌ Notlar kaydedilemedi: \(error)")
        }
    }

    func deleteFriend() {
        modelContext.delete(friend)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("❌ Arkadaş silinemedi: \(error)")
        }
    }

    // MARK: - Transaction Actions - Moved to FriendDetailView+TransactionActions.swift extension
}

// MARK: - Transaction Row Component - REMOVED FOR DEBUGGING

