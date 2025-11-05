//
//  PremiumManager.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Premium abonelik durumu yönetimi
//

import Foundation
import StoreKit

@Observable
class PremiumManager {
    static let shared = PremiumManager()

    // Premium durum kontrolü (şimdilik false, sonra StoreKit ile entegre edilecek)
    var isPremium: Bool = false

    // Premium özellikleri
    enum PremiumFeature {
        case advancedAnalytics
        case aiInsights
        case trendAnalysis
        case unlimitedGoals
        case customThemes
        case exportData

        var localizedName: String {
            switch self {
            case .advancedAnalytics:
                return String(localized: "premium.feature.advanced.charts")
            case .aiInsights:
                return String(localized: "premium.feature.ai.insights")
            case .trendAnalysis:
                return String(localized: "premium.feature.trend.analysis")
            case .unlimitedGoals:
                return "Sınırsız Hedef"
            case .customThemes:
                return "Özel Temalar"
            case .exportData:
                return "Veri Dışa Aktarma"
            }
        }
    }

    private init() {
        // TODO: UserDefaults veya StoreKit'ten premium durumu oku
        loadPremiumStatus()
    }

    func loadPremiumStatus() {
        // Geliştirme için: UserDefaults'tan oku
        isPremium = UserDefaults.standard.bool(forKey: "isPremiumUser")
    }

    func setPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: "isPremiumUser")
    }

    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        return isPremium
    }

    // MARK: - Future: StoreKit Integration

    /*
    func purchaseSubscription(plan: SubscriptionPlan) async throws {
        // StoreKit 2 ile satın alma işlemi
    }

    func restorePurchases() async throws {
        // Satın alımları geri yükle
    }
    */
}
