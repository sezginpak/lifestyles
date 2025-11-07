//
//  AchievementComponents.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Modern achievement component'leri - Tamamen yeniden tasarlandı
//

import SwiftUI

// MARK: - Modern Achievement Card

/// Tek bir achievement için modern, interaktif kart
struct ModernAchievementCard: View {
    let achievement: Achievement
    var onTap: (() -> Void)? = nil

    @State private var isPressed = false
    @State private var showSparkles = false
    @State private var shimmerOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Shimmer effect için progress threshold
    private var shouldShimmer: Bool {
        achievement.progressPercentage >= 80 && !achievement.isEarned
    }

    var body: some View {
        Button {
            HapticFeedback.medium()
            onTap?()
        } label: {
            VStack(spacing: 0) {
                // Top: Progress Ring + Emoji
                ZStack {
                    // Gradient Background
                    LinearGradient(
                        colors: [
                            Color(hex: achievement.colorHex).opacity(achievement.isEarned ? 0.25 : 0.08),
                            Color(hex: achievement.colorHex).opacity(achievement.isEarned ? 0.15 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 140)

                    VStack(spacing: 12) {
                        // Progress Ring with Emoji
                        ZStack {
                            // Background Ring
                            Circle()
                                .stroke(
                                    Color(hex: achievement.colorHex).opacity(0.15),
                                    lineWidth: 6
                                )
                                .frame(width: 80, height: 80)

                            // Progress Ring
                            Circle()
                                .trim(from: 0, to: CGFloat(achievement.progressPercentage) / 100.0)
                                .stroke(
                                    shouldShimmer ? shimmerGradient : normalGradient,
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: achievement.progressPercentage)
                                .shadow(
                                    color: shouldShimmer ? Color(hex: achievement.colorHex).opacity(0.5) : .clear,
                                    radius: shouldShimmer ? 8 : 0
                                )
                                .onAppear {
                                    if shouldShimmer && !reduceMotion {
                                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                            shimmerOffset = 1.0
                                        }
                                    }
                                }
                                .onChange(of: achievement.progressPercentage) { oldValue, newValue in
                                    if shouldShimmer && !reduceMotion && shimmerOffset == 0 {
                                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                            shimmerOffset = 1.0
                                        }
                                    }
                                }

                            // Emoji Center (or ??? for secret)
                            Text(achievement.isSecret && !achievement.isEarned ? "❓" : achievement.emoji)
                                .font(.system(size: 36))
                                .grayscale(achievement.isLocked ? 0.99 : 0)
                                .opacity(achievement.isLocked ? 0.4 : 1)
                                .scaleEffect(showSparkles ? 1.1 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSparkles)
                        }

                        // Progress Percentage Badge
                        if !achievement.isEarned {
                            Text(String(localized: "achievement.progress.percentage", defaultValue: "\(achievement.progressPercentage)%", comment: "Progress percentage"))
                                .font(.caption.bold())
                                .foregroundStyle(Color(hex: achievement.colorHex))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: achievement.colorHex).opacity(0.15))
                                )
                        }
                    }
                    .padding(.vertical, 20)

                    // Lock Overlay (if locked)
                    if achievement.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                            .offset(x: 35, y: -35)
                    }

