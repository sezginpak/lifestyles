//
//  PremiumPaywallView.swift
//  LifeStyles
//
//  Premium Subscription Paywall
//  Created by Claude on 22.10.2025.
//

import SwiftUI
import StoreKit

struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var purchaseManager = PurchaseManager.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Computed Properties

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [.purple, .pink, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var purchaseGradient: LinearGradient {
        LinearGradient(
            colors: [.yellow, .orange],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                            .shadow(color: .yellow.opacity(0.5), radius: 10)

                        Text(String(localized: "premium.lifestyles.title", comment: "LifeStyles Premium"))
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text(String(localized: "premium.subtitle", comment: "More features, unlimited usage"))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Features
                    VStack(spacing: 16) {
                        ForEach(SubscriptionFeature.allCases, id: \.self) { feature in
                            PremiumFeatureRowPaywall(feature: feature)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Trial Banner (if not started trial yet)
                    if !purchaseManager.hasUserStartedTrial() && !purchaseManager.isInTrial {
                        TrialHighlightBanner()
                            .padding(.horizontal, 24)
                    }

                    // Pricing Card
                    if let product = purchaseManager.getMonthlyProduct() {
                        SubscriptionCard(
                            product: product,
                            isInTrial: purchaseManager.isInTrial,
                            trialDaysRemaining: purchaseManager.trialDaysRemaining
                        )
                        .padding(.horizontal, 24)
                    } else {
                        // Fallback pricing
                        SubscriptionPlaceholderCard()
                            .padding(.horizontal, 24)
                    }

                    // Purchase Button
                    Button {
                        HapticFeedback.medium()
                        purchasePremium()
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                if !purchaseManager.hasUserStartedTrial() {
                                    Image(systemName: "sparkles")
                                    Text(String(localized: "premium.trial.3days"))
                                        .font(.headline)
                                } else {
                                    Image(systemName: "crown.fill")
                                    Text(String(localized: "premium.upgrade", comment: "Upgrade to Premium"))
                                        .font(.headline)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(purchaseGradient)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .shadow(color: .yellow.opacity(0.5), radius: 10, y: 5)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 24)

                    // Restore Purchases
                    Button {
                        HapticFeedback.light()
                        restorePurchases()
                    } label: {
                        Text(String(localized: "premium.restore.purchases", comment: "Restore Purchases"))
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                            .underline()
                    }

                    // Legal
                    HStack(spacing: 16) {
                        Link("Gizlilik Politikası", destination: URL(string: "https://sezginpak.github.io/lifestyles/privacy.html")!)
                        Text("•")
                        Link("Kullanım Koşulları", destination: URL(string: "https://sezginpak.github.io/lifestyles/terms.html")!)
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 40)
                }
            }

            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Actions

    private func purchasePremium() {
        guard let product = purchaseManager.getMonthlyProduct() else {
            errorMessage = "Ürün bilgisi yüklenemedi. Lütfen tekrar deneyin."
            showError = true
            return
        }

        Task {
            isPurchasing = true

            do {
                let success = try await purchaseManager.purchase(product)

                if success {
                    HapticFeedback.success()
                    dismiss()
                }
            } catch {
                errorMessage = "Satın alma başarısız: \(error.localizedDescription)"
                showError = true
                HapticFeedback.error()
            }

            isPurchasing = false
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await purchaseManager.restorePurchases()

                if purchaseManager.isPremium {
                    HapticFeedback.success()
                    dismiss()
                } else {
                    errorMessage = "Aktif abonelik bulunamadı."
                    showError = true
                }
            } catch {
                errorMessage = "Geri yükleme başarısız: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

// MARK: - Feature Row

private struct PremiumFeatureRowPaywall: View {
    let feature: SubscriptionFeature

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.white.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.15))
        )
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let product: Product
    let isInTrial: Bool
    let trialDaysRemaining: Int

    var body: some View {
        VStack(spacing: 12) {
            // Trial Info (if active)
            if isInTrial {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text(String(localized: "premium.trial.countdown").replacingOccurrences(of: "%d", with: "\(trialDaysRemaining)"))
                        .font(.caption.bold())
                }
                .foregroundStyle(.yellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.yellow.opacity(0.2))
                )
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "premium.monthly.subscription", comment: "Monthly Subscription"))
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(String(localized: "premium.cancel.anytime", comment: "Cancel anytime"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(String(localized: "premium.per.month", comment: "/month"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Placeholder Card (Product yüklenmediyse)

struct SubscriptionPlaceholderCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "premium.monthly.subscription", comment: "Monthly Subscription"))
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(String(localized: "premium.cancel.anytime", comment: "Cancel anytime"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$0.99")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(String(localized: "premium.per.month", comment: "Per month"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Trial Highlight Banner

struct TrialHighlightBanner: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)

                Text(String(localized: "premium.trial.3days"))
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            Text(String(localized: "premium.price.after.trial"))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))

            Text(String(localized: "premium.cancel.before.charged"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

#Preview {
    PremiumPaywallView()
}
