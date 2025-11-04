//
//  ProductIDs.swift
//  LifeStyles
//
//  Product Identifiers for StoreKit
//  Created by Claude on 22.10.2025.
//
//  PRICING:
//  - Monthly Subscription: $0.99/month
//  - 3-day free trial for new users
//  - Configure trial in App Store Connect under Subscriptions → Introductory Offers
//

import Foundation

enum ProductID {
    static let monthlySubscription = "com.lifestyles.premium.monthly"

    static let allProducts = [monthlySubscription]

    // Trial configuration
    static let trialDurationDays = 3
}

enum SubscriptionFeature: String, CaseIterable {
    case unlimitedChat = "Limitsiz AI Chat"
    case advancedAnalytics = "Gelişmiş Analitikler"
    case prioritySupport = "Öncelikli Destek"
    case premiumBadge = "Premium Rozeti"

    var icon: String {
        switch self {
        case .unlimitedChat: return "message.fill"
        case .advancedAnalytics: return "chart.bar.fill"
        case .prioritySupport: return "star.fill"
        case .premiumBadge: return "crown.fill"
        }
    }

    var description: String {
        switch self {
        case .unlimitedChat:
            return "Günlük limit olmadan sınırsız AI sohbet"
        case .advancedAnalytics:
            return "Detaylı istatistikler ve trend analizleri"
        case .prioritySupport:
            return "Sorularınıza öncelikli ve hızlı yanıt"
        case .premiumBadge:
            return "Profil rozetinizle öne çıkın"
        }
    }
}
