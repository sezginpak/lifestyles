//
//  AIServiceProtocol.swift
//  LifeStyles
//
//  AI Service Abstraction - Easy migration to backend
//  Created by Claude on 04.11.2025.
//

import Foundation

/// AI servis protokolü - Backend migration için abstraction layer
/// Bu protocol sayesinde gelecekte ClaudeHaikuService → BackendProxyService değişimi kolay olacak
protocol AIServiceProtocol {
    /// AI response generate et
    func generate(
        systemPrompt: String,
        userMessage: String,
        temperature: Double,
        maxTokens: Int
    ) async throws -> String

    /// Conversation history ile generate et
    func generateWithHistory(
        systemPrompt: String,
        messages: [ClaudeMessage],
        temperature: Double
    ) async throws -> String

    /// API kullanım istatistikleri
    var totalRequests: Int { get }
    var totalInputTokens: Int { get }
    var totalOutputTokens: Int { get }
    var estimatedCost: Double { get }

    /// Maliyet tracking'i sıfırla
    func resetCostTracking()
}

// MARK: - Service Type Enum

/// Hangi AI servis kullanılacak? (Gelecekte backend eklendiğinde buradan switch yapılacak)
enum AIServiceType {
    case directAPI      // Şu an kullanılan - Direct Claude API
    case backend        // Gelecekte eklenecek - Backend proxy

    /// Şu an kullanılan servis tipi
    static var current: AIServiceType {
        // Gelecekte bu bir UserDefaults veya Config'den okunabilir
        // Örnek: UserDefaults.standard.bool(forKey: "use_backend") ? .backend : .directAPI
        return .directAPI
    }
}

// MARK: - Service Factory

/// AI servis factory - Uygun servisi döndürür
class AIServiceFactory {
    static let shared = AIServiceFactory()

    private init() {}

    /// Aktif AI servisini döndür
    func getService() -> AIServiceProtocol {
        switch AIServiceType.current {
        case .directAPI:
            return ClaudeHaikuService.shared

        case .backend:
            // Backend henüz implement edilmedi - directAPI'ye fallback
            print("⚠️ Backend service henüz hazır değil - directAPI kullanılıyor")
            return ClaudeHaikuService.shared
        }
    }
}

// MARK: - Migration Guide

/*
 BACKEND MIGRATION PLANI:

 1. Backend Kurulumu:
    - Cloudflare Worker / Vercel / Firebase Cloud Function
    - POST /api/chat endpoint'i oluştur
    - API key'i backend'de sakla

 2. BackendProxyService Oluştur:
    ```swift
    class BackendProxyService: AIServiceProtocol {
        static let shared = BackendProxyService()
        private let backendURL = "https://your-backend.com/api/chat"

        func generate(...) async throws -> String {
            // Backend'e POST request at
            var request = URLRequest(url: URL(string: backendURL)!)
            request.httpMethod = "POST"
            request.setValue("Bearer YOUR_APP_TOKEN", forHTTPHeaderField: "Authorization")
            // ... rest of implementation
        }
    }
    ```

 3. AIServiceType.current'i değiştir:
    ```swift
    static var current: AIServiceType {
        return .backend  // ✅ Backend'e geçiş tamamlandı!
    }
    ```

 4. Tüm view'lar otomatik olarak backend kullanmaya başlayacak!
    - ChatHaikuService.swift
    - AIBrainViewModel.swift
    - FriendAIChatView.swift
    - ... ve diğer AI kullanan tüm yerler

 AVANTAJLAR:
 - ✅ API key güvenli (backend'de)
 - ✅ Server-side rate limiting
 - ✅ User authentication kontrolü
 - ✅ Maliyet kontrolü (user başı quota)
 - ✅ Analytics ve monitoring
 - ✅ Key rotation kolay (client update gerektirmez)

 TESTFLIGHT PLAN:
 1. Önce .directAPI ile production'a çık
 2. Backend hazır olunca:
    - AIServiceType.current = .backend
    - TestFlight'a yeni build gönder
    - A/B test yap
 3. Stabil olunca App Store'a gönder
 */
