//
//  ModernHeroCard.swift
//  LifeStyles
//
//  Modern Hero Stats Card for Dashboard - Redesigned
//  Created by Claude on 25.10.2025.
//

import SwiftUI

struct ModernHeroStatsCard: View {
    let summary: DashboardSummary

    @State private var animateScore = false
    @State private var animateRings = false

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(hex: "667EEA").opacity(0.15),
                    Color(hex: "764BA2").opacity(0.1),
                    Color(hex: "F093FB").opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 24) {
                // Top Section: Score + Message
                VStack(spacing: 12) {
                    // Score with circular progress
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                            .frame(width: 140, height: 140)

                        // Progress circle
                        Circle()
                            .trim(from: 0, to: animateScore ? CGFloat(summary.overallScore) / 100.0 : 0)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "667EEA"),
                                        Color(hex: "764BA2"),
                                        Color(hex: "F093FB")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.2), value: animateScore)

                        // Score text
                        VStack(spacing: 4) {
                            Text(String(format: "%d", summary.overallScore))
                                .font(.system(size: 52, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "667EEA"),
                                            Color(hex: "764BA2")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .opacity(animateScore ? 1 : 0)
                                .scaleEffect(animateScore ? 1 : 0.5)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: animateScore)

                            Text("SKOR")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(2)
                                .opacity(animateScore ? 1 : 0)
                                .animation(.easeIn(duration: 0.5).delay(0.4), value: animateScore)
                        }
                    }
                    .padding(.top, 20)

                    // Motivation Message - Modern Badge
                    HStack(spacing: 8) {
                        Text(getMotivationEmoji())
                            .font(.title2)

                        Text(summary.motivationMessage)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "667EEA"),
                                        Color(hex: "764BA2")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text(getMotivationEmoji())
                            .font(.title2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "667EEA").opacity(0.5),
                                                Color(hex: "F093FB").opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .shadow(color: Color(hex: "667EEA").opacity(0.2), radius: 15, y: 8)
                    .opacity(animateScore ? 1 : 0)
                    .offset(y: animateScore ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: animateScore)
                }

                // Bottom Section: 4 Rings
                HStack(spacing: 16) {
                    ringView(summary.goalsRing, delay: 0.1)
                    ringView(summary.habitsRing, delay: 0.2)
                    ringView(summary.socialRing, delay: 0.3)
                    ringView(summary.activityRing, delay: 0.4)
                }
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color(hex: "667EEA").opacity(0.15), radius: 20, x: 0, y: 12)
        .shadow(color: Color.black.opacity(0.08), radius: 30, x: 0, y: 15)
        .onAppear {
            animateScore = true
            animateRings = true
        }
    }

    // Helper: Motivation emoji based on MOOD (3rd ring = socialRing)
    private func getMotivationEmoji() -> String {
        let moodPercentage = summary.socialRing.percentage

        switch moodPercentage {
        case 80...100: return "🌟" // Çok mutlu
        case 60..<80: return "😊"  // İyi
        case 40..<60: return "😌"  // Normal
        case 20..<40: return "🤗"  // Biraz kötü
        default: return "💙"       // Kötü (destek gerek)
        }
    }

    private func ringView(_ data: DashboardRingData, delay: Double = 0) -> some View {
        VStack(spacing: 6) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.12), lineWidth: 5)
                    .frame(width: 70, height: 70)

                // Progress circle with animation
                Circle()
                    .trim(from: 0, to: animateRings ? data.progress : 0)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: data.color),
                                Color(hex: data.color).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(delay), value: animateRings)

                // Icon
                Image(systemName: data.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: data.color))
                    .scaleEffect(animateRings ? 1 : 0.5)
                    .opacity(animateRings ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay + 0.2), value: animateRings)
            }

            Text(data.label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .opacity(animateRings ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(delay + 0.3), value: animateRings)

            Text(String(format: "%d%%", data.percentage))
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: data.color))
                .opacity(animateRings ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(delay + 0.4), value: animateRings)
        }
    }
}

#Preview {
    ModernHeroStatsCard(
        summary: DashboardSummary.empty()
    )
    .padding()
}
