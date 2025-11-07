//
//  LanguageSettingsView.swift
//  LifeStyles
//
//  Created by Claude on 7.11.2025.
//  Dil ayarları ve çoklu dil yönetimi
//

import SwiftUI

struct LanguageSettingsView: View {
    @State private var showLanguageAlert = false
    @State private var pendingLanguage: AppLanguage?
    @State private var showSuccessAlert = false

    var body: some View {
        List {
            // Mevcut Dil
            Section {
                HStack {
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "settings.language.current", comment: "Current Language"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(LanguageManager.shared.currentLanguage.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Text(LanguageManager.shared.currentLanguage.flag)
                        .font(.system(size: 32))
                }
                .padding(.vertical, 8)
            } header: {
                Text(String(localized: "settings.language.current.header", comment: "Active Language"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

            // Dil Seçimi
            Section {
                ForEach(AppLanguage.allCases) { language in
                    languageRow(language: language)
                }
            } header: {
                Text(String(localized: "settings.language.select", comment: "Select Language"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "settings.language.restart.warning", comment: "Language restart warning"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // Desteklenen diller bilgisi
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text(String(localized: "settings.language.supported.count", defaultValue: "\(AppLanguage.allCases.count) languages supported", comment: "Languages count"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Dil Hakkında
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    infoRow(
                        icon: "checkmark.seal.fill",
                        title: String(localized: "settings.language.info.quality", comment: "Translation Quality"),
                        description: String(localized: "settings.language.info.quality.desc", comment: "Professional translations"),
                        color: .green
                    )

                    Divider()

                    infoRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: String(localized: "settings.language.info.sync", comment: "Auto Sync"),
                        description: String(localized: "settings.language.info.sync.desc", comment: "Syncs across devices"),
                        color: .blue
                    )

                    Divider()

                    infoRow(
                        icon: "plus.circle.fill",
                        title: String(localized: "settings.language.info.more", comment: "More Languages"),
                        description: String(localized: "settings.language.info.more.desc", comment: "Coming soon"),
                        color: .orange
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text(String(localized: "settings.language.about", comment: "About"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "settings.language.title", comment: "Language"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(String(localized: "settings.language.change.title", comment: "Change Language"), isPresented: $showLanguageAlert) {
            Button(String(localized: "common.cancel", comment: "Cancel"), role: .cancel) {
                pendingLanguage = nil
            }
            Button(String(localized: "settings.language.change.button", comment: "Change"), role: .none) {
                if let newLanguage = pendingLanguage {
                    LanguageManager.shared.changeLanguage(to: newLanguage)
                    showSuccessAlert = true
                    pendingLanguage = nil
                }
            }
        } message: {
            Text(String(localized: "settings.language.restart.message", comment: "App needs to be reopened to apply language changes.\n\nDeğişikliklerin uygulanması için uygulama yeniden açılmalı."))
        }
        .alert(String(localized: "common.success", comment: "Success"), isPresented: $showSuccessAlert) {
            Button(String(localized: "common.ok", comment: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.language.change.success", comment: "Language changed successfully"))
        }
    }

    // MARK: - Language Row
    private func languageRow(language: AppLanguage) -> some View {
        let isSelected = LanguageManager.shared.currentLanguage == language

        return Button {
            HapticFeedback.medium()
            if !isSelected {
                pendingLanguage = language
                showLanguageAlert = true
            }
        } label: {
            HStack(spacing: 16) {
                // Flag circle
                ZStack {
                    Circle()
                        .fill(isSelected ? LinearGradient.primaryGradient : LinearGradient(colors: [.secondary.opacity(0.2), .secondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)

                    Text(language.flag)
                        .font(.title)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? Color.brandPrimary : .primary)

                    Text(language.rawValue.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    HStack(spacing: 6) {
                        Text(String(localized: "common.active", comment: "Active"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brandPrimary)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.brandPrimary)
                            .font(.title3)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info Row
    private func infoRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
