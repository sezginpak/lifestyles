//
//  JournalStatsHeader.swift
//  LifeStyles
//
//  Advanced analytics header for journal tab
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct JournalStatsHeader: View {
    let entries: [JournalEntry]
    let currentMood: MoodEntry?

    var body: some View {
        VStack(spacing: 6) {
            // Stats grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6)
                ],
                spacing: 6
            ) {
                // Bu ay yazılan
                JournalStatCard(
                    icon: "calendar",
                    title: "\(entriesThisMonth)",
                    label: "Bu Ay",
                    color: .blue
                )

                // Total kelime
                JournalStatCard(
                    icon: "doc.text",
                    title: formatNumber(totalWordCount),
                    label: "Toplam Kelime",
                    color: .purple
                )

                // Longest streak
                JournalStatCard(
                    icon: "flame.fill",
                    title: "\(longestStreak)",
                    label: "En Uzun Seri",
                    color: .orange
                )

                // Mood average
                if let avgScore = averageMoodScore {
                    JournalStatCard(
                        icon: getMoodIcon(avgScore),
                        title: getMoodLabel(avgScore),
                        label: "Ortalama Ruh Hali",
                        color: .green
                    )
                } else {
                    JournalStatCard(
                        icon: "face.smiling",
                        title: "-",
                        label: "Ruh Hali",
                        color: .gray
                    )
                }
            }

            // Type distribution mini chart
            if !entries.isEmpty {
                typeDistributionView
            }
        }
        .padding(8)
        .background(
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground()

                // Glassmorphism overlay
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            }
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Type Distribution

    var typeDistributionView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "chart.pie")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Text("Journal Dağılımı")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            HStack(spacing: 4) {
                ForEach(typeDistribution, id: \.type) { dist in
                    if dist.count > 0 {
                        VStack(spacing: 3) {
                            Text(dist.type.emoji)
                                .font(.system(size: 14))

                            Text("\(dist.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(dist.type.color)

                            // Progress bar
                            GeometryReader { geo in
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    dist.type.color,
                                                    dist.type.color.opacity(0.6)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: geo.size.height * dist.percentage)
                                }
                            }
                            .frame(height: 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.02))
        )
    }

    // MARK: - Computed Properties

    var entriesThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return entries.filter { entry in
            calendar.isDate(entry.date, equalTo: now, toGranularity: .month)
        }.count
    }

    var totalWordCount: Int {
        entries.reduce(0) { $0 + $1.wordCount }
    }

    var longestStreak: Int {
        guard !entries.isEmpty else { return 0 }

        let sortedEntries = entries.sorted { $0.date < $1.date }
        var currentStreak = 1
        var maxStreak = 1

        for i in 1..<sortedEntries.count {
            let calendar = Calendar.current
            let prevDate = sortedEntries[i - 1].date
            let currentDate = sortedEntries[i].date

            if let daysDiff = calendar.dateComponents([.day], from: prevDate, to: currentDate).day,
               daysDiff == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if let daysDiff = calendar.dateComponents([.day], from: prevDate, to: currentDate).day,
                      daysDiff > 1 {
                currentStreak = 1
            }
        }

        return maxStreak
    }

    var averageMoodScore: Double? {
        let moodEntries = entries.compactMap { $0.moodEntry }
        guard !moodEntries.isEmpty else { return nil }

        let sum = moodEntries.reduce(0.0) { $0 + $1.score }
        return sum / Double(moodEntries.count)
    }

    var typeDistribution: [TypeDistribution] {
        var distribution: [JournalType: Int] = [:]

        for type in JournalType.allCases {
            distribution[type] = 0
        }

        for entry in entries {
            distribution[entry.journalType, default: 0] += 1
        }

        let totalEntries = entries.count
        return JournalType.allCases.map { type in
            let count = distribution[type] ?? 0
            let percentage = totalEntries > 0 ? Double(count) / Double(totalEntries) : 0.0
            return TypeDistribution(type: type, count: count, percentage: percentage)
        }
    }

    struct TypeDistribution {
        let type: JournalType
        let count: Int
        let percentage: Double
    }

    // MARK: - Helpers

    func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.1fK", thousands)
        }
        return "\(number)"
    }

    func getMoodIcon(_ score: Double) -> String {
        switch score {
        case 1.5...: return "face.smiling.fill"
        case 0.5..<1.5: return "face.smiling"
        case -0.5..<0.5: return "minus.circle"
        case -1.5..<(-0.5): return "face.frowning"
        default: return "face.frowning.fill"
        }
    }

    func getMoodLabel(_ score: Double) -> String {
        switch score {
        case 1.5...: return "Harika"
        case 0.5..<1.5: return "İyi"
        case -0.5..<0.5: return "Normal"
        case -1.5..<(-0.5): return "Kötü"
        default: return "Çok Kötü"
        }
    }
}

// MARK: - Journal Stat Card

struct JournalStatCard: View {
    let icon: String
    let title: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Spacer()
            }

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            color.opacity(0.3),
                            lineWidth: 0.5
                        )
                )
        )
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    let colors: [Color] = [
        .blue.opacity(0.1),
        .purple.opacity(0.1),
        .pink.opacity(0.1),
        .orange.opacity(0.1)
    ]

    var body: some View {
        LinearGradient(
            colors: animateGradient ? colors : colors.reversed(),
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .cornerRadius(12)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 5.0)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            JournalStatsHeader(
                entries: [
                    JournalEntry(
                        title: "Test 1",
                        content: "Lorem ipsum dolor sit amet",
                        journalType: .general,
                        tags: ["test"]
                    ),
                    JournalEntry(
                        title: "Test 2",
                        content: "Consectetur adipiscing elit",
                        journalType: .gratitude,
                        tags: ["test"]
                    ),
                    JournalEntry(
                        title: "Test 3",
                        content: "Sed do eiusmod tempor incididunt",
                        journalType: .achievement,
                        tags: ["test"]
                    )
                ],
                currentMood: nil
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
