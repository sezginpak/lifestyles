//
//  FriendDetailView.swift
//  LifeStyles
//
//  Created by Claude on 16.10.2025.
//  Enhanced Version with AI Features
//

import SwiftUI
import SwiftData
import Charts
import FoundationModels

struct FriendDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    let friend: Friend
    @State var showingEditSheet = false
    @State var showingAddHistorySheet = false
    @State var showingDeleteAlert = false
    @State var noteText: String = ""
    @State var scrollOffset: CGFloat = 0
    @State var selectedTab: DetailTab = .overview
    @State var showingAISuggestion = false
    @State var showingAIChat = false

    // AI Chat States
    @State var chatMessages: [ChatMessage] = []
    @State var userInput: String = ""
    @State var isGeneratingAI = false
    @State var aiSuggestionText: String = ""

    // Transaction State
    @State var showingAddTransaction = false

    enum DetailTab: String {
        case overview = "Genel"
        case history = "Geçmiş"
        case insights = "Analiz"
        case partner = "Partner"

        static func tabs(for friend: Friend) -> [DetailTab] {
            if friend.isPartner {
                return [.overview, .history, .insights, .partner]
            } else {
                return [.overview, .history, .insights]
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Compact Paralax Header
                compactHeaderSection

                // Segmented Control
                Picker("", selection: $selectedTab) {
                    ForEach(DetailTab.tabs(for: friend), id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)

                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .history:
                        historyContent
                    case .insights:
                        insightsContent
                    case .partner:
                        partnerContent
                    }
                }
                .animation(.easeInOut, value: selectedTab)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAIChat = true
                    } label: {
                        Label("AI Chat", systemImage: "brain.head.profile")
                    }

                    Button {
                        showingEditSheet = true
                    } label: {
                        Label(String(localized: "common.edit", comment: "Edit"), systemImage: "pencil")
                    }

                    Button {
                        showingAISuggestion.toggle()
                    } label: {
                        Label(String(localized: "friends.ai.suggestion", comment: "AI Suggestion"), systemImage: "sparkles")
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditFriendView(friend: friend)
        }
        .sheet(isPresented: $showingAddHistorySheet) {
            AddContactHistoryView(friend: friend)
        }
        .sheet(isPresented: $showingAIChat) {
            FriendAIChatView(
                friend: friend,
                chatMessages: $chatMessages,
                userInput: $userInput,
                isGeneratingAI: $isGeneratingAI
            )
        }
        .alert("Arkadaşı Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                deleteFriend()
            }
        } message: {
            Text(String(format: NSLocalizedString("friends.delete.confirmation.format", comment: "Are you sure you want to delete %@?"), friend.name))
        }
        .onAppear {
            noteText = friend.notes ?? ""
        }
    }

    // MARK: - Compact Header

    var compactHeaderSection: some View {
        ZStack(alignment: .top) {
            // Dynamic Gradient Background based on RelationshipType
            LinearGradient(
                colors: relationshipGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)
            .overlay(
                // Glassmorphism effect
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.clear,
                        Color.black.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            VStack(spacing: 12) {
                // Hero Avatar Section
                VStack(spacing: 10) {
                    // Floating Avatar with rings
                    FriendAvatarAdvancedView(
                        friend: friend,
                        size: 80,
                        accentColor: relationshipAccentColor
                    )

                    // Name and Relationship Type
                    VStack(spacing: 4) {
                        Text(friend.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.primary)

                        HStack(spacing: 5) {
                            Text(friend.relationshipType.emoji)
                                .font(.caption2)
                            Text(friend.relationshipType.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Capsule())

                        if let phone = friend.phoneNumber {
                            Text(phone)
                                .font(.caption2)
                                .foregroundStyle(.secondary.opacity(0.8))
                        }
                    }
                }
                .padding(.top, 6)

                // Stats Row - Hafif ve kompakt badges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Health Score
                        StatsBadge(
                            icon: "heart.circle.fill",
                            value: "\(relationshipHealthScore)%",
                            label: "Sağlık",
                            color: healthScoreColor
                        )

                        // Streak
                        if currentStreak > 0 {
                            StatsBadge(
                                icon: "flame.fill",
                                value: "\(currentStreak)",
                                label: "Seri",
                                color: .orange
                            )
                        }

                        // Days since creation
                        StatsBadge(
                            icon: "calendar",
                            value: "\(daysSinceCreation)",
                            label: "Gün",
                            color: .purple
                        )

                        // Total contacts
                        StatsBadge(
                            icon: "phone.circle.fill",
                            value: "\(friend.totalContactCount)",
                            label: "İletişim",
                            color: .blue
                        )

                        // Partner specific: relationship duration
                        if friend.isPartner, let duration = friend.relationshipDuration {
                            let totalMonths = duration.years * 12 + duration.months
                            StatsBadge(
                                icon: "heart.fill",
                                value: "\(totalMonths)",
                                label: "Ay",
                                color: .pink
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 4)

                // Quick Actions - Compact 2x2 grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    if let _ = friend.phoneNumber {
                        QuickActionCompactButton(
                            icon: "phone.fill",
                            label: "Ara",
                            colors: [.green, .green.opacity(0.8)],
                            action: {
                                callFriend()
                            },
                            contextMenuItems: {
                                AnyView(
                                    Group {
                                        Button {
                                            callFriend()
                                        } label: {
                                            Label("Şimdi Ara", systemImage: "phone.fill")
                                        }

                                        Divider()

                                        Section("Hatırlatma Süresi (Dynamic Island)") {
                                            if #available(iOS 16.1, *) {
                                                Button {
                                                    NotificationService.shared.startLiveActivityReminder(for: friend, after: 1)
                                                    HapticFeedback.success()
                                                } label: {
                                                    Label("1 Dakika (Test)", systemImage: "circle.hexagongrid.fill")
                                                }

                                                Button {
                                                    NotificationService.shared.startLiveActivityReminder(for: friend, after: 15)
                                                    HapticFeedback.success()
                                                } label: {
                                                    Label("15 Dakika", systemImage: "circle.hexagongrid.fill")
                                                }

                                                Button {
                                                    NotificationService.shared.startLiveActivityReminder(for: friend, after: 30)
                                                    HapticFeedback.success()
                                                } label: {
                                                    Label("30 Dakika", systemImage: "circle.hexagongrid.fill")
                                                }

                                                Button {
                                                    NotificationService.shared.startLiveActivityReminder(for: friend, after: 60)
                                                    HapticFeedback.success()
                                                } label: {
                                                    Label("1 Saat", systemImage: "circle.hexagongrid.fill")
                                                }
                                            } else {
                                                // iOS 16 altı için fallback
                                                Text("Live Activity iOS 16.1+ gerektirir")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                )
                            }
                        )

                        QuickActionCompactButton(
                            icon: "message.fill",
                            label: "Mesaj",
                            colors: [.blue, .cyan]
                        ) {
                            sendSMS()
                        }
                    }

                    QuickActionCompactButton(
                        icon: "checkmark.circle.fill",
                        label: String(localized: "friend.action.mark.contacted", comment: "Mark as contacted quick action"),
                        colors: [.orange, .red]
                    ) {
                        markAsContacted()
                    }

                    QuickActionCompactButton(
                        icon: "sparkles.rectangle.stack.fill",
                        label: String(localized: "friend.action.ai.chat", comment: "AI Chat quick action button"),
                        colors: [.purple, .pink]
                    ) {
                        showingAIChat = true
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Relationship Colors

    var relationshipGradientColors: [Color] {
        switch friend.relationshipType {
        case .partner:
            return [
                Color.pink.opacity(0.4),
                Color.red.opacity(0.3),
                Color.purple.opacity(0.2),
                Color.clear
            ]
        case .family:
            return [
                Color.green.opacity(0.4),
                Color.mint.opacity(0.3),
                Color.teal.opacity(0.2),
                Color.clear
            ]
        case .colleague:
            return [
                Color.purple.opacity(0.4),
                Color.indigo.opacity(0.3),
                Color.blue.opacity(0.2),
                Color.clear
            ]
        case .friend:
            return [
                Color.blue.opacity(0.4),
                Color.cyan.opacity(0.3),
                Color.teal.opacity(0.2),
                Color.clear
            ]
        }
    }

    var relationshipAccentColor: Color {
        switch friend.relationshipType {
        case .partner: return .pink
        case .family: return .green
        case .colleague: return .purple
        case .friend: return .blue
        }
    }

    // MARK: - Health Score Badge

    var healthScoreBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(healthScoreColor)
                .frame(width: 8, height: 8)

            Text(String(format: NSLocalizedString("friends.health.percentage", comment: "Relationship health percentage"), relationshipHealthScore))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(healthScoreColor)

            Text(String(localized: "friends.relationship.health", comment: "Relationship Health"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(healthScoreColor.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Notes Section

    var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Notlar", systemImage: "note.text")
                    .font(.headline)
                Spacer()
            }

            if let notes = friend.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                Text("Not yok")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Enhanced Stat Card Component

struct EnhancedStatCard: View {
    let icon: String
    let value: String
    let label: String
    let gradient: LinearGradient
    let accentColor: Color

    var body: some View {
        VStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(gradient)
            }

            // Value
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.primary)

            // Label
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    gradient.opacity(0.3),
                    lineWidth: 1
                )
        )
        .shadow(color: accentColor.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Health Indicator Component

struct HealthIndicator: View {
    let icon: String
    let label: String
    let isGood: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(isGood ? .green : .red)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill((isGood ? Color.green : Color.red).opacity(0.1))
        )
    }
}

// MARK: - Modern Achievement Badge Component

struct ModernAchievementBadge: View {
    let badge: FriendAchievement

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [badge.color.opacity(0.2), badge.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: badge.icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [badge.color, badge.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(badge.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 80)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    badge.color.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}