                    // Earned Badge (if earned)
                    if achievement.isEarned {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .offset(x: 35, y: -35)
                    }
                }

                // Bottom: Info
                VStack(alignment: .leading, spacing: 8) {
                    // Title (displayTitle için secret support)
                    Text(achievement.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    // Description (displayDescription için secret support)
                    Text(achievement.displayDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Bottom Row: Category + Tier + Rarity + Progress
                    HStack(spacing: 6) {
                        // Category Badge
                        Text(achievement.category.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color(hex: achievement.colorHex))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: achievement.colorHex).opacity(0.15))
                            )

                        // Tier Badge
                        Text(achievement.tier.emoji)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: achievement.tier.color).opacity(0.15))
                            )

                        // Rarity Badge (only if rare+)
                        if achievement.rarity != .common {
                            Text(achievement.rarity.emoji)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: achievement.rarity.color).opacity(0.15))
                                )
                        }

                        Spacer()

                        // Progress Text (if not earned)
                        if !achievement.isEarned {
                            Text(String(localized: "achievement.progress.fraction", defaultValue: "\(achievement.currentProgress)/\(achievement.requirement)", comment: "Progress fraction"))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        } else if let earnedDate = achievement.earnedAt {
                            Text(earnedDate, style: .date)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 180)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: achievement.isEarned
                                        ? [Color(hex: achievement.colorHex).opacity(0.5), Color(hex: achievement.colorHex).opacity(0.2)]
                                        : [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: achievement.isEarned ? 2 : 1
                            )
                    )
                    .shadow(color: achievement.isEarned ? Color(hex: achievement.colorHex).opacity(0.3) : .black.opacity(0.08), radius: 12, y: 6)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            if achievement.isEarned {
                showSparkles = true
            }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(achievement.isEarned ? [.isButton, .isSelected] : [.isButton])
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        if achievement.isSecret && !achievement.isEarned {
            return "Gizli başarı, ???"
        }
        return "\(achievement.title), \(achievement.category.displayName) kategorisi"
    }

    private var accessibilityValue: String {
        if achievement.isEarned {
            if let earnedAt = achievement.earnedAt {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Kazanıldı, \(formatter.string(from: earnedAt))"
            }
            return "Kazanıldı"
        } else {
            return "\(achievement.progressPercentage)% tamamlandı, \(achievement.currentProgress) / \(achievement.requirement)"
        }
    }

    private var accessibilityHint: String {
        if achievement.isEarned {
            return "Detayları görmek için çift dokunun"
        } else if achievement.isSecret {
            return "Gizli başarı. Keşfetmek için ilerlemeye devam edin. Detaylar için çift dokunun"
        } else {
            return "Henüz kazanılmadı. Detaylar için çift dokunun"
        }
    }

    // MARK: - Gradient Helpers

    private var normalGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: achievement.colorHex),
                Color(hex: achievement.colorHex).opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: achievement.colorHex).opacity(0.5), location: shimmerOffset - 0.3),
                .init(color: Color(hex: achievement.colorHex), location: shimmerOffset - 0.15),
                .init(color: .white.opacity(0.8), location: shimmerOffset),
                .init(color: Color(hex: achievement.colorHex), location: shimmerOffset + 0.15),
                .init(color: Color(hex: achievement.colorHex).opacity(0.5), location: shimmerOffset + 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Achievements Section Header

/// Başarılar bölümü için header (stats + filtre)
struct AchievementsSectionHeader: View {
    let earnedCount: Int
    let totalCount: Int
    let selectedCategory: AchievementCategory?
    let onCategoryTap: (AchievementCategory?) -> Void
    let onSeeAll: () -> Void

    private let categories: [AchievementCategory?] = [nil, .goal, .habit, .streak, .consistency, .special]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top: Title + Stats + See All
            HStack(alignment: .center, spacing: 12) {
                // Trophy Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "dashboard.achievements.title", comment: "Achievements"))
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text(String(format: NSLocalizedString("dashboard.achievements.earned.format", comment: "Earned count"), earnedCount, totalCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // See All Button
                Button {
                    HapticFeedback.light()
                    onSeeAll()
                } label: {
                    HStack(spacing: 4) {
                        Text(String(localized: "dashboard.achievements.all", comment: "All"))
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.blue)
                }
            }

            // Category Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedCategory == category,
                            onTap: {
                                HapticFeedback.light()
                                onCategoryTap(category)
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let category: AchievementCategory?
    let isSelected: Bool
    let onTap: () -> Void

    private var displayText: String {
        category?.displayName ?? "Tümü"
    }

    private var icon: String {
        switch category {
        case .goal: return "target"
        case .habit: return "flame.fill"
        case .streak: return "bolt.fill"
        case .consistency: return "chart.bar.fill"
        case .special: return "star.fill"
        case nil: return "square.grid.2x2.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(displayText)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [.secondary.opacity(0.15), .secondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? .blue.opacity(0.3) : .clear, lineWidth: 1)
            )
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Achievements Section

/// Dashboard'da gösterilecek ana başarılar bölümü
struct ModernAchievementsSection: View {
    let achievements: [Achievement]
    var onAchievementTap: ((Achievement) -> Void)? = nil
    var onSeeAll: (() -> Void)? = nil

    @State private var selectedCategory: AchievementCategory? = nil

    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievements.filter { $0.category == category }
        }
        return achievements
    }

    private var displayedAchievements: [Achievement] {
        // Önce earned olanlar, sonra progress'e göre sırala
        let sorted = filteredAchievements.sorted { first, second in
            if first.isEarned && !second.isEarned { return true }
            if !first.isEarned && second.isEarned { return false }
            return first.progressPercentage > second.progressPercentage
        }
        return Array(sorted.prefix(10)) // Max 10 achievement göster
    }

    private var earnedCount: Int {
        achievements.filter { $0.isEarned }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            AchievementsSectionHeader(
                earnedCount: earnedCount,
                totalCount: achievements.count,
                selectedCategory: selectedCategory,
                onCategoryTap: { category in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedCategory = category
                    }
                },
                onSeeAll: {
                    onSeeAll?()
                }
            )
            .padding(.horizontal)

            // Achievement Cards Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(displayedAchievements) { achievement in
                        ModernAchievementCard(
                            achievement: achievement,
                            onTap: {
                                onAchievementTap?(achievement)
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Achievement Detail Sheet

/// Achievement detay modal
struct AchievementDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let achievement: Achievement

    @State private var showConfetti = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero: Big Emoji + Progress Ring
                    ZStack {
                        // Background Gradient
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: achievement.colorHex).opacity(0.3),
                                        Color(hex: achievement.colorHex).opacity(0.1),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 200, height: 200)

                        // Progress Ring
                        ZStack {
                            Circle()
                                .stroke(
                                    Color(hex: achievement.colorHex).opacity(0.2),
                                    lineWidth: 12
                                )
                                .frame(width: 160, height: 160)

                            Circle()
                                .trim(from: 0, to: CGFloat(achievement.progressPercentage) / 100.0)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: achievement.colorHex),
                                            Color(hex: achievement.colorHex).opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: achievement.progressPercentage)

                            // Big Emoji
                            Text(achievement.emoji)
                                .font(.system(size: 72))
                                .grayscale(achievement.isLocked ? 0.99 : 0)
                                .opacity(achievement.isLocked ? 0.5 : 1)
                        }
                    }
                    .padding(.top, 20)

                    // Title + Category
                    VStack(spacing: 12) {
                        Text(achievement.title)
                            .font(.title.bold())
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text(achievement.category.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: achievement.colorHex))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(hex: achievement.colorHex).opacity(0.15))
                            )
                    }

                    Divider()
                        .padding(.horizontal)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "dashboard.achievement.description", comment: "Description"))
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(achievement.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Progress Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text(String(localized: "dashboard.achievement.progress", comment: "Progress"))
                            .font(.headline)
                            .foregroundStyle(.primary)

                        // Progress Stats
                        HStack(spacing: 20) {
                            // Current Progress
                            VStack(spacing: 6) {
                                Text(String(localized: "achievement.current.progress", defaultValue: "\(achievement.currentProgress)", comment: "Current progress"))
                                    .font(.title.bold())
                                    .foregroundStyle(Color(hex: achievement.colorHex))
                                Text(String(localized: "dashboard.achievement.current", comment: "Current"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: achievement.colorHex).opacity(0.1))
                            )

                            // Target
                            VStack(spacing: 6) {
                                Text(String(localized: "achievement.requirement", defaultValue: "\(achievement.requirement)", comment: "Achievement requirement"))
                                    .font(.title.bold())
                                    .foregroundStyle(.primary)
                                Text(String(localized: "dashboard.achievement.target", comment: "Target"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.secondary.opacity(0.1))
                            )

                            // Percentage
                            VStack(spacing: 6) {
                                Text(String(localized: "achievement.progress.percentage", defaultValue: "%\(achievement.progressPercentage)", comment: "Progress percentage"))
                                    .font(.title.bold())
                                    .foregroundStyle(Color(hex: achievement.colorHex))
                                Text(String(localized: "dashboard.achievement.completion", comment: "Completion"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: achievement.colorHex).opacity(0.1))
                            )
                        }

                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.secondary.opacity(0.15))

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: achievement.colorHex),
                                                Color(hex: achievement.colorHex).opacity(0.7)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(achievement.progressPercentage) / 100.0)
                            }
                        }
                        .frame(height: 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Earned Date (if earned)
                    if achievement.isEarned, let earnedDate = achievement.earnedAt {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(localized: "dashboard.achievement.earned.date", comment: "Earned Date"))
                                .font(.headline)
                                .foregroundStyle(.primary)

                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.yellow)
                                Text(earnedDate, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.yellow.opacity(0.1))
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "achievement.detail.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.close", comment: "Close button")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .confetti(isPresented: $showConfetti, count: 50)
        .onAppear {
            if achievement.isEarned {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Achievement Card") {
    let service = AchievementService.shared
    let achievements = service.getAllAchievements(goals: [], habits: [], currentStreak: 0, friends: [])

    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(achievements.prefix(3)) { achievement in
                ModernAchievementCard(achievement: achievement)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(for: [Goal.self, Habit.self])
}

#Preview("Achievements Section") {
    let service = AchievementService.shared
    let achievements = service.getAllAchievements(goals: [], habits: [], currentStreak: 0, friends: [])

    ScrollView {
        ModernAchievementsSection(achievements: Array(achievements.prefix(6)))
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(for: [Goal.self, Habit.self])
}

// MARK: - Profile Completion Widget

/// Dashboard'da gösterilecek profil tamamlama teşvik widget'ı
/// AI önerilerinin kalitesini artırmak için kullanıcıyı profil bilgilerini tamamlamaya teşvik eder
struct ProfileCompletionWidget: View {
    let profile: UserProfile?
    let onEditProfile: () -> Void

    @State private var isPressed = false

    private var completionPercentage: Double {
        profile?.completionPercentage ?? 0.0
    }

    private var isComplete: Bool {
        completionPercentage >= 1.0
    }

    private var missingFields: [String] {
        guard let profile = profile else {
            return ["İsim", "Yaş", "Meslek", "Hakkımda", "Hobiler", "İlgi Alanları", "Çalışma Saatleri", "Yaşam Durumu", "Hayat Hedefleri", "Değerler"]
        }

        var missing: [String] = []

        if profile.name == nil || profile.name?.isEmpty == true {
            missing.append("İsim")
        }
        if profile.age == nil {
            missing.append("Yaş")
        }
        if profile.occupation == nil || profile.occupation?.isEmpty == true {
            missing.append("Meslek")
        }
        if profile.bio == nil || profile.bio?.isEmpty == true {
            missing.append("Hakkımda")
        }
        if profile.hobbies.isEmpty {
            missing.append("Hobiler")
        }
        if profile.interests.isEmpty {
            missing.append("İlgi Alanları")
        }
        if profile.workSchedule == nil || profile.workSchedule?.isEmpty == true {
            missing.append("Çalışma Saatleri")
        }
        if profile.livingArrangement == nil || profile.livingArrangement?.isEmpty == true {
            missing.append("Yaşam Durumu")
        }
        if profile.lifeGoals == nil || profile.lifeGoals?.isEmpty == true {
            missing.append("Hayat Hedefleri")
        }
        if profile.coreValues.isEmpty {
            missing.append("Değerler")
        }

        return missing
    }

    private var title: String {
        if isComplete {
            return "Profilin Tam!"
        } else if completionPercentage > 0 {
            return "Profilini Tamamla"
        } else {
            return "Profil Oluştur"
        }
    }

    private var subtitle: String {
        if isComplete {
            return "AI seni tanıyor ve kişiselleştirilmiş öneriler sunabiliyor"
        } else if completionPercentage > 0 {
            let remaining = missingFields.count
            return "AI daha iyi öneriler için \(remaining) alan daha ekle"
        } else {
            return "AI'nin seni tanıması ve kişisel öneriler sunması için profil bilgileri gerekli"
        }
    }

    private var gradientColors: [Color] {
        if isComplete {
            return [.green, .green.opacity(0.7)]
        } else if completionPercentage > 0.5 {
            return [.orange, .orange.opacity(0.7)]
        } else {
            return [.purple, .pink]
        }
    }

    var body: some View {
        Button {
            HapticFeedback.medium()
            onEditProfile()
        } label: {
            HStack(spacing: 16) {
                // Left: Progress Ring + Icon
                ZStack {
                    // Background Ring
                    Circle()
                        .stroke(
                            Color.white.opacity(0.3),
                            lineWidth: 6
                        )
                        .frame(width: 70, height: 70)

                    // Progress Ring
                    Circle()
                        .trim(from: 0, to: CGFloat(completionPercentage))
                        .stroke(
                            .white,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: completionPercentage)

                    // Center Icon
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    } else {
                        VStack(spacing: 2) {
                            Image(systemName: "person.fill")
                                .font(.title3)
                                .foregroundStyle(.white)

                            Text(String(localized: "achievement.completion.percentage", defaultValue: "\(Int(completionPercentage * 100))%", comment: "Completion percentage"))
                                .font(.caption2.bold())
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }

                // Middle: Text Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Missing Fields Preview (if not complete)
                    if !isComplete && !missingFields.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                            Text(String(format: NSLocalizedString("dashboard.achievement.missing.format", comment: "Missing fields"), "\(missingFields.prefix(2).joined(separator: ", "))\(missingFields.count > 2 ? "..." : "")"))
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 2)
                    }
                }

                Spacer()

                // Right: Arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: gradientColors[0].opacity(0.4), radius: 16, y: 8)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Compact Profile Completion Card

/// Dashboard için daha kompakt profil tamamlama kartı
struct CompactProfileCompletionCard: View {
    let profile: UserProfile?
    let onEditProfile: () -> Void

    private var completionPercentage: Double {
        profile?.completionPercentage ?? 0.0
    }

    private var isComplete: Bool {
        completionPercentage >= 1.0
    }

    var body: some View {
        Button {
            HapticFeedback.light()
            onEditProfile()
        } label: {
            HStack(spacing: 12) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.purple.opacity(0.2), lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: CGFloat(completionPercentage))
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.purple)
                    } else {
                        Text(String(localized: "achievement.completion.percentage", defaultValue: "\(Int(completionPercentage * 100))", comment: "Completion value"))
                            .font(.caption2.bold())
                            .foregroundStyle(.purple)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(isComplete ? "Profil Tam" : "Profilini Tamamla")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(String(localized: "dashboard.achievement.ai.required", comment: "Required for AI"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Profile Completion Widget - Empty") {
    VStack(spacing: 16) {
        ProfileCompletionWidget(
            profile: nil,
            onEditProfile: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Profile Completion Widget - Partial") {
    VStack(spacing: 16) {
        ProfileCompletionWidget(
            profile: UserProfile(
                name: "Sezgin",
                age: 30,
                occupation: "Developer"
            ),
            onEditProfile: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Profile Completion Widget - Complete") {
    VStack(spacing: 16) {
        let profile = UserProfile(
            name: "Sezgin",
            age: 30,
            occupation: "Developer",
            bio: "iOS Developer",
            hobbies: ["Coding", "Music"],
            interests: ["Tech", "AI"],
            workSchedule: "9-5",
            livingArrangement: "Alone",
            lifeGoals: "Build great apps",
            coreValues: ["Innovation", "Quality"]
        )

        ProfileCompletionWidget(
            profile: profile,
            onEditProfile: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Profile Card") {
    VStack(spacing: 16) {
        CompactProfileCompletionCard(
            profile: UserProfile(name: "Sezgin", age: 30),
            onEditProfile: {}
        )

        CompactProfileCompletionCard(
            profile: nil,
            onEditProfile: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
