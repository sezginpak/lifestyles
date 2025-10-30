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
        VStack(spacing: 16) {
            // Compact Stats Grid (Partner için ilişki süresi de eklenebilir)
            if friend.isPartner && friend.relationshipStartDate != nil {
                // Partner için genişletilmiş stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    CompactStatCard(icon: "phone.fill", value: "\(friend.totalContactCount)", label: "İletişim", gradient: [.blue, .cyan])
                    CompactStatCard(icon: "calendar", value: "\(daysSinceCreation)", label: "Gün", gradient: [.purple, .pink])
                    CompactStatCard(icon: "clock.fill", value: friend.frequency.displayName, label: "Sıklık", gradient: [.orange, .red])

                    // Partner için ilişki süresi
                    if let duration = friend.relationshipDuration {
                        let totalMonths = duration.years * 12 + duration.months
                        CompactStatCard(icon: "heart.fill", value: "\(totalMonths)", label: "Ay Birlikte", gradient: [.pink, .red])
                    }
                }
                .padding(.horizontal)
            } else {
                // Normal stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    CompactStatCard(icon: "phone.fill", value: "\(friend.totalContactCount)", label: "İletişim", gradient: [.blue, .cyan])
                    CompactStatCard(icon: "calendar", value: "\(daysSinceCreation)", label: "Gün", gradient: [.purple, .pink])
                    CompactStatCard(icon: "clock.fill", value: friend.frequency.displayName, label: "Sıklık", gradient: [.orange, .red])
                }
                .padding(.horizontal)
            }

            // AI Suggestion Card (Compact)
            if showingAISuggestion {
                aiSuggestionCard
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Next Contact Reminder (Compact)
            nextContactCard

            // Yaklaşan Özel Günler Kartı
            UpcomingSpecialDatesCard(friend: friend)
                .padding(.horizontal)

            // İletişim Kalitesi & Trend Kartları (Yan Yana)
            HStack(spacing: 12) {
                CommunicationTrendCard(friend: friend)
                MoodTrendCard(friend: friend)
            }
            .padding(.horizontal)

            // Partner için Özel Kartlar
            if friend.isPartner {
                VStack(spacing: 12) {
                    // İlişki Süresi Kartı
                    PartnerRelationshipDurationCard(friend: friend)

                    // Yıldönümü Kartı
                    PartnerAnniversaryCard(friend: friend)

                    // Sevgi Dili Özet Kartı
                    LoveLanguageSummaryCard(friend: friend)
                }
                .padding(.horizontal)
            }

            // Achievement Badges (Compact)
            if !achievementBadges.isEmpty {
                achievementSection
            }

            // Ortak İlgi Alanları
            SharedInterestsView(friend: friend)
                .padding(.horizontal)

            // Borç/Alacak Section
            transactionSection
                .padding(.horizontal)

            // Quick Notes
            compactNotesSection
        }
        .padding(.vertical)
    }

    // MARK: - History Content

    var historyContent: some View {
        VStack(spacing: 16) {
            // Mini Calendar View
            miniCalendarView

            // History List
            if let history = sortedHistory, !history.isEmpty {
                VStack(spacing: 8) {
                    ForEach(history) { item in
                        CompactHistoryCard(historyItem: item)
                            .padding(.horizontal)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteHistory(item)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            } else {
                emptyHistoryView
            }
        }
        .padding(.vertical)
    }

    // MARK: - Insights Content

    var insightsContent: some View {
        VStack(spacing: 16) {
            // Trend Chart
            trendChartSection

            // Mood Distribution
            moodDistributionSection

            // Communication Pattern
            communicationPatternSection

            // Best Day/Time
            bestTimeSection
        }
        .padding(.vertical)
    }

    // MARK: - Partner Content

    var partnerContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // İlişki Timeline Widget
                if let _ = friend.relationshipStartDate {
                    RelationshipTimelineWidget(friend: friend)
                        .padding(.horizontal)
                }

                // Özel Günler
                SpecialDatesSection(friend: friend)
                    .padding(.horizontal)

                // Love Language Detayları
                if let _ = friend.loveLanguage {
                    LoveLanguageDetailCard(friend: friend)
                        .padding(.horizontal)
                }

                // Date Ideas
                DateIdeasSection(friend: friend)
                    .padding(.horizontal)

                // Partner Notes
                PartnerNotesSection(friend: friend)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Chat Content

    var chatContent: some View {
        VStack(spacing: 0) {
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        // Karşılama mesajı
                        if chatMessages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.purple.gradient)

                                Text(String(localized: "friend.ai.assistant", comment: "AI Assistant"))
                                    .font(.headline)

                                Text(String(format: NSLocalizedString("friend.ai.description.format", comment: "AI description"), friend.name))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                // Hızlı Aksiyonlar
                                VStack(spacing: 8) {
                                    Text(String(localized: "friend.quick.questions", comment: "Quick questions"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    QuickQuestionButton(question: String(localized: "friend.create.message.draft", comment: "Create message draft")) {
                                        userInput = "Bana \(friend.name) için bir mesaj taslağı oluşturabilir misin?"
                                    }

                                    QuickQuestionButton(question: String(localized: "friend.give.relationship.advice", comment: "Relationship advice")) {
                                        userInput = "\(friend.name) ile ilişkimi nasıl geliştirebilirim?"
                                    }

                                    QuickQuestionButton(question: String(localized: "friend.analyze.communication", comment: "Analyze communication")) {
                                        userInput = "\(friend.name) ile iletişim geçmişimi analiz et"
                                    }
                                }
                                .padding()
                            }
                            .padding(.vertical, 40)
                        } else {
                            // Mesajlar
                            ForEach(chatMessages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }

                        // Yükleniyor göstergesi
                        if isGeneratingAI {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(String(localized: "friend.ai.thinking", comment: "AI thinking"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatMessages.count) { _, _ in
                    if let lastMessage = chatMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input Area
            HStack(spacing: 12) {
                TextField("Bir soru sorun...", text: $userInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(isGeneratingAI)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: isGeneratingAI ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(userInput.isEmpty ? .gray : .blue)
                }
                .disabled(userInput.isEmpty && !isGeneratingAI)
            }
            .padding()
            .background(Color(.systemBackground))
        }
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

    var aiSuggestionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)
                Text(String(localized: "friend.ai.suggestion", comment: "AI suggestion"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)

                Spacer()

                if aiSuggestionText.isEmpty {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            Text(aiSuggestionText.isEmpty ? generateAISuggestion() : aiSuggestionText)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .onAppear {
            loadAISuggestionForOverview()
        }
    }

    var achievementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "friend.achievements", comment: "Achievements"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievementBadges, id: \.title) { badge in
                        AchievementBadge(badge: badge)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Transaction Section - REBUILT SAFELY

    var transactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Borç/Alacak", systemImage: "banknote")
                    .font(.headline)

                Spacer()

                Button {
                    showingAddTransaction = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }

            // Check if transactions exist
            if let transactions = friend.transactions, !transactions.isEmpty {
                VStack(spacing: 12) {
                    // Balance Summary
                    balanceSummaryView(transactions: transactions)

                    // Transactions list
                    ForEach(transactions.sorted(by: { $0.date > $1.date }), id: \.id) { transaction in
                        HStack(alignment: .top, spacing: 12) {
                            // Icon based on type
                            Image(systemName: transaction.transactionType == .debt ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.title3)
                                .foregroundStyle(transaction.transactionType == .debt ? .red : .green)

                            // Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(transaction.transactionDescription)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(transaction.transactionType.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                // Due Date Info
                                if let dueDate = transaction.dueDate, !transaction.isPaid {
                                    if let days = transaction.daysUntilDue {
                                        if days < 0 {
                                            // Overdue
                                            Text(String(format: NSLocalizedString("transaction.overdue.days", comment: "Overdue by X days"), abs(days)))
                                                .font(.caption2)
                                                .foregroundStyle(.red)
                                                .fontWeight(.semibold)
                                        } else if days == 0 {
                                            Text(String(localized: "transaction.due.today", comment: "Due today"))
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                                .fontWeight(.semibold)
                                        } else if days <= 3 {
                                            Text(String(format: NSLocalizedString("transaction.due.within.days", comment: "Due within X days"), days))
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        } else {
                                            Text(String(format: NSLocalizedString("transaction.due.days", comment: "Due in X days"), days))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }

                            Spacer()

                            // Amount
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(transaction.amount.description) \(transaction.currency)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(transaction.transactionType == .debt ? .red : .green)

                                if !transaction.isPaid {
                                    Text(String(localized: "transaction.unpaid", comment: "Unpaid"))
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                } else {
                                    Text(String(localized: "transaction.paid", comment: "Paid"))
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .padding(12)
                        .background(transaction.isOverdue && !transaction.isPaid ? Color.red.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(transaction.isOverdue && !transaction.isPaid ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                        .contextMenu {
                            // Mark as Paid/Unpaid
                            if !transaction.isPaid {
                                Button {
                                    markTransactionAsPaid(transaction)
                                } label: {
                                    Label("Ödendi Olarak İşaretle", systemImage: "checkmark.circle")
                                }
                            } else {
                                Button {
                                    markTransactionAsUnpaid(transaction)
                                } label: {
                                    Label("Ödenmedi Olarak İşaretle", systemImage: "xmark.circle")
                                }
                            }

                            Divider()

                            // Delete
                            Button(role: .destructive) {
                                deleteTransaction(transaction)
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
            } else {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "banknote")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.5))

                    Text(String(localized: "transaction.empty", comment: "No transaction records"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        showingAddTransaction = true
                    } label: {
                        Text(String(localized: "transaction.add.first", comment: "Add first transaction"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionSheet(friend: friend)
        }
    }

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

    var miniCalendarView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "friend.last.30.days", comment: "Last 30 days"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(getLast30Days(), id: \.self) { date in
                    let hasContact = checkContactOnDate(date)
                    Circle()
                        .fill(hasContact ? Color.green : Color(.systemGray5))
                        .frame(height: 28)
                        .overlay(
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption2)
                                .foregroundStyle(hasContact ? .white : .secondary)
                        )
                }
            }
            .padding(.horizontal)
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

    var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(String(localized: "friend.no.history.yet", comment: "No history yet"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Helper Properties

    var sortedHistory: [ContactHistory]? {
        friend.contactHistory?.sorted(by: { $0.date > $1.date })
    }

    var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: friend.createdAt, to: Date()).day ?? 0
    }

    var currentStreak: Int {
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

    var relationshipHealthScore: Int {
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

    var healthScoreColor: Color {
        switch relationshipHealthScore {
        case 80...100: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    var averageMoodScore: Double? {
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

    var achievementBadges: [FriendAchievement] {
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

    var communicationTrend: String {
        guard let history = friend.contactHistory, history.count > 2 else { return "-" }

        let recent = history.suffix(3).count
        let old = history.prefix(max(3, history.count - 3)).count

        if recent > old {
            return "↗"
        } else if recent < old {
            return "↘"
        } else {
            return "→"
        }
    }

    var trendColor: Color {
        switch communicationTrend {
        case "↗": return .green
        case "↘": return .red
        default: return .gray
        }
    }

    var averageGapDays: String {
        guard let history = friend.contactHistory, history.count > 1 else { return "-" }

        let sorted = history.sorted(by: { $0.date < $1.date })
        var totalGap = 0

        for i in 1..<sorted.count {
            let gap = Calendar.current.dateComponents([.day], from: sorted[i-1].date, to: sorted[i].date).day ?? 0
            totalGap += gap
        }

        let average = totalGap / (sorted.count - 1)
        return "\(average)g"
    }

    var bestDayForContact: String {
        guard let history = friend.contactHistory, !history.isEmpty else { return "Veri yok" }

        let weekdayCounts = Dictionary(grouping: history) { contact in
            Calendar.current.component(.weekday, from: contact.date)
        }.mapValues { $0.count }

        guard let bestDay = weekdayCounts.max(by: { $0.value < $1.value })?.key else {
            return "Veri yok"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.weekdaySymbols[bestDay - 1]
    }

    // MARK: - Helper Functions

    func getLast30Days() -> [Date] {
        (0..<30).compactMap { dayOffset in
            Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())
        }.reversed()
    }

    func checkContactOnDate(_ date: Date) -> Bool {
        guard let history = friend.contactHistory else { return false }
        return history.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func getMonthlyData() -> [MonthlyData] {
        guard let history = friend.contactHistory else { return [] }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: history) { contact in
            let components = calendar.dateComponents([.year, .month], from: contact.date)
            return calendar.date(from: components)!
        }

        let sorted = grouped.sorted { $0.key < $1.key }
        let last3Months = Array(sorted.suffix(3))

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "tr_TR")

        return last3Months.map { date, contacts in
            MonthlyData(month: formatter.string(from: date), count: contacts.count)
        }
    }

    func getMoodDistribution() -> [MoodData] {
        guard let history = friend.contactHistory?.compactMap({ $0.mood }), !history.isEmpty else { return [] }

        let grouped = Dictionary(grouping: history) { $0 }
        return grouped.map { mood, items in
            MoodData(mood: mood.emoji + " " + mood.displayName, count: items.count)
        }.sorted { $0.count > $1.count }
    }

    func generateAISuggestion() -> String {
        let suggestions = [
            "Bugün güzel bir gün! Belki kahve içmek için arayabilirsiniz.",
            "Hafta sonu yaklaşıyor, birlikte bir aktivite planlayabilirsiniz.",
            "Son zamanlarda yoğun görünüyorsunuz. Kısa bir mesaj atın!",
            "Düzenli iletişiminiz harika! Bu şekilde devam edin.",
            "Bir süredir görüşmediniz. Nasıl olduklarını öğrenebilirsiniz."
        ]

        // Defensive programming: Array bounds check
        let defaultSuggestion = "İletişim zamanı! Bir mesaj gönderin."

        let index: Int
        if friend.needsContact {
            index = 4
        } else if friend.daysRemaining <= 2 {
            index = 2
        } else if currentStreak > 5 {
            index = 3
        } else {
            index = 0
        }

        guard index < suggestions.count else {
            print("⚠️ Array index out of bounds: \(index)")
            return defaultSuggestion
        }

        return suggestions[index]
    }

    // MARK: - AI Chat Actions

    func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Empty input, returning")
            return
        }

        print("📤 Sending message: '\(userInput)'")

        let userMessage = ChatMessage(content: userInput, isUser: true)
        chatMessages.append(userMessage)

        let question = userInput
        userInput = ""
        isGeneratingAI = true

        print("⏳ Starting AI generation...")

        Task {
            let response: String

            if #available(iOS 26.0, *) {
                print("🔍 iOS 26+ available, trying Foundation Models...")
                // iOS 26+ için Foundation Models dene
                do {
                    response = try await generateContextualResponse(for: friend, question: question)
                    print("✅ Foundation Models response received: \(response)")
                } catch {
                    print("⚠️ Foundation Models failed: \(error)")
                    print("🔄 Using fallback response...")
                    // Model yoksa gelişmiş fallback kullan
                    response = await generateFallbackResponse(for: friend, question: question)
                    print("✅ Fallback response: \(response)")
                }
            } else {
                print("📱 iOS < 26, using fallback directly")
                // iOS 17-25 için gelişmiş fallback
                response = await generateFallbackResponse(for: friend, question: question)
                print("✅ Fallback response: \(response)")
            }

            print("💬 Adding AI message to chat")

            await MainActor.run {
                let aiMessage = ChatMessage(content: response, isUser: false)
                chatMessages.append(aiMessage)
                isGeneratingAI = false
                print("✅ Message added, generation complete")
            }
        }
    }

    @available(iOS 26.0, *)
    func generateContextualResponse(for friend: Friend, question: String) async throws -> String {
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: {
                """
                Sen yardımcı bir asistansın ve kullanıcının arkadaşlık ilişkilerini güçlendirmesine yardımcı oluyorsun.
                Arkadaş hakkında bilgileri kullanarak soruları yanıtla.
                Her zaman Türkçe yanıt ver.
                Samimi, dostça ve motive edici ol.
                Kısa ve öz cevaplar ver (maksimum 3 cümle).
                """
            }
        )

        var prompt = """
        Kullanıcı, arkadaşı \(friend.name) hakkında şunu soruyor: "\(question)"

        Arkadaş bilgileri:
        - İsim: \(friend.name)
        - İletişim sıklığı: \(friend.frequency.displayName)
        """

        if friend.needsContact {
            prompt += "\n- Durum: \(friend.daysOverdue) gündür iletişim kurulmamış"
        } else {
            prompt += "\n- Durum: Sonraki iletişime \(friend.daysRemaining) gün var"
        }

        if let lastContact = friend.lastContactDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "tr_TR")
            prompt += "\n- Son iletişim: \(formatter.string(from: lastContact))"
        }

        if let history = friend.contactHistory, !history.isEmpty {
            prompt += "\n- Toplam \(history.count) kez görüşmüşler"
        }

        if let notes = friend.notes, !notes.isEmpty {
            prompt += "\n- Notlar: \(notes)"
        }

        prompt += "\n\nLütfen soruyu yanıtla. Arkadaşın adını kullan ve samimi ol."

        let response = try await session.respond(to: prompt)
        return response.content
    }

    func generateFallbackResponse(for friend: Friend, question: String) async -> String {
        let lowercased = question.lowercased()

        print("📝 Question: \(question)")
        print("👤 Friend: \(friend.name), needsContact: \(friend.needsContact), daysOverdue: \(friend.daysOverdue)")

        // Mesaj taslağı
        if lowercased.contains("mesaj") || lowercased.contains("taslak") || lowercased.contains("yaz") {
            if friend.needsContact {
                return "Selam \(friend.name)! Nasılsın? \(friend.daysOverdue) gündür görüşemedik, çok merak ettim. Bu hafta bir kahve içmeye ne dersin? ☕"
            } else {
                return "Merhaba \(friend.name)! Nasıl gidiyor? Uzun zamandır buluşamadık, müsait olduğunda bir araya gelelim mi?"
            }
        }

        // Zamanlama soruları
        else if lowercased.contains("ne zaman") || lowercased.contains("zaman") {
            if friend.needsContact {
                return "\(friend.name) ile \(friend.daysOverdue) gündür görüşmediniz. Hemen bugün veya yarın aramayı düşünebilirsiniz. Ne kadar erken o kadar iyi! 📞"
            } else {
                return "\(friend.name) ile sonraki görüşmenize \(friend.daysRemaining) gün var. Ama şimdi de arayabilirsiniz, sürpriz yapmış olursunuz! 😊"
            }
        }

        // Öneri soruları
        else if lowercased.contains("öneri") || lowercased.contains("tavsiye") || lowercased.contains("nasıl") {
            if friend.isImportant {
                return "\(friend.name) önemli bir arkadaşınız. Özel günlerini hatırlayın, küçük sürprizler yapın ve düzenli iletişimi koruyun. ⭐"
            } else if friend.needsContact {
                return "\(friend.name) ile iletişim gerekiyor. Hemen bir mesaj atın veya arayın. 'Nasılsın?' diye sormak yeterli! 💬"
            } else {
                return "\(friend.name) ile ilişkiniz iyi gidiyor. Mevcut tempoyu koruyun, ara sıra sohbet edin ve ortak aktiviteler planlayın. 👍"
            }
        }

        // Başka öneri
        else if lowercased.contains("başka") || lowercased.contains("daha") || lowercased.contains("var mı") {
            let suggestions = [
                "Eski fotoğraflarınızdan birini paylaşıp nostalji yapabilirsiniz 📸",
                "Ortak ilgi alanlarınız hakkında konuşun, belki yeni bir aktivite planlarsınız 🎯",
                "Sesli mesaj gönderin, yazılı mesajdan daha samimi olur 🎤",
                "Bir sonraki buluşmanızı planlayın, somut tarih koyun 📅",
                "Arkadaşınızın önemli günlerini not alın ve kutlayın 🎉"
            ]
            return suggestions.randomElement() ?? suggestions[0]
        }

        // Genel yardım
        else {
            return "\(friend.name) hakkında size nasıl yardımcı olabilirim?\n\n• Mesaj taslağı oluşturabilirim\n• Ne zaman arayacağınızı önerebilirim\n• İlişkinizi geliştirme tavsiyeleri verebilirim\n\nSormak istediğiniz bir şey var mı?"
        }
    }

    func loadAISuggestionForOverview() {
        guard aiSuggestionText.isEmpty else { return }

        Task {
            do {
                let suggestion: String

                if #available(iOS 26.0, *) {
                    suggestion = try await FriendAIService.shared.generateSuggestion(for: friend)
                } else {
                    suggestion = await FriendAIServiceFallback.shared.generateSuggestion(for: friend)
                }

                await MainActor.run {
                    aiSuggestionText = suggestion
                }
            } catch {
                print("❌ AI öneri yüklenemedi: \(error)")
            }
        }
    }

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

    func deleteHistory(_ item: ContactHistory) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)

        // Remove from friend's transactions array
        if let index = friend.transactions?.firstIndex(where: { $0.id == transaction.id }) {
            friend.transactions?.remove(at: index)
        }

        do {
            try modelContext.save()
            HapticFeedback.success()
        } catch {
            print("❌ Transaction silinemedi: \(error)")
        }
    }

    func markTransactionAsPaid(_ transaction: Transaction) {
        transaction.isPaid = true
        transaction.paidDate = Date()
        transaction.paidAmount = transaction.amount

        do {
            try modelContext.save()
            HapticFeedback.success()
        } catch {
            print("❌ Transaction güncellenemedi: \(error)")
        }
    }

    func markTransactionAsUnpaid(_ transaction: Transaction) {
        transaction.isPaid = false
        transaction.paidDate = nil
        transaction.paidAmount = 0

        do {
            try modelContext.save()
            HapticFeedback.success()
        } catch {
            print("❌ Transaction güncellenemedi: \(error)")
        }
    }

    @ViewBuilder
    func balanceSummaryView(transactions: [Transaction]) -> some View {
        let unpaidTransactions = transactions.filter { !$0.isPaid }

        if !unpaidTransactions.isEmpty {
            let totalDebt = unpaidTransactions.filter { $0.transactionType == .debt }.reduce(Decimal(0)) { $0 + $1.amount }
            let totalCredit = unpaidTransactions.filter { $0.transactionType == .credit }.reduce(Decimal(0)) { $0 + $1.amount }
            let balance = totalCredit - totalDebt

            HStack(spacing: 12) {
                // Net Balance
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Durum")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if balance > 0 {
                        Text("+ \(balance.description) TL")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    } else if balance < 0 {
                        Text("- \(abs(balance).description) TL")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                    } else {
                        Text("Dengede")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()

                // Badges
                HStack(spacing: 8) {
                    if totalDebt > 0 {
                        VStack(spacing: 2) {
                            Text(String(localized: "transaction.debt", comment: "Debt"))
                                .font(.caption2)
                            Text("\(totalDebt.description) TL")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
                    }

                    if totalCredit > 0 {
                        VStack(spacing: 2) {
                            Text("Alacak")
                                .font(.caption2)
                            Text("\(totalCredit.description) TL")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TL"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "₺\(amount)"
    }
}

// MARK: - Transaction Row Component - REMOVED FOR DEBUGGING

