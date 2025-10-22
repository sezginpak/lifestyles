//
//  NotificationPreferencesView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Geliştirilmiş versiyon - Toggle'lar ve test butonları
//

import SwiftUI

struct NotificationPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            // Hatırlatma Sıklığı
            Section {
                Picker("Hatırlatma Sıklığı", selection: $viewModel.reminderFrequency) {
                    ForEach(SettingsViewModel.ReminderFrequency.allCases) { frequency in
                        VStack(alignment: .leading) {
                            Text(frequency.rawValue)
                                .font(.headline)
                            Text(frequency.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(frequency)
                    }
                }
                .pickerStyle(.inline)
                .onChange(of: viewModel.reminderFrequency) { _, _ in
                    HapticFeedback.light()
                    viewModel.saveNotificationPreferences()
                }
            } header: {
                Text(String(localized: "settings.notifications.reminder.frequency", comment: "Reminder Frequency"))
            } footer: {
                Text(String(localized: "settings.notifications.frequency.description", comment: "Determines how often friend and goal reminders will be sent."))
            }

            // Sessiz Saatler
            Section {
                Toggle(String(localized: "settings.notifications.quiet.hours.enable", comment: "Enable Quiet Hours"), isOn: $viewModel.quietHoursEnabled)
                    .tint(Color.brandPrimary)
                    .onChange(of: viewModel.quietHoursEnabled) { _, _ in
                        HapticFeedback.medium()
                        viewModel.saveNotificationPreferences()
                    }

                if viewModel.quietHoursEnabled {
                    DatePicker(
                        String(localized: "settings.notifications.start.time", comment: "Start"),
                        selection: $viewModel.quietHoursStart,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(Color.brandPrimary)
                    .onChange(of: viewModel.quietHoursStart) { _, _ in
                        viewModel.saveNotificationPreferences()
                    }

                    DatePicker(
                        String(localized: "settings.notifications.end.time", comment: "End"),
                        selection: $viewModel.quietHoursEnd,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(Color.brandPrimary)
                    .onChange(of: viewModel.quietHoursEnd) { _, _ in
                        viewModel.saveNotificationPreferences()
                    }
                }
            } header: {
                Text(String(localized: "settings.notifications.quiet.hours", comment: "Quiet Hours"))
            } footer: {
                if viewModel.quietHoursEnabled {
                    Text(String(localized: "settings.notifications.quiet.active.description", comment: "No notifications will be sent during the specified hours."))
                } else {
                    Text(String(localized: "settings.notifications.quiet.inactive.description", comment: "Set hours when you don't want to receive notifications."))
                }
            }

            // Bildirim Türleri (Toggle'lı)
            Section {
                NotificationToggleRow(
                    icon: "person.2.fill",
                    title: "Arkadaş Hatırlatmaları",
                    description: "İletişim kurmanız gereken arkadaşlarınız için",
                    color: .blue,
                    isEnabled: $viewModel.friendRemindersEnabled
                )
                .onChange(of: viewModel.friendRemindersEnabled) { _, _ in
                    viewModel.saveNotificationPreferences()
                }

                NotificationToggleRow(
                    icon: "target",
                    title: "Hedef Hatırlatmaları",
                    description: "Hedefleriniz için son tarih yaklaşınca",
                    color: .orange,
                    isEnabled: $viewModel.goalRemindersEnabled
                )
                .onChange(of: viewModel.goalRemindersEnabled) { _, _ in
                    viewModel.saveNotificationPreferences()
                }

                NotificationToggleRow(
                    icon: "star.fill",
                    title: "Alışkanlık Hatırlatmaları",
                    description: "Günlük alışkanlıklarınız için",
                    color: .purple,
                    isEnabled: $viewModel.habitRemindersEnabled
                )
                .onChange(of: viewModel.habitRemindersEnabled) { _, _ in
                    viewModel.saveNotificationPreferences()
                }

                NotificationToggleRow(
                    icon: "location.fill",
                    title: "Konum Önerileri",
                    description: "Dışarı çıkma ve aktivite önerileri",
                    color: .green,
                    isEnabled: $viewModel.locationSuggestionsEnabled
                )
                .onChange(of: viewModel.locationSuggestionsEnabled) { _, _ in
                    viewModel.saveNotificationPreferences()
                }

                NotificationToggleRow(
                    icon: "sparkles",
                    title: "Motivasyon Mesajları",
                    description: "Günlük motivasyon ve ilham",
                    color: .yellow,
                    isEnabled: $viewModel.motivationMessagesEnabled
                )
                .onChange(of: viewModel.motivationMessagesEnabled) { _, _ in
                    viewModel.saveNotificationPreferences()
                }

                NotificationToggleRow(
                    icon: "figure.run",
                    title: "Aktivite Hatırlatmaları",
                    description: "Günlük aktivite önerileri",
                    color: .indigo,
                    isEnabled: $viewModel.activityRemindersEnabled
                )
                .onChange(of: viewModel.activityRemindersEnabled) { _, _ in
                    viewModel.saveNotificationPreferences()
                }

                NotificationToggleRow(
                    icon: "flame.fill",
                    title: "Streak Uyarıları",
                    description: "Streak'inizin kopma riski varsa uyarı",
                    color: .red,
                    isEnabled: $viewModel.streakWarningsEnabled
                )
                .onChange(of: viewModel.streakWarningsEnabled) { _, _ in
                    viewModel.saveNotificationPreferences()
                }
            } header: {
                Text(String(localized: "settings.notifications.types", comment: "Notification Types"))
            } footer: {
                Text(String(localized: "settings.notifications.types.description", comment: "You can enable or disable notification types."))
            }
        }
        .navigationTitle("Bildirim Tercihleri")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Notification Toggle Row

struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    @Binding var isEnabled: Bool

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

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Color.brandPrimary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        NotificationPreferencesView()
    }
}
