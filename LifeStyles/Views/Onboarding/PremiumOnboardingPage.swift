//
//  PremiumOnboardingPage.swift
//  LifeStyles
//
//  Premium tanıtım sayfası - Onboarding flow'unda gösterilir
//  Created by Claude on 04.11.2025.
//

import SwiftUI

struct PremiumOnboardingPage: View {
    @Binding var isPresented: Bool
    @Binding var didStartTrial: Bool
    @State private var purchaseManager = PurchaseManager.shared
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color.backgroundPrimary,
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Crown Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .shadow(color: .yellow.opacity(0.4), radius: 20, x: 0, y: 10)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .bounce()

                    // Title & Subtitle
                    VStack(spacing: 12) {
                        Text(String(localized: "onboarding.premium.title"))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(String(localized: "onboarding.premium.subtitle"))
                            .font(.body)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                    }

                    // Premium Features
                    VStack(spacing: 16) {
                        ForEach(SubscriptionFeature.allCases, id: \.self) { feature in
                            PremiumFeatureRow(feature: feature)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Price Info
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(Color.brandPrimary)
                            Text(String(localized: "premium.trial.3days"))
                                .font(.headline)
                                .foregroundStyle(Color.brandPrimary)
                        }

                        Text(String(localized: "premium.price.after.trial"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(String(localized: "premium.cancel.before.charged"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 16)

                    Spacer()
                        .frame(height: 20)
                }
            }

            // Floating Bottom Buttons
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    // Try Free Button
                    Button {
                        startFreeTrial()
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                Text(String(localized: "premium.trial.3days"))
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isProcessing)

                    // Continue Free Button
                    Button {
                        HapticFeedback.light()
                        withAnimation {
                            isPresented = false
                        }
                    } label: {
                        Text(String(localized: "onboarding.skip.stay.free"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Legal Text
                    Text("By continuing, you agree to our Terms and Privacy Policy")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, AppConstants.Spacing.large)
                .padding(.bottom, 40)
                .background(
                    LinearGradient(
                        colors: [
                            Color.backgroundPrimary.opacity(0),
                            Color.backgroundPrimary
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    .allowsHitTesting(false)
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func startFreeTrial() {
        Task {
            isProcessing = true
            HapticFeedback.medium()

            // Önce ürünleri yükle
            await purchaseManager.loadProducts()

            guard let product = purchaseManager.getMonthlyProduct() else {
                await MainActor.run {
                    errorMessage = "Premium subscription not available. Please try again later."
                    showError = true
                    isProcessing = false
                }
                return
            }

            do {
                // Satın alma işlemi başlat (StoreKit otomatik trial uygulayacak)
                let success = try await purchaseManager.purchase(product)

                if success {
                    HapticFeedback.success()
                    await MainActor.run {
                        // Trial başarıyla başlatıldı
                        await purchaseManager.startTrial()
                        didStartTrial = true
                        withAnimation {
                            isPresented = false
                        }
                    }
                } else {
                    await MainActor.run {
                        isProcessing = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Premium Feature Row

struct PremiumFeatureRow: View {
    let feature: SubscriptionFeature

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.rawValue)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    PremiumOnboardingPage(
        isPresented: .constant(true),
        didStartTrial: .constant(false)
    )
}
