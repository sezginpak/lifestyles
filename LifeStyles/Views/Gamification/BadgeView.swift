//
//  BadgeView.swift
//  LifeStyles
//
//  Badge display component for gamification
//  Created by Claude on 30.10.2025.
//

import SwiftUI

struct BadgeView: View {
    let badgeType: BadgeType
    let isEarned: Bool
    let earnedDate: Date?
    let onTap: (() -> Void)?

    @State private var isAnimating = false

    init(
        badgeType: BadgeType,
        isEarned: Bool = false,
        earnedDate: Date? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.badgeType = badgeType
        self.isEarned = isEarned
        self.earnedDate = earnedDate
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap?()
        }) {
            VStack(spacing: 8) {
                // Badge icon
                ZStack {
                    // Glow effect (earned badges only)
                    if isEarned {
                        Circle()
                            .fill(badgeType.color.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .blur(radius: 15)
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                    }

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isEarned ? [badgeType.color, badgeType.color.opacity(0.7)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(isEarned ? 0.5 : 0.2), lineWidth: 2)
                        )
                        .shadow(color: isEarned ? badgeType.color.opacity(0.4) : .clear, radius: 10)

                    // Emoji
                    Text(badgeType.emoji)
                        .font(.system(size: 32))
                        .grayscale(isEarned ? 0 : 0.99)
                        .opacity(isEarned ? 1 : 0.4)
                }
                .frame(width: 80, height: 80)

                // Badge info
                VStack(spacing: 2) {
                    Text(badgeType.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if isEarned, let date = earnedDate {
                        Text(formattedDate(date))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if !isEarned {
                        Text("🔒 Kilitli")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 100)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isEarned {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let badgeType: BadgeType
    let isEarned: Bool
    let earnedDate: Date?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Large badge display
                ZStack {
                    // Glow
                    if isEarned {
                        Circle()
                            .fill(badgeType.color.opacity(0.3))
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)
                    }

                    // Main badge
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isEarned ? [badgeType.color, badgeType.color.opacity(0.7)] : [Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 3)
                        )
                        .shadow(color: isEarned ? badgeType.color.opacity(0.4) : .clear, radius: 20)

                    Text(badgeType.emoji)
                        .font(.system(size: 64))
                        .grayscale(isEarned ? 0 : 0.99)
                        .opacity(isEarned ? 1 : 0.4)
                }
                .padding(.top, 32)

                // Badge info
                VStack(spacing: 12) {
                    Text(badgeType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(badgeType.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // XP reward
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("+\(badgeType.xpReward) XP")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.15))
                    )

                    // Earned date
                    if isEarned, let date = earnedDate {
                        Text("Kazanıldı: \(formattedFullDate(date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    } else {
                        Text("Henüz kazanılmadı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func formattedFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Badge Grid View

struct BadgeGridView: View {
    let badges: [GamificationBadge]
    @State private var selectedBadge: BadgeType?
    @State private var showingDetail = false

    // Tüm badge tiplerini göster (kazanılmış + kilitli)
    private var allBadgeTypes: [BadgeType] {
        BadgeType.allCases
    }

    private func isEarned(_ type: BadgeType) -> Bool {
        badges.contains(where: { $0.badgeType == type })
    }

    private func earnedDate(for type: BadgeType) -> Date? {
        badges.first(where: { $0.badgeType == type })?.earnedDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rozetler")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(badges.count) / \(BadgeType.allCases.count) Kazanıldı")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: CGFloat(badges.count) / CGFloat(BadgeType.allCases.count))
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(Double(badges.count) / Double(BadgeType.allCases.count) * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)

            // Badge grid
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 16
                ) {
                    ForEach(allBadgeTypes, id: \.self) { type in
                        BadgeView(
                            badgeType: type,
                            isEarned: isEarned(type),
                            earnedDate: earnedDate(for: type),
                            onTap: {
                                selectedBadge = type
                                showingDetail = true
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let badge = selectedBadge {
                BadgeDetailSheet(
                    badgeType: badge,
                    isEarned: isEarned(badge),
                    earnedDate: earnedDate(for: badge)
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        BadgeView(
            badgeType: .firstJournal,
            isEarned: true,
            earnedDate: Date(),
            onTap: {}
        )

        BadgeView(
            badgeType: .journal10,
            isEarned: false,
            earnedDate: nil,
            onTap: {}
        )
    }
    .padding()
}
