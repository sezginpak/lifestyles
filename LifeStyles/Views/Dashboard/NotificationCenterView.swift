//
//  NotificationCenterView.swift
//  LifeStyles
//
//  Created by Claude on 06.11.2025.
//  Modern bildirim merkezi - Gruplandırılmış, swipe actions, glassmorphism
//

import SwiftUI
import SwiftData

struct NotificationCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var notifications: [DashboardNotification] = []
    @State private var selectedFilter: NotificationFilter = .all
    @State private var isLoading = false
    @State private var showingCompact = false
    @State private var searchText = ""

    private let notificationService = NotificationService.shared

    enum NotificationFilter: String, CaseIterable, Identifiable {
        case all = "Tümü"
        case unread = "Okunmamış"
        case contacts = "İletişim"
        case goals = "Hedefler"
        case habits = "Alışkanlıklar"
        case achievements = "Başarılar"
        case insights = "Öneriler"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: return "tray.fill"
            case .unread: return "circle.fill"
            case .contacts: return "person.2.fill"
            case .goals: return "target"
            case .habits: return "checkmark.circle.fill"
            case .achievements: return "trophy.fill"
            case .insights: return "lightbulb.fill"
            }
        }

        var color: Color {
            switch self {
            case .all: return .blue
            case .unread: return .red
            case .contacts: return .purple
            case .goals: return .green
            case .habits: return .orange
            case .achievements: return .yellow
            case .insights: return .pink
            }
        }

        var gradient: LinearGradient {
            switch self {
            case .all:
                return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .unread:
                return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .contacts:
                return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .goals:
                return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .habits:
                return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .achievements:
                return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .insights:
                return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }

    var filteredNotifications: [DashboardNotification] {
        let filtered: [DashboardNotification]

        switch selectedFilter {
        case .all:
            filtered = notifications
        case .unread:
            filtered = notifications.filter { !$0.isRead }
        default:
            filtered = notifications.filter { $0.type.filter == selectedFilter }
        }

        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.message.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var groupedNotifications: [(String, [DashboardNotification])] {
        let calendar = Calendar.current
        let now = Date()

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let thisWeek = calendar.date(byAdding: .day, value: -7, to: now)!

        var groups: [(String, [DashboardNotification])] = []

        let todayNotifs = filteredNotifications.filter { calendar.isDateInToday($0.date) }
        let yesterdayNotifs = filteredNotifications.filter { calendar.isDateInYesterday($0.date) }
        let thisWeekNotifs = filteredNotifications.filter {
            $0.date >= thisWeek && $0.date < yesterday && !calendar.isDateInYesterday($0.date)
        }
        let olderNotifs = filteredNotifications.filter { $0.date < thisWeek }

        if !todayNotifs.isEmpty {
            groups.append((String(localized: "notification.group.today", comment: "Bugün"), todayNotifs))
        }
        if !yesterdayNotifs.isEmpty {
            groups.append((String(localized: "notification.group.yesterday", comment: "Dün"), yesterdayNotifs))
        }
        if !thisWeekNotifs.isEmpty {
            groups.append((String(localized: "notification.group.this.week", comment: "Bu Hafta"), thisWeekNotifs))
        }
        if !olderNotifs.isEmpty {
            groups.append((String(localized: "notification.group.older", comment: "Daha Eski"), olderNotifs))
        }

        return groups
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground()
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if notifications.isEmpty {
                    emptyState
                } else {
                    mainContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    headerView
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticFeedback.light()
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 32, height: 32)

                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !notifications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    showingCompact.toggle()
                                }
                            } label: {
                                Label(
                                    showingCompact ? "Detaylı Görünüm" : "Kompakt Görünüm",
                                    systemImage: showingCompact ? "list.bullet" : "square.grid.2x2"
                                )
                            }

                            Divider()

                            Button {
                                markAllAsRead()
                            } label: {
                                Label(String(localized: "notification.mark.all.read", comment: ""), systemImage: "checkmark.circle")
                            }

                            Button(role: .destructive) {
                                clearAll()
                            } label: {
                                Label(String(localized: "notification.clear.all", comment: ""), systemImage: "trash")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 32, height: 32)

                                Image(systemName: "ellipsis")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .task {
                await loadNotifications()
            }
            .refreshable {
                await loadNotifications()
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Bildirim ara..."
            )
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 2) {
            Text(String(localized: "dashboard.notifications.title", comment: "Notifications title"))
                .font(.headline)
                .foregroundStyle(.primary)

            if unreadCount > 0 {
                Text(String(localized: "dashboard.notifications.unread.count", defaultValue: "\(unreadCount) unread", comment: "Unread count"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filter Section
                filterSection

                // Notifications by group
                LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                    ForEach(groupedNotifications, id: \.0) { group in
                        Section {
                            LazyVStack(spacing: 12) {
                                ForEach(group.1) { notification in
                                    if showingCompact {
                                        CompactNotificationCard(
                                            notification: notification,
                                            onTap: { handleNotificationTap(notification) },
                                            onDelete: { deleteNotification(notification) }
                                        )
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .move(edge: .trailing).combined(with: .opacity)
                                        ))
                                    } else {
                                        ModernNotificationCard(
                                            notification: notification,
                                            onTap: { handleNotificationTap(notification) },
                                            onDelete: { deleteNotification(notification) }
                                        )
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .move(edge: .trailing).combined(with: .opacity)
                                        ))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } header: {
                            GroupHeader(title: group.0)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NotificationFilter.allCases) { filter in
                    FilterPill(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getFilterCount(filter)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                            HapticFeedback.light()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.primary)

            Text(String(localized: "dashboard.notifications.loading", comment: "Loading notifications"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: selectedFilter == .unread ? "tray" : "bell.slash.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)

            VStack(spacing: 8) {
                Text(selectedFilter == .all
                     ? String(localized: "notification.center.empty.title", comment: "Bildirim Yok")
                     : "Filtre Sonucu Yok")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text(selectedFilter == .all
                     ? String(localized: "notification.center.empty.message", comment: "Yeni hatırlatmalar burada görünecek")
                     : "Bu kategoride bildirim bulunmuyor")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if selectedFilter != .all {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = .all
                    }
                } label: {
                    Text(String(localized: "dashboard.notifications.show.all", comment: "Show all notifications"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadNotifications() async {
        isLoading = true
        defer { isLoading = false }

        // 1. Gerçek bildirimleri NotificationService'den al
        let realNotifications = await notificationService.getAllNotificationsForDashboard()

        // 2. SwiftData'dan oluşturulan bildirimleri ekle
        var generatedNotifications: [DashboardNotification] = []

        generatedNotifications.append(contentsOf: loadContactReminders())
        generatedNotifications.append(contentsOf: loadGoalDeadlines())
        generatedNotifications.append(contentsOf: loadHabitReminders())
        generatedNotifications.append(contentsOf: loadAchievementNotifications())
        generatedNotifications.append(contentsOf: loadInsightNotifications())

        // 3. Birleştir ve duplicate'leri filtrele
        var combinedNotifications = realNotifications
        let realActionIds = Set(realNotifications.compactMap { $0.actionData?.values.first })

        for notification in generatedNotifications {
            if let actionId = notification.actionData?.values.first,
               !realActionIds.contains(actionId) {
                combinedNotifications.append(notification)
            } else if notification.actionData == nil {
                combinedNotifications.append(notification)
            }
        }

        // 4. Tarihe göre sırala
        notifications = combinedNotifications.sorted { $0.date > $1.date }
    }

    private func loadContactReminders() -> [DashboardNotification] {
        guard let friends = try? modelContext.fetch(FetchDescriptor<Friend>()) else { return [] }

        var reminders: [DashboardNotification] = []

        for friend in friends where friend.needsContact {
            let daysSince: Int
            if let lastContact = friend.lastContactDate {
                daysSince = Calendar.current.dateComponents([.day], from: lastContact, to: Date()).day ?? 0
            } else {
                daysSince = 0
            }

            reminders.append(
                DashboardNotification(
                    type: .contactReminder,
                    title: "\(friend.name) ile iletişim zamanı",
                    message: daysSince > 0 ? "\(daysSince) gündür görüşmediniz. Bir selam verin!" : "Görüşme zamanı geldi!",
                    date: Date(),
                    isRead: false,
                    actionData: ["friendId": friend.id.uuidString]
                )
            )
        }

        return reminders
    }

    private func loadGoalDeadlines() -> [DashboardNotification] {
        guard let goals = try? modelContext.fetch(FetchDescriptor<Goal>()) else { return [] }
        let activeGoals = goals.filter { !$0.isCompleted }

        var deadlines: [DashboardNotification] = []

        for goal in activeGoals {
            let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: goal.targetDate).day ?? 0

            if daysUntilDeadline <= 3 && daysUntilDeadline >= 0 {
                deadlines.append(
                    DashboardNotification(
                        type: .goalDeadline,
                        title: goal.title,
                        message: "Hedef tarihe \(daysUntilDeadline) gün kaldı!",
                        date: Date(),
                        isRead: false,
                        actionData: ["goalId": goal.id.uuidString]
                    )
                )
            }
        }

        return deadlines
    }

    private func loadHabitReminders() -> [DashboardNotification] {
        guard let habits = try? modelContext.fetch(FetchDescriptor<Habit>()) else { return [] }
        let activeHabits = habits.filter { $0.isActive }

        var reminders: [DashboardNotification] = []

        for habit in activeHabits where !habit.isCompletedToday() {
            reminders.append(
                DashboardNotification(
                    type: .habitReminder,
                    title: habit.name,
                    message: "Bugün henüz tamamlanmadı",
                    date: Date(),
                    isRead: false,
                    actionData: ["habitId": habit.id.uuidString]
                )
            )
        }

        return reminders
    }

    private func loadAchievementNotifications() -> [DashboardNotification] {
        return []
    }

    private func loadInsightNotifications() -> [DashboardNotification] {
        return []
    }

    private func handleNotificationTap(_ notification: DashboardNotification) {
        Task {
            await markAsRead(notification)
        }
        // TODO: Navigation logic
    }

    private func deleteNotification(_ notification: DashboardNotification) {
        withAnimation(.spring(response: 0.3)) {
            notifications.removeAll { $0.id == notification.id }
        }

        Task {
            await notificationService.cancelNotification(identifier: notification.id.uuidString)
        }

        HapticFeedback.success()
    }

    private func markAsRead(_ notification: DashboardNotification) async {
        await notificationService.markNotificationAsRead(identifier: notification.id.uuidString)

        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }

    private func markAllAsRead() {
        Task {
            await notificationService.markAllNotificationsAsRead()

            for index in notifications.indices {
                notifications[index].isRead = true
            }
        }

        HapticFeedback.success()
    }

    private func clearAll() {
        Task {
            await notificationService.clearAllNotifications()
            withAnimation(.spring(response: 0.3)) {
                notifications.removeAll()
            }
        }

        HapticFeedback.success()
    }

    private func getFilterCount(_ filter: NotificationFilter) -> Int {
        switch filter {
        case .all:
            return notifications.count
        case .unread:
            return unreadCount
        default:
            return notifications.filter { $0.type.filter == filter }.count
        }
    }
}

// MARK: - Modern Notification Card

struct ModernNotificationCard: View {
    let notification: DashboardNotification
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGSize = .zero
    @State private var isDeleting = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            deleteBackground

            // Main card
            cardContent
                .offset(x: offset.width)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3)) {
                                if value.translation.width < -80 {
                                    offset = CGSize(width: -80, height: 0)
                                } else {
                                    offset = .zero
                                }
                            }
                        }
                )
        }
        .onChange(of: isDeleting) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3)) {
                    offset = CGSize(width: -UIScreen.main.bounds.width, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDelete()
                }
            }
        }
    }

    private var deleteBackground: some View {
        HStack {
            Spacer()
            Button {
                HapticFeedback.warning()
                isDeleting = true
            } label: {
                Image(systemName: "trash.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 60)
            }
        }
        .frame(maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.red, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var cardContent: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(notification.type.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: notification.type.icon)
                        .font(.title2)
                        .foregroundStyle(notification.type.gradient)
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))

                        Text(notification.date.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        notification.isRead
                            ? Color.clear
                            : notification.type.color.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: notification.isRead
                    ? .black.opacity(0.05)
                    : notification.type.color.opacity(0.15),
                radius: notification.isRead ? 4 : 8,
                x: 0,
                y: notification.isRead ? 2 : 4
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Notification Card

struct CompactNotificationCard: View {
    let notification: DashboardNotification
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGSize = .zero
    @State private var isDeleting = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            deleteBackground

            // Compact card
            cardContent
                .offset(x: offset.width)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3)) {
                                if value.translation.width < -80 {
                                    offset = CGSize(width: -80, height: 0)
                                } else {
                                    offset = .zero
                                }
                            }
                        }
                )
        }
        .onChange(of: isDeleting) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3)) {
                    offset = CGSize(width: -UIScreen.main.bounds.width, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDelete()
                }
            }
        }
    }

    private var deleteBackground: some View {
        HStack {
            Spacer()
            Button {
                HapticFeedback.warning()
                isDeleting = true
            } label: {
                Image(systemName: "trash.fill")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 60)
            }
        }
        .frame(maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.red, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var cardContent: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Compact icon
                Image(systemName: notification.type.icon)
                    .font(.body)
                    .foregroundStyle(notification.type.gradient)
                    .frame(width: 32, height: 32)
                    .background(notification.type.color.opacity(0.1))
                    .clipShape(Circle())

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(notification.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if !notification.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let filter: NotificationCenterView.NotificationFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.caption)

                Text(filter.rawValue)
                    .font(.caption.weight(.medium))

                if count > 0 {
                    Text(String(localized: "dashboard.notifications.badge.count", defaultValue: "\(count)", comment: "Badge count"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSelected ? filter.color : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white : filter.color)
                        )
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        filter.gradient
                    } else {
                        LinearGradient(
                            colors: [.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : filter.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(
                color: isSelected ? filter.color.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Group Header

struct GroupHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Animated Gradient Background

private struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color.blue.opacity(0.05),
                Color.purple.opacity(0.05),
                Color(.systemGroupedBackground)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Dashboard Notification Model

struct DashboardNotification: Identifiable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let date: Date
    var isRead: Bool
    var actionData: [String: String]?

    /// Default initializer - UUID otomatik oluşturulur
    init(
        type: NotificationType,
        title: String,
        message: String,
        date: Date,
        isRead: Bool,
        actionData: [String: String]? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
        self.actionData = actionData
    }

    /// String identifier ile initializer (NotificationService entegrasyonu için)
    init(
        identifier: String,
        type: NotificationType,
        title: String,
        message: String,
        date: Date,
        isRead: Bool,
        actionData: [String: String]? = nil
    ) {
        // String identifier'dan UUID oluştur (tutarlı olması için)
        if let uuid = UUID(uuidString: identifier) {
            self.id = uuid
        } else {
            // Identifier UUID formatında değilse hash kullanarak UUID oluştur
            self.id = UUID()
        }
        self.type = type
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
        self.actionData = actionData
    }

    enum NotificationType {
        case contactReminder
        case goalDeadline
        case habitReminder
        case achievement
        case insight
        case system

        var icon: String {
            switch self {
            case .contactReminder: return "person.2.fill"
            case .goalDeadline: return "target"
            case .habitReminder: return "checkmark.circle.fill"
            case .achievement: return "trophy.fill"
            case .insight: return "lightbulb.fill"
            case .system: return "bell.fill"
            }
        }

        var color: Color {
            switch self {
            case .contactReminder: return .purple
            case .goalDeadline: return .green
            case .habitReminder: return .orange
            case .achievement: return .yellow
            case .insight: return .pink
            case .system: return .blue
            }
        }

        var gradient: LinearGradient {
            switch self {
            case .contactReminder:
                return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .goalDeadline:
                return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .habitReminder:
                return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .achievement:
                return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .insight:
                return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .system:
                return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }

        var filter: NotificationCenterView.NotificationFilter {
            switch self {
            case .contactReminder: return .contacts
            case .goalDeadline: return .goals
            case .habitReminder: return .habits
            case .achievement: return .achievements
            case .insight: return .insights
            case .system: return .all
            }
        }
    }
}

#Preview {
    NotificationCenterView()
        .modelContainer(for: [Friend.self, Goal.self, Habit.self])
}
