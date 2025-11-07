//
//  AIPrivacySettingsView.swift
//  LifeStyles
//
//  AI Privacy & Data Sharing Settings UI
//  Created by Claude on 22.10.2025.
//

import SwiftUI

struct AIPrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var privacySettings = AIPrivacySettings.shared

    @State private var showConsentSheet = false
    @State private var showDataDetailsSheet = false

    var body: some View {
        List {
            // MARK: - Consent Status
            Section {
                if privacySettings.hasGivenAIConsent {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "settings.ai.features.active", comment: "AI Features Active"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            if let date = privacySettings.consentDate {
                                Text(String(format: NSLocalizedString("settings.ai.consent.date.format", comment: "Consent date: %@"), date.formatted(date: .abbreviated, time: .omitted)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "settings.ai.features.inactive", comment: "AI Features Inactive"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(String(localized: "settings.ai.features.give.consent", comment: "Give consent to use AI features"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // MARK: - AI Features
            Section {
                Toggle(isOn: $privacySettings.morningInsightEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "ai.morning.insight", comment: "Morning Insight"))
                            .font(.subheadline)
                        Text(String(localized: "settings.ai.morning.insight.description", comment: "Personalized suggestions every morning"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!privacySettings.hasGivenAIConsent)

                Toggle(isOn: $privacySettings.aiChatEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "ai.chat", comment: "AI Chat"))
                            .font(.subheadline)
                        Text(String(localized: "settings.ai.chat.description", comment: "AI assistant for conversations and suggestions"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!privacySettings.hasGivenAIConsent)
            } header: {
                Text(String(localized: "settings.ai.features", comment: "AI Features"))
            }

            // MARK: - Data Sharing
            Section {
                Toggle(isOn: $privacySettings.shareFriendsData) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(.blue)
                        Text(String(localized: "settings.ai.data.friends", comment: "Friend Information"))
                    }
                }
                .disabled(!privacySettings.hasGivenAIConsent)

                Toggle(isOn: $privacySettings.shareGoalsAndHabits) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundStyle(.green)
                        Text(String(localized: "settings.ai.data.goals.habits", comment: "Goals and Habits"))
                    }
                }
                .disabled(!privacySettings.hasGivenAIConsent)

                Toggle(isOn: $privacySettings.shareMoodData) {
                    HStack {
                        Image(systemName: "face.smiling")
                            .foregroundStyle(.orange)
                        Text(String(localized: "settings.ai.data.mood", comment: "Mood Data"))
                    }
                }
                .disabled(!privacySettings.hasGivenAIConsent)

                Toggle(isOn: $privacySettings.shareLocationData) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.purple)
                        Text(String(localized: "settings.ai.data.location", comment: "Location Data"))
                    }
                }
                .disabled(!privacySettings.hasGivenAIConsent)

                Button {
                    showDataDetailsSheet = true
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text(String(localized: "settings.ai.data.about", comment: "About Shared Data"))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            } header: {
                Text(String(localized: "settings.ai.data.sharing", comment: "Data Sharing"))
            } footer: {
                Text(String(format: NSLocalizedString("settings.ai.data.types.count.format", comment: "X types of data shared with AI"), privacySettings.enabledDataTypesCount))
            }

            // MARK: - Chat Context Mode
            Section {
                Picker(String(localized: "settings.ai.context.mode", comment: "Context Mode"), selection: $privacySettings.chatContextMode) {
                    ForEach(ChatContextMode.allCases, id: \.self) { mode in
                        VStack(alignment: .leading) {
                            Text(mode.displayName)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.navigationLink)
                .disabled(!privacySettings.hasGivenAIConsent)

            } header: {
                Text(String(localized: "settings.ai.chat.settings", comment: "Chat Settings"))
            } footer: {
                Text(String(localized: "settings.ai.smart.mode.description", comment: "Smart mode shares necessary data based on your questions and optimizes costs"))
            }

            // MARK: - Transparency
            if let lastUsage = privacySettings.lastRequestDataCount {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "settings.ai.last.request", comment: "Last AI Request"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(lastUsage.summary)
                            .font(.subheadline)

                        Text(lastUsage.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                } header: {
                    Text(String(localized: "settings.ai.data.usage", comment: "Data Usage"))
                }
            }

            // MARK: - Actions
            Section {
                if privacySettings.hasGivenAIConsent {
                    Button(role: .destructive) {
                        privacySettings.revokeConsent()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.shield")
                            Text(String(localized: "settings.ai.revoke.consent", comment: "Revoke AI Consent"))
                        }
                    }
                } else {
                    Button {
                        showConsentSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.shield")
                            Text(String(localized: "settings.ai.enable.features", comment: "Enable AI Features"))
                        }
                    }
                }

                Button {
                    if privacySettings.enabledDataTypesCount == 4 {
                        privacySettings.disableAllDataSharing()
                    } else {
                        privacySettings.enableAllDataSharing()
                    }
                } label: {
                    HStack {
                        Image(systemName: privacySettings.enabledDataTypesCount == 4 ? "eye.slash" : "eye")
                        Text(privacySettings.enabledDataTypesCount == 4 ? String(localized: "settings.ai.disable.all.sharing", comment: "Disable All Data Sharing") : String(localized: "settings.ai.enable.all.sharing", comment: "Enable All Data Sharing"))
                    }
                }
                .disabled(!privacySettings.hasGivenAIConsent)
            }
        }
        .navigationTitle(String(localized: "settings.ai.privacy.title", comment: "AI & Privacy"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConsentSheet) {
            AIConsentSheet()
        }
        .sheet(isPresented: $showDataDetailsSheet) {
            DataSharingDetailsSheet()
        }
    }
}

// MARK: - AI Consent Sheet

struct AIConsentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var privacySettings = AIPrivacySettings.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(String(localized: "ai.consent.title", comment: "AI Features"))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(String(localized: "ai.consent.description", comment: "LifeStyles uses Claude AI to provide personalized suggestions"))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text(String(localized: "ai.consent.features.header", comment: "Features"))
                            .font(.headline)

                        FeatureRow(
                            icon: "sunrise.fill",
                            color: .orange,
                            title: "Morning Insight",
                            description: "Her sabah kişiselleştirilmiş günlük öneriler"
                        )

                        FeatureRow(
                            icon: "message.fill",
                            color: .blue,
                            title: "AI Chat",
                            description: "Arkadaşlarınız ve hedefleriniz hakkında akıllı sohbet"
                        )

                        FeatureRow(
                            icon: "sparkles",
                            color: .purple,
                            title: "Akıllı Öneriler",
                            description: "Davranış paternlerinize göre özelleştirilmiş tavsiyeler"
                        )
                    }

                    Divider()

                    // Data Sharing
                    VStack(alignment: .leading, spacing: 16) {
                        Text(String(localized: "ai.consent.shared.data", comment: "Shared Data"))
                            .font(.headline)

                        Text(String(localized: "ai.consent.shared.data.description", comment: "To use AI features, the following data will be shared with Claude AI"))
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        DataSharingRow(icon: "person.2.fill", color: .blue, text: "Arkadaş iletişim durumu")
                        DataSharingRow(icon: "target", color: .green, text: "Hedef ve alışkanlık ilerlemesi")
                        DataSharingRow(icon: "face.smiling", color: .orange, text: "Ruh hali trendi")
                        DataSharingRow(icon: "location.fill", color: .purple, text: "Konum kullanım paterni")
                    }

                    Divider()

                    // Privacy Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "ai.consent.privacy.notes", comment: "🔒 Privacy Notes"))
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            PrivacyNote(text: "Verileriniz sadece AI yanıtları oluşturmak için kullanılır")
                            PrivacyNote(text: "Anthropic verilerinizi eğitim için kullanmaz")
                            PrivacyNote(text: "İstediğiniz zaman ayarlardan veri paylaşımını kapatabilirsiniz")
                            PrivacyNote(text: "Her veri türünü ayrı ayrı kontrol edebilirsiniz")
                        }
                    }
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationTitle(String(localized: "nav.ai.onayı"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button {
                        privacySettings.giveConsent()
                        privacySettings.morningInsightEnabled = true
                        privacySettings.aiChatEnabled = true
                        HapticFeedback.success()
                        dismiss()
                    } label: {
                        Text(String(localized: "common.accept", comment: "I Accept"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "ai.consent.not.now", comment: "Not Now"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DataSharingRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.callout)
        }
    }
}

struct PrivacyNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Data Details Sheet

struct DataSharingDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DetailRow(
                        icon: "person.2.fill",
                        color: .blue,
                        title: "Arkadaş Bilgileri",
                        items: [
                            "İsim ve ilişki türü",
                            "Son iletişim tarihi",
                            "İletişim sıklığı hedefi",
                            "Notlar ve ortak ilgi alanları"
                        ]
                    )
                }

                Section {
                    DetailRow(
                        icon: "target",
                        color: .green,
                        title: "Hedef ve Alışkanlıklar",
                        items: [
                            "Hedef başlığı ve kategori",
                            "İlerleme durumu",
                            "Alışkanlık streak'leri",
                            "Tamamlanma oranları"
                        ]
                    )
                }

                Section {
                    DetailRow(
                        icon: "face.smiling",
                        color: .orange,
                        title: "Ruh Hali Verileri",
                        items: [
                            "Günlük ruh hali kayıtları",
                            "Son 7 günlük trend",
                            "Ruh hali notları",
                            "Ortalama skorlar"
                        ]
                    )
                }

                Section {
                    DetailRow(
                        icon: "location.fill",
                        color: .purple,
                        title: "Konum Verileri",
                        items: [
                            "Evde geçirilen süre",
                            "Dışarı çıkma sıklığı",
                            "Sık ziyaret edilen yerler",
                            "Aktivite paternleri"
                        ]
                    )
                }
            }
            .navigationTitle(String(localized: "nav.paylaşılan.veriler"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.ok", comment: "OK button")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let color: Color
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(item)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AIPrivacySettingsView()
    }
}

#Preview("Consent Sheet") {
    AIConsentSheet()
}
