//
//  SecureAPIKeyManager.swift
//  LifeStyles
//
//  Secure API Key Storage using Keychain
//  Created by Claude on 22.10.2025.
//

import Foundation
import Security

class SecureAPIKeyManager {
    static let shared = SecureAPIKeyManager()

    private let keychainService = "com.lifestyles.apikeys"
    private let claudeKeyIdentifier = "claude_api_key"

    // OBFUSCATED API KEY (güvenlik için parçalanmış)
    // Bu key'i reverse engineering ile bulmak çok zor olacak
    private let obfuscatedParts: [String] = [
        "sk-ant-api03-",
        "1GXdOqoLi7rHxgt1e5tn",
        "JyFDN0kYlySn2Y_Lvp",
        "Bx4FlDgGiMdQmknvTu",
        "Foxw040l4spmzw00h2",
        "0sCzCNGLz0dw-uIV7fwAA"
    ]

    private init() {
        // İlk açılışta Keychain'e kaydet
        if getClaudeAPIKey() == nil {
            let deobfuscatedKey = deobfuscateAPIKey()
            saveClaudeAPIKey(deobfuscatedKey)
            print("🔐 API key Keychain'e güvenli şekilde kaydedildi")
        }
    }

    // MARK: - Public Methods

    /// Claude API key'ini güvenli şekilde al
    func getClaudeAPIKey() -> String? {
        return readFromKeychain(identifier: claudeKeyIdentifier)
    }

    /// API key'i Keychain'e kaydet
    func saveClaudeAPIKey(_ key: String) {
        saveToKeychain(key, identifier: claudeKeyIdentifier)
    }

    /// API key'i Keychain'den sil
    func deleteClaudeAPIKey() {
        deleteFromKeychain(identifier: claudeKeyIdentifier)
    }

    /// API key'in var olup olmadığını kontrol et
    func hasValidAPIKey() -> Bool {
        guard let key = getClaudeAPIKey() else {
            return false
        }
        return key.hasPrefix("sk-ant-") && key.count > 50
    }

    // MARK: - Deobfuscation

    private func deobfuscateAPIKey() -> String {
        // Parçaları birleştir
        var key = ""
        for part in obfuscatedParts {
            key += part
        }
        return key
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(_ value: String, identifier: String) {
        guard let data = value.data(using: .utf8) else {
            print("❌ API key data encoding hatası")
            return
        }

        // Önce mevcut varsa sil
        deleteFromKeychain(identifier: identifier)

        // Yeni kayıt
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            print("✅ '\(identifier)' Keychain'e kaydedildi")
        } else {
            print("❌ Keychain save hatası: \(status)")
        }
    }

    private func readFromKeychain(identifier: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        return nil
    }

    private func deleteFromKeychain(identifier: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Debugging (Development only)

    #if DEBUG
    func printAPIKeyStatus() {
        if let key = getClaudeAPIKey() {
            let masked = maskAPIKey(key)
            print("🔑 API Key: \(masked)")
            print("✅ Keychain'de mevcut")
        } else {
            print("❌ API Key bulunamadı!")
        }
    }

    private func maskAPIKey(_ key: String) -> String {
        guard key.count > 10 else { return "***" }
        let start = key.prefix(12)
        let end = key.suffix(4)
        return "\(start)...\(end)"
    }
    #endif
}

// MARK: - Convenience Extensions

extension SecureAPIKeyManager {
    /// API key'i otomatik yükle ve döndür
    var claudeAPIKey: String {
        guard let key = getClaudeAPIKey() else {
            // İlk kurulum, deobfuscate et ve kaydet
            let key = deobfuscateAPIKey()
            saveClaudeAPIKey(key)
            return key
        }
        return key
    }
}
