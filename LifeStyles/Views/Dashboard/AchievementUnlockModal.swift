//
//  AchievementUnlockModal.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Achievement unlock celebration modal
//

import SwiftUI

// MARK: - Achievement Unlock Modal

/// Yeni bir achievement kazanıldığında gösterilen full-screen celebration modal
struct AchievementUnlockModal: View {
    let achievement: Achievement
    @Binding var isPresented: Bool

    @State private var animationPhase = 0
    @State private var showConfetti = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 32) {
                // Phase 1: Achievement reveal (0-0.5s)
                if animationPhase >= 1 {
                    achievementEmoji
                }

                // Phase 2: Text reveal (0.5-1s)
                if animationPhase >= 2 {
                    achievementInfo
                }

                // Phase 3: Action button (1-1.5s)
                if animationPhase >= 3 {
                    dismissButton
                }
            }
            .padding(40)
        }
        .achievementConfetti(
            isPresented: $showConfetti,
            requirement: achievement.requirement
        )
        .onAppear {
            performUnlockSequence()
        }
    }

    // MARK: - Achievement Emoji

    private var achievementEmoji: some View {
        Text(achievement.emoji)
            .font(.system(size: 120))
            .scaleEffect(animationPhase >= 2 ? 1.0 : 0.3)
            .rotationEffect(.degrees(animationPhase >= 2 ? 0 : -180))
            .animation(
                reduceMotion
                    ? .easeIn(duration: 0.2)
                    : .spring(response: 0.5, dampingFraction: 0.6),
                value: animationPhase
            )
    }

    // MARK: - Achievement Info

    private var achievementInfo: some View {
        VStack(spacing: 12) {
            Text(String(localized: "achievement.unlocked", comment: ""))
                .font(.title.bold())
                .foregroundStyle(.white)

            Text(achievement.title)
                .font(.title2)
                .foregroundStyle(Color(hex: achievement.colorHex))

            Text(achievement.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Tier and Points
            HStack(spacing: 16) {
                // Tier Badge
                HStack(spacing: 6) {
                    Text(achievement.tier.emoji)
                        .font(.caption)
                    Text(achievement.tier.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.15))
                )

                // Points
                HStack(spacing: 4) {
                    Text("⭐")
                        .font(.caption)
                    Text(String(localized: "achievement.points.format", defaultValue: "\(achievement.points) points", comment: "Achievement points"))
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.yellow.opacity(0.15))
                )
            }
            .padding(.top, 8)
        }
        .transition(
            reduceMotion
                ? .opacity
                : .opacity.combined(with: .scale)
        )
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Text(String(localized: "achievement.awesome", comment: ""))
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: 200)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color(hex: achievement.colorHex))
                )
        }
        .transition(
            reduceMotion
                ? .opacity
                : .move(edge: .bottom).combined(with: .opacity)
        )
    }

    // MARK: - Unlock Sequence

    private func performUnlockSequence() {
        // Initial haptic
        HapticFeedback.heavy()

        // Phase 1: Emoji reveal (0s)
        withAnimation {
            animationPhase = 1
        }

        // Phase 2: Text reveal (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            HapticFeedback.success()
            withAnimation {
                animationPhase = 2
            }

            // Start confetti
            if !reduceMotion {
                showConfetti = true
            }
        }

        // Phase 3: Button reveal (1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            HapticFeedback.light()
            withAnimation {
                animationPhase = 3
            }
        }
    }

    private func dismiss() {
        withAnimation {
            isPresented = false
        }
        showConfetti = false
    }
}

// MARK: - Multiple Achievements Modal

/// Birden fazla achievement aynı anda kazanıldığında gösterilen modal
struct MultipleAchievementsModal: View {
    let achievements: [Achievement]
    @Binding var isPresented: Bool

    @State private var currentIndex = 0
    @State private var animationPhase = 0
    @State private var showConfetti = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var currentAchievement: Achievement {
        achievements[currentIndex]
    }

    private var isLastAchievement: Bool {
        currentIndex == achievements.count - 1
    }

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Phase 1: Achievement reveal
                if animationPhase >= 1 {
                    Text(currentAchievement.emoji)
                        .font(.system(size: 120))
                        .scaleEffect(animationPhase >= 2 ? 1.0 : 0.3)
                        .rotationEffect(.degrees(animationPhase >= 2 ? 0 : -180))
                        .animation(
                            reduceMotion
                                ? .easeIn(duration: 0.2)
                                : .spring(response: 0.5, dampingFraction: 0.6),
                            value: animationPhase
                        )
                }

