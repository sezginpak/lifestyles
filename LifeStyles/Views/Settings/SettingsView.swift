//
//  SettingsView.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var exportDataURL: URL?
    @State private var showImportPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showLanguageAlert = false
    @State private var pendingLanguage: AppLanguage?

    // Premium
    @State private var purchaseManager = PurchaseManager.shared
    @State private var usageManager = AIUsageManager.shared
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.backgroundPrimary,
                        Color.backgroundSecondary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppConstants.Spacing.large) {
                        // Profil bölümü (opsiyonel)
                        VStack(spacing: AppConstants.Spacing.medium) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.primaryGradient)
                                    .frame(width: 80, height: 80)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                            }

                            HStack(spacing: 8) {
                                Text(String(localized: "settings.user.label", comment: "LifeStyles User"))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)

                                if purchaseManager.isPremium {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.caption2)
                                        Text(String(localized: "settings.premium.badge", comment: "Premium"))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(8)
                                }
                            }

                            Text(purchaseManager.isPremium ? String(localized: "settings.premium.member", comment: "Premium Member") : String(localized: "settings.tagline", comment: "Your personal life coach"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, AppConstants.Spacing.large)

                        // Tema seçimi
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                            Text(String(localized: "settings.appearance.title", comment: "Appearance"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppConstants.Spacing.large)

                            HStack(spacing: AppConstants.Spacing.medium) {
                                ForEach(AppTheme.allCases) { theme in
                                    ThemeButton(
                                        theme: theme,
                                        isSelected: themeManager.currentTheme == theme,
                                        action: {
                                            HapticFeedback.medium()
                                            themeManager.setTheme(theme)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, AppConstants.Spacing.large)
                        }

                        // Dil seçimi
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                            Text(String(localized: "settings.language.title", comment: "Language"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppConstants.Spacing.large)

                            HStack(spacing: AppConstants.Spacing.medium) {
                                ForEach(AppLanguage.allCases) { language in
                                    LanguageButton(
                                        language: language,
                                        isSelected: LanguageManager.shared.currentLanguage == language,
                                        action: {
                                            HapticFeedback.medium()
                                            if language != LanguageManager.shared.currentLanguage {
                                                pendingLanguage = language
                                                showLanguageAlert = true
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, AppConstants.Spacing.large)
                        }

                        // Ayarlar bölümleri
                        VStack(spacing: AppConstants.Spacing.medium) {
                            // İzinler
                            SettingsSection(title: String(localized: "settings.permissions.title", comment: "Permissions")) {
                                NavigationLink {
                                    PermissionsDetailView()
                                } label: {
                                    SettingsRow(
                                        icon: "lock.shield.fill",
                                        title: "Uygulama İzinleri",
                                        color: Color.brandPrimary
                                    )
                                }
                            }

                            // Bildirimler
                            SettingsSection(title: String(localized: "settings.notifications.title", comment: "Notifications")) {
                                SettingsToggleRow(
                                    icon: "bell.fill",
                                    title: "Bildirimler Aktif",
                                    color: Color.error,
                                    isOn: Binding(
                                        get: { viewModel.notificationsEnabled },
                                        set: { newValue in
                                            Task {
                                                await viewModel.toggleNotifications(newValue)
                                            }
                                        }
                                    )
                                )

                                SettingsToggleRow(
                                    icon: "sparkles",
                                    title: "Günlük Motivasyon",
                                    color: Color.brandSecondary,
                                    isOn: Binding(
                                        get: { viewModel.dailyMotivationEnabled },
                                        set: { viewModel.toggleDailyMotivation($0) }
                                    )
                                )

                                NavigationLink {
                                    NotificationPreferencesView()
                                } label: {
                                    SettingsRow(
                                        icon: "slider.horizontal.3",
                                        title: "Bildirim Tercihleri",
                                        color: Color.info
                                    )
                                }
                            }

                            // Konum
                            SettingsSection(title: String(localized: "settings.location.title", comment: "Location")) {
                                SettingsToggleRow(
                                    icon: "location.fill",
                                    title: "Konum Takibi",
                                    color: Color.cardActivity,
                                    isOn: Binding(
                                        get: { viewModel.locationTrackingEnabled },
                                        set: { viewModel.toggleLocationTracking($0, context: modelContext) }
                                    )
                                )

                                NavigationLink {
                                    HomeLocationPickerView()
                                } label: {
                                    SettingsRow(
                                        icon: "house.fill",
                                        title: "Ev Konumu Ayarla",
                                        color: Color.cardGoals
                                    )
                                }
                            }

                            // Premium
                            SettingsSection(title: String(localized: "settings.premium.title", comment: "Premium")) {
                                if purchaseManager.isPremium {
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
                            SettingsSection(title: "AI & Gizlilik") {
                                NavigationLink {
                                    AIPrivacySettingsView()
                                } label: {
                                    SettingsRow(
                                        icon: "brain.head.profile",
                                        title: "AI Ayarları & Gizlilik",
                                        color: .purple
                                    )
                                }
                            }

                            // Veri Yönetimi
                            SettingsSection(title: String(localized: "settings.data.management.title", comment: "Data Management")) {
                                ShareLink(item: exportDataURL ?? URL(string: "about:blank")!) {
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
                                        title: viewModel.isImporting ? "İçe Aktarılıyor..." : "Yedekten Geri Yükle",
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
                                        title: "Toplam Arkadaş",
                                        value: "\(viewModel.totalFriends)",
                                        color: .blue
                                    )

                                    StatRow(
                                        icon: "location.fill",
                                        title: "Konum Kaydı",
                                        value: "\(viewModel.totalLocationLogs)",
                                        color: .green
                                    )

                                    StatRow(
                                        icon: "target",
                                        title: "Toplam Hedef",
                                        value: "\(viewModel.totalGoals)",
                                        color: .orange
                                    )

                                    StatRow(
                                        icon: "star.fill",
                                        title: "Toplam Alışkanlık",
                                        value: "\(viewModel.totalHabits)",
                                        color: .purple
                                    )

                                    StatRow(
                                        icon: "internaldrive.fill",
                                        title: "Depolama Kullanımı",
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
                                        Text("Versiyon")
                                            .foregroundStyle(.primary)
                                    }

                                    Spacer()

                                    Text("1.0.0")
                                        .foregroundStyle(.secondary)
                                        .fontWeight(.medium)
                                }
                                .padding(AppConstants.Spacing.medium)
                                .cardStyle()

                                Link(destination: URL(string: "https://example.com/privacy")!) {
                                    SettingsRow(
                                        icon: "hand.raised.fill",
                                        title: "Gizlilik Politikası",
                                        color: .secondary
                                    )
                                }

                                Link(destination: URL(string: "https://example.com/terms")!) {
                                    SettingsRow(
                                        icon: "doc.text.fill",
                                        title: "Kullanım Şartları",
                                        color: .secondary
                                    )
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
                                        Text(viewModel.isDeleting ? "Siliniyor..." : "Tüm Verileri Sil")
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
            .onAppear {
                viewModel.checkPermissions()
                viewModel.calculateStatistics(context: modelContext)
            }
            .alert("Tüm Verileri Sil?", isPresented: $viewModel.showDeleteConfirmation) {
                Button(String(localized: "common.cancel", comment: "Cancel"), role: .cancel) {}
                Button(String(localized: "common.delete", comment: "Delete"), role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text(String(localized: "settings.delete.warning", comment: "This action cannot be undone. All your friends, goals, habits and location history will be deleted."))
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json]
            ) { result in
                importData(result: result)
            }
            .alert(String(localized: "settings.language.change.title", comment: "Change Language"), isPresented: $showLanguageAlert) {
                Button(String(localized: "common.cancel", comment: "Cancel"), role: .cancel) {
                    pendingLanguage = nil
                }
                Button(String(localized: "settings.language.change.button", comment: "Change"), role: .none) {
                    if let newLanguage = pendingLanguage {
                        LanguageManager.shared.changeLanguage(to: newLanguage)
                        alertMessage = "Dil ayarları kaydedildi! Değişikliklerin uygulanması için lütfen uygulamayı kapatıp tekrar açın.\n\nLanguage settings saved! Please close and reopen the app to apply changes."
                        showAlert = true
                        pendingLanguage = nil
                    }
                }
            } message: {
                Text(String(localized: "settings.language.restart.message", comment: "App needs to be reopened to apply language changes.\n\nDeğişikliklerin uygulanması için uygulama yeniden açılmalı."))
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
                alertMessage = "Yedekleme hatası: \(error.localizedDescription)"
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
                viewModel.calculateStatistics(context: modelContext)
            } catch {
                alertMessage = "İçe aktarma hatası: \(error.localizedDescription)"
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
                viewModel.calculateStatistics(context: modelContext)
            } catch {
                alertMessage = "Silme hatası: \(error.localizedDescription)"
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
                title: "Rehber",
                description: "İletişim geçmişi takibi için",
                color: .blue,
                status: viewModel.contactsPermissionStatus
            )

            PermissionRow(
                icon: "location.fill",
                title: "Konum",
                description: "Aktivite önerileri için",
                color: .green,
                status: viewModel.locationPermissionStatus
            )

            PermissionRow(
                icon: "bell.fill",
                title: "Bildirimler",
                description: "Hatırlatmalar ve öneriler için",
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

struct ThemeButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppConstants.Spacing.small) {
                ZStack {
                    Circle()
                        .fill(isSelected ? LinearGradient.primaryGradient : LinearGradient(colors: [.secondary.opacity(0.2), .secondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)

                    Image(systemName: theme.icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .secondary)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 3)
                        .frame(width: 64, height: 64)
                )

                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.brandPrimary : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LanguageButton: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppConstants.Spacing.small) {
                ZStack {
                    Circle()
                        .fill(isSelected ? LinearGradient.primaryGradient : LinearGradient(colors: [.secondary.opacity(0.2), .secondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)

                    Text(language.flag)
                        .font(.largeTitle)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 3)
                        .frame(width: 64, height: 64)
                )

                Text(language.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.brandPrimary : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
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
