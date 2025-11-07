//
//  AppearanceSettingsView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Görünüm, dil ve profil ayarları
//

import SwiftUI
import SwiftData

// Tema enum
enum AppTheme: String, CaseIterable, Identifiable {
    case light, dark, auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return String(localized: "appearance.theme.light", comment: "Light")
        case .dark: return String(localized: "appearance.theme.dark", comment: "Dark")
        case .auto: return String(localized: "appearance.theme.auto", comment: "Auto")
        }
    }

    var description: String {
        switch self {
        case .light: return String(localized: "appearance.theme.description.light", comment: "Always use light theme")
        case .dark: return String(localized: "appearance.theme.description.dark", comment: "Always use dark theme")
        case .auto: return String(localized: "appearance.theme.description.auto", comment: "Follow system settings")
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .auto: return "circle.lefthalf.filled"
        }
    }
}

struct AppearanceSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var systemColorScheme
    @Query private var userProfiles: [UserProfile]
    @AppStorage("appTheme") private var selectedTheme: String = AppTheme.auto.rawValue
    @AppStorage("userAvatar") private var userAvatar: String = "👤"
    @State private var showAlert = false
    @State private var alertMessage = ""

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private let purchaseManager = PurchaseManager.shared

    // Avatar emojileri
    private let avatarEmojis = [
        "👤", "👨", "👩", "🧑", "👦", "👧",
        "👨‍💼", "👩‍💼", "👨‍🎓", "👩‍🎓", "👨‍⚕️", "👩‍⚕️",
        "👨‍🎨", "👩‍🎨", "👨‍💻", "👩‍💻", "👨‍🔬", "👩‍🔬",
        "🧙‍♂️", "🧙‍♀️", "🧚‍♂️", "🧚‍♀️", "🦸‍♂️", "🦸‍♀️",
        "😀", "😎", "🤓", "🥳", "😇", "🤠",
        "🐶", "🐱", "🐭", "🐹", "🐰", "🦊",
        "🐻", "🐼", "🐨", "🐯", "🦁", "🐮"
    ]

    var body: some View {
        List {
            // Profil Bölümü
            Section {
                profileCard

                // Profil düzenle butonu
                NavigationLink {
                    UserProfileEditView()
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .foregroundStyle(Color.brandPrimary)
                        Text(String(localized: "settings.edit.profile", comment: "Edit profile"))
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
                .buttonStyle(.plain)
            } header: {
                Text(String(localized: "appearance.profile.header", comment: "Profile"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

            // Avatar Seçimi
            Section {
                avatarSelector
            } header: {
                Text(String(localized: "appearance.avatar.header", comment: "Avatar"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

            // Tema Seçimi
            Section {
                ForEach(AppTheme.allCases) { theme in
                    themeRow(theme: theme)
                }
            } header: {
                Text(String(localized: "appearance.theme.header", comment: "Theme"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "appearance.title", comment: "Appearance"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(String(localized: "common.info", comment: "Info"), isPresented: $showAlert) {
            Button(String(localized: "common.ok", comment: "OK"), role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        HStack(spacing: 16) {
            // Avatar emoji
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)

                Text(userAvatar)
                    .font(.largeTitle)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(userProfile?.name ?? String(localized: "appearance.profile.default.name", comment: "User"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    // Premium Badge
                    if purchaseManager.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text(String(localized: "premium.label", comment: "Premium"))
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
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(completion == 100 ? .green : Color.brandPrimary)
                        Text(String(format: NSLocalizedString("settings.profile.completion", comment: "Profile completion"), Int(completion)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Tamamlanma circle
            if let profile = userProfile {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: calculateCompletion(profile: profile) / 100)
                        .stroke(LinearGradient.primaryGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: calculateCompletion(profile: profile))

                    Text(String(localized: "text.intcalculatecompletionprofile.profile"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Avatar Selector
    private var avatarSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Current avatar
            HStack {
                Text(String(localized: "appearance.avatar.change", comment: "Change Avatar"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(userAvatar)
                    .font(.title)
            }

            // Avatar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(avatarEmojis, id: \.self) { emoji in
                    Button {
                        HapticFeedback.light()
                        userAvatar = emoji
                    } label: {
                        ZStack {
                            Circle()
                                .fill(userAvatar == emoji ? LinearGradient.primaryGradient : LinearGradient(colors: [.secondary.opacity(0.15), .secondary.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)

                            Text(emoji)
                                .font(.title3)

                            if userAvatar == emoji {
                                Circle()
                                    .strokeBorder(Color.brandPrimary, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Theme Row
    private func themeRow(theme: AppTheme) -> some View {
        let isSelected = selectedTheme == theme.rawValue

        return Button {
            HapticFeedback.medium()
            selectedTheme = theme.rawValue
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? LinearGradient.primaryGradient : LinearGradient(colors: [.secondary.opacity(0.2), .secondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)

                    Image(systemName: theme.icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? Color.brandPrimary : .primary)

                    Text(theme.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.brandPrimary)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // GÜVENLİ completion hesaplama - NaN'i önle
    private func calculateCompletion(profile: UserProfile) -> Double {
        var filledFields = 0
        let totalFields = 9

        if profile.name?.isEmpty == false { filledFields += 1 }
        if let age = profile.age, age > 0 { filledFields += 1 }
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
