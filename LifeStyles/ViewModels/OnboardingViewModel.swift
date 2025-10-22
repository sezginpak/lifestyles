//
//  OnboardingViewModel.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import SwiftUI

@Observable
class OnboardingViewModel {
    var currentPage: Int = 0
    var isRequestingPermission: Bool = false
    var showLocationSettingsAlert: Bool = false

    private let permissionManager = PermissionManager.shared

    // Onboarding sayfaları
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "hand.wave.fill",
            title: "LifeStyles'a Hoş Geldiniz",
            description: "Hayat kalitenizi artırmak ve liderlik ruhunuzu geliştirmek için tasarlanmış kişisel yaşam koçunuz.",
            gradient: .primaryGradient
        ),
        OnboardingPage(
            icon: "person.2.fill",
            title: "İletişim Takibi",
            description: "Önemli kişilerle düzenli iletişim kurun. Uygulama size hatırlatmalar gönderecek.",
            gradient: .coolGradient,
            permissionType: .contacts
        ),
        OnboardingPage(
            icon: "location.fill",
            title: "Konum Bazlı Öneriler",
            description: "Hayat kalitenizi artırmak için konumunuzu 15 dakikada bir kaydediyoruz. Arka planda da çalışması için \"Her Zaman\" iznini vermeniz gerekiyor.",
            gradient: .energyGradient,
            permissionType: .location
        ),
        OnboardingPage(
            icon: "bell.fill",
            title: "Bildirimler",
            description: "Motivasyon mesajları, hatırlatmalar ve aktivite önerileri için bildirimlere izin verin.",
            gradient: .motivationGradient,
            permissionType: .notifications
        )
    ]

    var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    func nextPage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        }
    }

    func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }

    func requestPermissionForCurrentPage() async -> Bool {
        guard let permissionType = pages[currentPage].permissionType else {
            return true
        }

        isRequestingPermission = true
        defer { isRequestingPermission = false }

        switch permissionType {
        case .contacts:
            return await permissionManager.requestContactsPermission()
        case .location:
            return await permissionManager.requestLocationPermission()
        case .notifications:
            return await permissionManager.requestNotificationsPermission()
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    static func hasCompletedOnboarding() -> Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
    var permissionType: PermissionType?

    enum PermissionType {
        case contacts
        case location
        case notifications
    }
}
