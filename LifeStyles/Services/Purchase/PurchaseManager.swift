//
//  PurchaseManager.swift
//  LifeStyles
//
//  StoreKit 2 Purchase Management
//  Created by Claude on 22.10.2025.
//

import Foundation
import StoreKit

@Observable
class PurchaseManager {
    static let shared = PurchaseManager()

    // MARK: - Published State

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var subscriptionStatus: SubscriptionStatus = .free

    #if DEBUG
    // Debug override - paywall test etmek için
    var debugForceFreeMode: Bool = false
    #endif

    var isPremium: Bool {
        #if DEBUG
        // Debug override aktifse, free mode
        if debugForceFreeMode {
            return false
        }
        // Debug modda da gerçek subscription kontrolü yap
        return subscriptionStatus == .premium
        #else
        // Production modda gerçek abonelik kontrolü
        return subscriptionStatus == .premium
        #endif
    }

    // Transaction update task
    private var transactionUpdateTask: Task<Void, Never>?

    private init() {
        // Start listening for transaction updates
        transactionUpdateTask = Task {
            await observeTransactionUpdates()
        }

        // Load products and check subscription
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    // MARK: - Product Loading

    @MainActor
    func loadProducts() async {
        do {
            let fetchedProducts = try await Product.products(for: ProductID.allProducts)
            products = fetchedProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("❌ Failed to load products: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)

            // Update subscription status
            await checkSubscriptionStatus()

            // Finish the transaction
            await transaction.finish()

            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore Purchases

    @MainActor
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            print("❌ Restore failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Subscription Status

    @MainActor
    func checkSubscriptionStatus() async {
        var hasPremium = false

        // Check all transactions
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if it's our monthly subscription
                if transaction.productID == ProductID.monthlySubscription {
                    hasPremium = true
                    purchasedProductIDs.insert(transaction.productID)
                }
            } catch {
                print("❌ Transaction verification failed: \(error.localizedDescription)")
            }
        }

        // Update status
        subscriptionStatus = hasPremium ? .premium : .free
    }

    // MARK: - Transaction Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }

    // MARK: - Transaction Updates

    private func observeTransactionUpdates() async {
        for await result in StoreKit.Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                await transaction.finish()

                // Update subscription status
                await checkSubscriptionStatus()
            } catch {
                print("❌ Transaction update failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers

    func getMonthlyProduct() -> Product? {
        products.first { $0.id == ProductID.monthlySubscription }
    }

    var monthlyPrice: String {
        getMonthlyProduct()?.displayPrice ?? "₺39.99"
    }
}

// MARK: - Subscription Status Model

enum SubscriptionStatus: String, Codable {
    case free = "Free"
    case premium = "Premium"

    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        }
    }

    var badgeColor: String {
        switch self {
        case .free:
            return "gray"
        case .premium:
            return "gold"
        }
    }
}
