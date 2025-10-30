//
//  AppearanceSettingsView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Görünüm, dil ve profil ayarları
//

import SwiftUI
import SwiftData

struct AppearanceSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var showLanguageAlert = false
    @State private var pendingLanguage: AppLanguage?
    @State private var showAlert = false
    @State private var alertMessage = ""

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private let purchaseManager = PurchaseManager.shared

    var body: some View {
        List {
            // TEST: Başarı mesajı
            Section {
                Text(String(localized: "settings.sheet.working", comment: "Sheet working"))
                    .font(.headline)
                    .foregroundStyle(.green)
            }

            // Profil Bölümü (BASİT - Sadece isim ve premium badge)
            Section {
                HStack(spacing: 12) {
                    // Avatar emoji
                    ZStack {
                        Circle()
                            .fill(LinearGradient.primaryGradient)
                            .frame(width: 50, height: 50)

                        Text("👤")
                            .font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(userProfile?.name ?? "Kullanıcı")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            // Premium Badge
                            if purchaseManager.isPremium {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.caption)
                                    Text("Premium")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }

                        // Tamamlanma yüzdesi
                        if let profile = userProfile {
                            let completion = calculateCompletion(profile: profile)
                            Text(String(format: NSLocalizedString("settings.profile.completion", comment: "Profile completion"), Int(completion)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Tamamlanma circle
                    if let profile = userProfile {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                                .frame(width: 44, height: 44)

                            Circle()
                                .trim(from: 0, to: calculateCompletion(profile: profile) / 100)
                                .stroke(LinearGradient.primaryGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))

                            Text("\(Int(calculateCompletion(profile: profile)))%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.brandPrimary)
                        }
                    }
                }
                .padding(.vertical, 8)

                // Profil düzenle butonu
                NavigationLink {
                    UserProfileEditView()
                } label: {
                    HStack {
                        Text(String(localized: "settings.edit.profile", comment: "Edit profile"))
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
                .buttonStyle(.plain)
            } header: {
                Text("Profil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

            // Dil seçimi
            Section {
                VStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            HapticFeedback.medium()
                            if language != LanguageManager.shared.currentLanguage {
                                pendingLanguage = language
                                showLanguageAlert = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(LanguageManager.shared.currentLanguage == language ? LinearGradient.primaryGradient : LinearGradient(colors: [.secondary.opacity(0.2), .secondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)

                                    Text(language.flag)
                                        .font(.title3)
                                }

                                Text(language.displayName)
                                    .font(.body)
                                    .foregroundStyle(LanguageManager.shared.currentLanguage == language ? Color.brandPrimary : .primary)

                                Spacer()

                                if LanguageManager.shared.currentLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brandPrimary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text(String(localized: "settings.language", comment: "Language"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            } footer: {
                Text(String(localized: "settings.language.restart.warning", comment: "Language restart warning"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Görünüm & Dil")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(alertMessage)
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
    }

    // GÜVENLİ completion hesaplama - NaN'i önle
    private func calculateCompletion(profile: UserProfile) -> Double {
        var filledFields = 0
        let totalFields = 9

        if profile.name?.isEmpty == false { filledFields += 1 }
        if profile.age != nil && profile.age! > 0 { filledFields += 1 }
        if profile.occupation?.isEmpty == false { filledFields += 1 }
        if profile.bio?.isEmpty == false { filledFields += 1 }
        if !profile.hobbies.isEmpty { filledFields += 1 }
        if !profile.interests.isEmpty { filledFields += 1 }
        if profile.workSchedule?.isEmpty == false { filledFields += 1 }
        if profile.livingArrangement?.isEmpty == false { filledFields += 1 }
        if !profile.coreValues.isEmpty { filledFields += 1 }

        // GÜVENLİ bölme - totalFields asla 0 değil ama yine de kontrol
        guard totalFields > 0 else { return 0.0 }

        let completion = (Double(filledFields) / Double(totalFields)) * 100.0

        // NaN kontrolü
        if completion.isNaN || completion.isInfinite {
            return 0.0
        }

        return min(100.0, max(0.0, completion))
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
