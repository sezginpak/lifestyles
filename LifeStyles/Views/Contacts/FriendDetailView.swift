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
                        Label("Düzenle", systemImage: "pencil")
                    }

                    Button {
                        showingAISuggestion.toggle()
                    } label: {
                        Label("AI Öneri", systemImage: "sparkles")
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
            Text("\(friend.name) adlı kişiyi silmek istediğinizden emin misiniz?")
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
            .frame(height: 240)
            .overlay(
                // Glassmorphism effect
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.clear,
                        Color.black.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            VStack(spacing: 16) {
                // Hero Avatar Section
                VStack(spacing: 12) {
                    // Floating Avatar with rings
                    FriendAvatarAdvancedView(
                        friend: friend,
                        size: 90,
                        accentColor: relationshipAccentColor
                    )

                    // Name and Relationship Type
                    VStack(spacing: 6) {
                        Text(friend.name)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)

                        HStack(spacing: 6) {
                            Text(friend.relationshipType.emoji)
                                .font(.caption)
                            Text(friend.relationshipType.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.3))
                        .clipShape(Capsule())

                        if let phone = friend.phoneNumber {
                            Text(phone)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 8)

                // Stats Row - Scrollable badges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
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
                                label: "Ay Birlikte",
                                color: .pink
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Quick Actions - Compact 2x2 grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    if let _ = friend.phoneNumber {
                        QuickActionCompactButton(
                            icon: "phone.fill",
                            label: "Ara",
                            colors: [.green, .green.opacity(0.8)]
                        ) {
                            callFriend()
                        }

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

            Text("\(relationshipHealthScore)%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(healthScoreColor)

            Text("İlişki Sağlığı")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(healthScoreColor.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Overview Content

}
