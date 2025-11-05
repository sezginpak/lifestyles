//
//  TrialCountdownWidget.swift
//  LifeStyles
//
//  Trial countdown widget for Dashboard
//  Created by Claude on 04.11.2025.
//

import SwiftUI

struct TrialCountdownWidget: View {
    @State private var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false

    var body: some View {
        if purchaseManager.isInTrial {
            Button {
                HapticFeedback.light()
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "premium.trial.active"))
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)

                        Text(trialRemainingText)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    // Arrow
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                )
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
        }
    }

    private var trialRemainingText: String {
        let days = purchaseManager.trialDaysRemaining

        if days > 1 {
            return String(localized: "premium.trial.days.remaining").replacingOccurrences(of: "%d", with: "\(days)")
        } else if days == 1 {
            return "Son gün! Yarın sona eriyor"
        } else {
            return "Bugün sona eriyor"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        TrialCountdownWidget()
            .padding()

        Spacer()
    }
    .background(Color.backgroundPrimary)
}
