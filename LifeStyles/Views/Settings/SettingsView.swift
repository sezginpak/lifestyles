//
//  SettingsView.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var exportDataURL: URL?
    @State private var showImportPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showAppearanceSettings = false

    // Premium
    @State private var purchaseManager = PurchaseManager.shared
    @State private var usageManager = AIUsageManager.shared
    @State private var showPaywall = false

    // MARK: - Computed Properties

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.backgroundPrimary, Color.backgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var premiumGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var premiumBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var premiumBorderGradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppConstants.Spacing.large) {
                        // Ayarlar bölümleri
                        VStack(spacing: AppConstants.Spacing.medium) {
                            // Görünüm & Kişiselleştirme
                            SettingsSection(title: String(localized: "settings.personalization.title", comment: "Personalization")) {
                                Button {
                                    showAppearanceSettings = true
                                } label: {
                                    SettingsRow(
                                        icon: "paintbrush.fill",
                                        title: String(localized: "settings.appearance.profile", comment: "Appearance & Profile"),
                                        color: Color.purple
                                    )
                                }
                            }

                            // Dil Ayarları
                            SettingsSection(title: String(localized: "settings.language.section", comment: "Language")) {
                                NavigationLink {
                                    LanguageSettingsView()
                                } label: {
                                    SettingsRow(
                                        icon: "globe",
                                        title: String(localized: "settings.language.title", comment: "Language Settings"),
                                        color: Color.blue
                                    )
                                }
                            }

                            // İzinler
                            SettingsSection(title: String(localized: "settings.permissions.title", comment: "Permissions")) {
                                NavigationLink {
                                    PermissionsDetailView()
                                } label: {
                                    SettingsRow(
                                        icon: "lock.shield.fill",
                                        title: String(localized: "settings.app.permissions", comment: "App Permissions"),
                                        color: Color.brandPrimary
                                    )
                                }
                            }

                            // Bildirimler
                            SettingsSection(title: String(localized: "settings.notifications.title", comment: "Notifications")) {
                                NavigationLink {
                                    NotificationSettingsView()
                                } label: {
                                    SettingsRow(
                                        icon: "bell.fill",
                                        title: String(localized: "Bildirim Ayarları", comment: "Notification Settings"),
                                        color: Color.error
                                    )
                                }
                            }

                            // Konum
                            SettingsSection(title: String(localized: "settings.location.title", comment: "Location")) {
                                NavigationLink {
                                    LocationSettingsView()
                                } label: {
                                    SettingsRow(
                                        icon: "location.fill",
                                        title: String(localized: "Konum Ayarları", comment: "Location Settings"),
                                        color: Color.cardActivity
                                    )
                                }
                            }

                            // Premium
                            SettingsSection(title: String(localized: "settings.premium.title", comment: "Premium")) {
                                if purchaseManager.isInTrial {
                                    // Trial user - Show trial status
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "sparkles")
                                                .foregroundStyle(premiumGradient)
                                            Text(String(localized: "premium.trial.active"))
                                                .font(.headline)
                                            Spacer()
                                            Text(String(format: NSLocalizedString("premium.trial.days.remaining", comment: "%d days left"), purchaseManager.trialDaysRemaining))
                                                .font(.subheadline)
                                                .foregroundStyle(purchaseManager.trialDaysRemaining > 1 ? .blue : .orange)
                                        }

                                        Text(String(localized: "text.deneme.süresi.bitince.otomatik"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        // Usage stats - trial users have unlimited access
                                        let stats = usageManager.getUsageStats()
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text(String(localized: "settings.premium.ai.messages.today", comment: "AI messages used today:"))
                                                    .font(.caption)
                                                Spacer()
                                                Text(String(localized: "text.statstodaycount.sınırsız"))
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.green)
                                            }

                                            HStack {
                                                Text(String(localized: "settings.premium.total.messages", comment: "Total messages:"))
                                                    .font(.caption)
                                                Spacer()
                                                Text(String(format: NSLocalizedString("settings.premium.messages.count", comment: "X messages"), stats.totalAllTime))
                                                    .font(.caption.bold())
                                            }
                                        }
                                        .padding(.top, 8)

                                        // Manage subscription button
                                        Button {
                                            HapticFeedback.light()
                                            showPaywall = true
                                        } label: {
                                            HStack {
                                                Text(String(localized: "settings.manage.subscription", comment: "Manage Subscription"))
                                                    .font(.subheadline.bold())
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                            }
                                            .foregroundStyle(.blue)
                                        }
                                        .padding(.top, 8)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(premiumBackgroundGradient)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(premiumBorderGradient, lineWidth: 1)
                                    )
                                } else if purchaseManager.isPremium {
                                    // Premium user - Show status and manage
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "crown.fill")
                                                .foregroundStyle(.yellow)
                                            Text(String(localized: "settings.premium.member.status", comment: "You are a Premium Member"))
                                                .font(.headline)
                                            Spacer()
                                            Text(String(format: NSLocalizedString("settings.premium.price.month", comment: "X/month"), purchaseManager.monthlyPrice))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }

                                        Text(String(localized: "settings.premium.benefits.description", comment: "Unlimited AI chat, advanced analytics and priority support."))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        // Usage stats
                                        let stats = usageManager.getUsageStats()
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text(String(localized: "settings.premium.ai.messages.today", comment: "AI messages used today:"))
                                                    .font(.caption)
                                                Spacer()
                                                Text(String(format: NSLocalizedString("settings.premium.messages.count", comment: "X messages"), stats.todayCount))
                                                    .font(.caption.bold())
                                            }

                                            HStack {
                                                Text(String(localized: "settings.premium.total.messages", comment: "Total messages:"))
                                                    .font(.caption)
                                                Spacer()
                                                Text(String(format: NSLocalizedString("settings.premium.messages.count", comment: "X messages"), stats.totalAllTime))
                                                    .font(.caption.bold())
                                            }
                                        }
                                        .padding(.top, 8)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.yellow.opacity(0.1))
                                    )
                                } else {
                                    // Free user - Show upgrade option
                                    Button {
                                        HapticFeedback.medium()
                                        showPaywall = true
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Image(systemName: "crown.fill")
                                                    .foregroundStyle(.yellow)
                                                Text(String(localized: "settings.premium.upgrade", comment: "Upgrade to Premium"))
                                                    .font(.headline)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundStyle(.secondary)
                                            }

                                            Text(String(localized: "settings.premium.unlimited.features", comment: "Unlimited AI chat, advanced analytics"))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            // Free tier limits
                                            let stats = usageManager.getUsageStats()
                                            HStack {
                                                Text(String(format: NSLocalizedString("settings.premium.daily.usage.format", comment: "Today: X/Y messages"), stats.todayCount, stats.dailyLimit))
                                                    .font(.caption)
                                                Spacer()
                                                Text(String(format: NSLocalizedString("settings.premium.remaining.format", comment: "X remaining"), stats.remainingToday))
                                                    .font(.caption)
                                                    .foregroundStyle(stats.remainingToday > 0 ? .green : .red)
                                            }
                                            .padding(.top, 4)
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.purple.opacity(0.1))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                            // AI & Privacy
                            SettingsSection(title: String(localized: "settings.ai.privacy.title", comment: "AI & Privacy")) {
                                NavigationLink {
                                    AIPrivacySettingsView()
                                } label: {
                                    SettingsRow(
                                        icon: "brain.head.profile",
                                        title: String(localized: "settings.ai.privacy.settings", comment: "AI Settings & Privacy"),
                                        color: .purple
                                    )
                                }

                                // ✅ YENI: API Usage Stats
                                NavigationLink {
                                    APIUsageStatsView()
                                } label: {
                                    SettingsRow(
                                        icon: "chart.bar.fill",
                                        title: "API Kullanım İstatistikleri",
                                        color: .blue
                                    )
                                }
                            }

                            // Veri Yönetimi
                            SettingsSection(title: String(localized: "settings.data.management.title", comment: "Data Management")) {
                                ShareLink(item: exportDataURL ?? URL(string: "about:blank") ?? URL(fileURLWithPath: "/")) {
                                    SettingsRow(
                                        icon: "square.and.arrow.up.fill",
                                        title: viewModel.isExporting ? String(localized: "settings.data.exporting", comment: "Exporting...") : String(localized: "settings.data.export", comment: "Export Data"),
                                        color: Color.info
                                    )
                                }
                                .disabled(viewModel.isExporting)
                                .simultaneousGesture(TapGesture().onEnded {
                                    HapticFeedback.light()
                                    exportData()
                                })

                                Button {
                                    HapticFeedback.light()
                                    showImportPicker = true
                                } label: {
                                    SettingsRow(
                                        icon: "square.and.arrow.down.fill",
                                        title: viewModel.isImporting ? String(localized: "settings.data.importing", comment: "Importing...") : String(localized: "settings.data.restore.backup", comment: "Restore from Backup"),
                                        color: Color.info
                                    )
                                }
                                .disabled(viewModel.isImporting)
                            }

                            // İstatistikler
                            SettingsSection(title: String(localized: "settings.app.stats.title", comment: "App Statistics")) {
                                VStack(spacing: AppConstants.Spacing.small) {
                                    StatRow(
                                        icon: "person.2.fill",
                                        title: String(localized: "settings.stats.total.friends", comment: "Total Friends"),
                                        value: "\(viewModel.totalFriends)",
                                        color: .blue
                                    )

                                    StatRow(
                                        icon: "location.fill",
                                        title: String(localized: "settings.stats.location.logs", comment: "Location Logs"),
                                        value: "\(viewModel.totalLocationLogs)",
                                        color: .green
                                    )

                                    StatRow(
                                        icon: "target",
                                        title: String(localized: "settings.stats.total.goals", comment: "Total Goals"),
                                        value: "\(viewModel.totalGoals)",
                                        color: .orange
                                    )

                                    StatRow(
                                        icon: "star.fill",
                                        title: String(localized: "settings.stats.total.habits", comment: "Total Habits"),
                                        value: "\(viewModel.totalHabits)",
                                        color: .purple
                                    )

                                    StatRow(
                                        icon: "internaldrive.fill",
                                        title: String(localized: "settings.stats.storage.usage", comment: "Storage Usage"),
                                        value: viewModel.storageUsed,
                                        color: .gray
                                    )
                                }
                                .padding(AppConstants.Spacing.medium)
                                .cardStyle()
                            }

                            // Hakkında
                            SettingsSection(title: String(localized: "settings.about.title", comment: "About")) {
                                HStack {
                                    HStack(spacing: AppConstants.Spacing.small) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundStyle(.secondary)
                                        Text(String(localized: "settings.version", comment: "Version"))
                                            .foregroundStyle(.primary)
                                    }

                                    Spacer()

                                    Text("1.0.0")
                                        .foregroundStyle(.secondary)
                                        .fontWeight(.medium)
                                }
                                .padding(AppConstants.Spacing.medium)
                                .cardStyle()

                                if let privacyURL = URL(string: "https://sezginpak.github.io/lifestyles/privacy.html") {
                                    Link(destination: privacyURL) {
                                        SettingsRow(
                                            icon: "hand.raised.fill",
                                            title: String(localized: "settings.privacy.policy", comment: "Privacy Policy"),
                                            color: .secondary
                                        )
                                    }
                                }

                                if let termsURL = URL(string: "https://sezginpak.github.io/lifestyles/terms.html") {
                                    Link(destination: termsURL) {
                                        SettingsRow(
                                            icon: "doc.text.fill",
                                            title: String(localized: "settings.terms.of.use", comment: "Terms of Use"),
                                            color: .secondary
                                        )
                                    }
                                }
                            }

                            // Tehlikeli işlemler
                            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                                Button(role: .destructive) {
                                    HapticFeedback.warning()
                                    viewModel.showDeleteConfirmation = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text(viewModel.isDeleting ? String(localized: "settings.delete.deleting", comment: "Deleting...") : String(localized: "settings.delete.all.data", comment: "Delete All Data"))
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.error.opacity(0.1))
                                    .foregroundStyle(Color.error)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium))
                                }
                                .disabled(viewModel.isDeleting)
                                .padding(.horizontal, AppConstants.Spacing.large)
                            }
                        }
                    }
                    .padding(.bottom, 100) // Tab bar için boşluk
                }
            }
            .navigationTitle(String(localized: "settings.title", comment: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAppearanceSettings) {
                NavigationStack {
                    AppearanceSettingsView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(String(localized: "common.close", comment: "Close")) {
                                    showAppearanceSettings = false
                                }
                            }
                        }
                }
            }
            .task {
                // İzin kontrolü
                viewModel.checkPermissions()

                // İstatistikleri async olarak hesapla (UI donmadan)
                // NOT: Bu fonksiyon UI'yi dondurabiliyor - arka plana alındı
                Task.detached {
                    await viewModel.calculateStatistics(context: modelContext)
                }
            }
            .alert(String(localized: "settings.delete.all.data.title", comment: "Delete All Data?"), isPresented: $viewModel.showDeleteConfirmation) {
                Button(String(localized: "common.cancel", comment: "Cancel"), role: .cancel) {}
                Button(String(localized: "common.delete", comment: "Delete"), role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text(String(localized: "settings.delete.warning", comment: "This action cannot be undone. All your friends, goals, habits and location history will be deleted."))
            }
            .alert(String(localized: "common.info", comment: "Info"), isPresented: $showAlert) {
                Button(String(localized: "common.ok", comment: "OK"), role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json]
            ) { result in
                importData(result: result)
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
        }
    }

    // MARK: - Helper Functions

    private func exportData() {
        Task {
            do {
                let url = try await viewModel.exportData(context: modelContext)
                exportDataURL = url
                if let message = viewModel.operationMessage {
                    alertMessage = message
                    showAlert = true
                }
            } catch {
                alertMessage = String(localized: "settings.error.export.prefix", comment: "Export error:") + " \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    private func importData(result: Result<URL, Error>) {
        Task {
            do {
                let url = try result.get()
                try await viewModel.importData(from: url, context: modelContext)
                if let message = viewModel.operationMessage {
                    alertMessage = message
                    showAlert = true
                }
                // İstatistikleri yeniden hesapla
                await viewModel.calculateStatistics(context: modelContext)
            } catch {
                alertMessage = String(localized: "settings.error.import.prefix", comment: "Import error:") + " \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    private func deleteAllData() {
        Task {
            do {
                try await viewModel.deleteAllData(context: modelContext)
                if let message = viewModel.operationMessage {
                    alertMessage = message
                    showAlert = true
                }
                // İstatistikleri yeniden hesapla
                await viewModel.calculateStatistics(context: modelContext)
            } catch {
                alertMessage = String(localized: "settings.error.delete.prefix", comment: "Delete error:") + " \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

struct PermissionsDetailView: View {
    @State private var viewModel = SettingsViewModel()
    private let permissionManager = PermissionManager.shared

    var body: some View {
        List {
            PermissionRow(
                icon: "person.2.fill",
                title: String(localized: "settings.permission.contacts.title", comment: "Contacts"),
                description: String(localized: "settings.permission.contacts.desc", comment: "For contact history tracking"),
                color: .blue,
                status: viewModel.contactsPermissionStatus
            )

            PermissionRow(
                icon: "location.fill",
                title: String(localized: "settings.permission.location.title", comment: "Location"),
                description: String(localized: "settings.permission.location.desc", comment: "For activity suggestions"),
                color: .green,
                status: viewModel.locationPermissionStatus
            )

            PermissionRow(
                icon: "bell.fill",
                title: String(localized: "settings.permission.notifications.title", comment: "Notifications"),
                description: String(localized: "settings.permission.notifications.desc", comment: "For reminders and suggestions"),
                color: .red,
                status: viewModel.notificationsPermissionStatus
            )

            // Ayarları Aç Butonu
            if needsPermissions {
                Button {
                    viewModel.openAppSettings()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text(String(localized: "settings.open.app.settings", comment: "Open App Settings"))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium))
                }
                .listRowBackground(Color.clear)
                .padding(.top)
            }
        }
        .navigationTitle(String(localized: "settings.permissions.detail.title", comment: "Permissions"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.checkPermissions()
        }
    }

    private var needsPermissions: Bool {
        viewModel.contactsPermissionStatus != .authorized ||
        viewModel.locationPermissionStatus != .authorized ||
        viewModel.notificationsPermissionStatus != .authorized
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    var status: PermissionManager.PermissionStatus = .notDetermined

    var body: some View {
        HStack(spacing: AppConstants.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Durum göstergesi
            statusIcon
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .authorized:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
        case .denied, .restricted:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.title3)
        case .notDetermined:
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
        }
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, AppConstants.Spacing.large)

            VStack(spacing: AppConstants.Spacing.small) {
                content
            }
            .padding(.horizontal, AppConstants.Spacing.large)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: AppConstants.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(AppConstants.Spacing.medium)
        .cardStyle()
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppConstants.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.brandPrimary)
        }
        .padding(AppConstants.Spacing.medium)
        .cardStyle()
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: AppConstants.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}