                // Phase 2: Text reveal
                if animationPhase >= 2 {
                    VStack(spacing: 12) {
                        // Multiple achievements indicator
                        Text(String(localized: "achievement.unlocked.multiple", defaultValue: "🎉 \(achievements.count) Achievements Unlocked!", comment: "Multiple achievements unlocked"))
                            .font(.title.bold())
                            .foregroundStyle(.white)

                        Text(String(localized: "achievement.pagination.format", defaultValue: "\(currentIndex + 1) / \(achievements.count)", comment: "Achievement pagination"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.1))
                            )

                        Text(currentAchievement.title)
                            .font(.title2)
                            .foregroundStyle(Color(hex: currentAchievement.colorHex))

                        Text(currentAchievement.description)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .scale)
                    )
                }

                // Phase 3: Action buttons
                if animationPhase >= 3 {
                    HStack(spacing: 16) {
                        if !isLastAchievement {
                            // Next button
                            Button {
                                nextAchievement()
                            } label: {
                                Text(String(localized: "achievement.next", comment: ""))
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: currentAchievement.colorHex))
                                    )
                            }
                        }

                        // Done button
                        Button {
                            dismiss()
                        } label: {
                            Text(isLastAchievement ? "Harika!" : "Atla")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: isLastAchievement ? .infinity : 100)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(
                                            isLastAchievement
                                                ? Color(hex: currentAchievement.colorHex)
                                                : Color.white.opacity(0.2)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .move(edge: .bottom).combined(with: .opacity)
                    )
                }
            }
            .padding(40)
        }
        .achievementConfetti(
            isPresented: $showConfetti,
            requirement: currentAchievement.requirement
        )
        .onAppear {
            performUnlockSequence()
        }
    }

    // MARK: - Actions

    private func nextAchievement() {
        // Reset animation
        withAnimation {
            animationPhase = 0
            showConfetti = false
        }

        // Move to next
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            performUnlockSequence()
        }
    }

    private func dismiss() {
        withAnimation {
            isPresented = false
        }
        showConfetti = false
    }

    private func performUnlockSequence() {
        HapticFeedback.heavy()

        withAnimation {
            animationPhase = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            HapticFeedback.success()
            withAnimation {
                animationPhase = 2
            }

            if !reduceMotion {
                showConfetti = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            HapticFeedback.light()
            withAnimation {
                animationPhase = 3
            }
        }
    }
}

// MARK: - Preview

#Preview("Single Achievement") {
    AchievementUnlockModal(
        achievement: Achievement(
            id: "test",
            title: "İlk Hedef",
            description: "İlk hedefini tamamladın!",
            emoji: "🎯",
            category: .goal,
            requirement: 1,
            currentProgress: 1,
            isEarned: true,
            earnedAt: Date(),
            colorHex: "FF6B6B",
            tier: .bronze,
            rarity: .common,
            isSecret: false,
            points: 10,
            hint: nil
        ),
        isPresented: .constant(true)
    )
}

#Preview("Multiple Achievements") {
    MultipleAchievementsModal(
        achievements: [
            Achievement(
                id: "test1",
                title: "İlk Hedef",
                description: "İlk hedefini tamamladın!",
                emoji: "🎯",
                category: .goal,
                requirement: 1,
                currentProgress: 1,
                isEarned: true,
                earnedAt: Date(),
                colorHex: "FF6B6B",
                tier: .bronze,
                rarity: .common,
                isSecret: false,
                points: 10,
                hint: nil
            ),
            Achievement(
                id: "test2",
                title: "İlk Alışkanlık",
                description: "İlk alışkanlığını oluşturdun!",
                emoji: "⚡",
                category: .habit,
                requirement: 1,
                currentProgress: 1,
                isEarned: true,
                earnedAt: Date(),
                colorHex: "4ECDC4",
                tier: .bronze,
                rarity: .common,
                isSecret: false,
                points: 10,
                hint: nil
            )
        ],
        isPresented: .constant(true)
    )
}
