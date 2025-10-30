//
//  NotificationSettingsView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Bildirim ayarları merkezi sayfası
//

import SwiftUI

struct NotificationSettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            Section {
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
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                SettingsToggleRow(
                    icon: "sparkles",
                    title: "Günlük Motivasyon",
                    color: Color.brandSecondary,
                    isOn: Binding(
                        get: { viewModel.dailyMotivationEnabled },
                        set: { viewModel.toggleDailyMotivation($0) }
                    )
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text(String(localized: "settings.general.settings", comment: "General Settings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

            Section {
                NavigationLink {
                    NotificationPreferencesView()
                } label: {
                    SettingsRow(
                        icon: "slider.horizontal.3",
                        title: "Bildirim Tercihleri",
                        color: Color.info
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text(String(localized: "settings.notifications.detailed", comment: "Detailed Settings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text(String(localized: "settings.notifications.permission", comment: "Notification Permission"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text(String(localized: "settings.notifications.permission.desc", comment: "Notification permission description"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if viewModel.notificationsPermissionStatus != .authorized {
                        Button {
                            viewModel.openAppSettings()
                        } label: {
                            Text(String(localized: "settings.notifications.open.settings", comment: "Open Settings"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.brandPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .padding()
            } header: {
                Text(String(localized: "settings.info", comment: "Info"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Bildirim Ayarları")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.checkPermissions()
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
