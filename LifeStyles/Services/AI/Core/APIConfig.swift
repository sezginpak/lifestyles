//
//  APIConfig.swift
//  LifeStyles
//
//  AI API Configuration - Secure storage
//  Created by Claude on 22.10.2025.
//

import Foundation

struct APIConfig {
    // MARK: - Claude API

    /// Claude API Key (Securely stored in Keychain)
    /// ✅ Key is encrypted and stored in iOS Keychain
    /// ✅ Safe for public release
    static var claudeAPIKey: String {
        return SecureAPIKeyManager.shared.claudeAPIKey
    }

    /// Claude API Base URL
    static let claudeBaseURL = "https://api.anthropic.com/v1/messages"

    /// API Version
    static let anthropicVersion = "2023-06-01"

    // MARK: - Model Configuration

    /// Default model: Claude 3.5 Haiku (fastest, cheapest, perfect for our use case)
    static let defaultModel = "claude-3-5-haiku-20241022"

    /// Max tokens per request
    static let maxTokens = 1024

    /// Temperature (0.0-1.0, higher = more creative)
    static let defaultTemperature = 0.7

    // MARK: - Cost Tracking

    /// Input cost per 1M tokens (USD)
    static let inputCostPer1M: Double = 0.25

    /// Output cost per 1M tokens (USD)
    static let outputCostPer1M: Double = 1.25

    // MARK: - Rate Limiting

    /// Max requests per minute
    static let maxRequestsPerMinute = 50

    /// Max tokens per minute
    static let maxTokensPerMinute = 50_000
}

// MARK: - Environment Detection

extension APIConfig {
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }

    static var apiKeyMasked: String {
        let key = claudeAPIKey
        guard key.count > 10 else { return "***" }
        let start = key.prefix(8)
        let end = key.suffix(4)
        return "\(start)...\(end)"
    }
}
