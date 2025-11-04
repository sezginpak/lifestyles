//
//  SecurityUtilities.swift
//  LifeStyles
//
//  Security utilities - Jailbreak detection, etc.
//  Created by Claude on 04.11.2025.
//

import Foundation
import UIKit

/// Güvenlik kontrolü utilities
class SecurityUtilities {
    static let shared = SecurityUtilities()

    private init() {}

    // MARK: - Jailbreak Detection

    /// Cihazın jailbreak olup olmadığını kontrol et
    func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        // Simulator'da her zaman false döndür
        return false
        #else
        return checkJailbreakFiles() || checkJailbreakDirectoryPermissions() || checkSuspiciousApps()
        #endif
    }

    /// Jailbreak dosyalarını kontrol et
    private func checkJailbreakFiles() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/tmp/cydia.log",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/usr/bin/ssh"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("⚠️ Jailbreak dosyası bulundu: \(path)")
                return true
            }
        }

        return false
    }

    /// Sistem dizinlerine yazma kontrolü (jailbreak'li cihazlarda yazılabilir)
    private func checkJailbreakDirectoryPermissions() -> Bool {
        let testPath = "/private/jailbreak-test-\(UUID().uuidString).txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            print("⚠️ Sistem dizinine yazma izni var (jailbreak)")
            return true
        } catch {
            // Yazamadı, güvenli
            return false
        }
    }

    /// Şüpheli uygulamaları kontrol et
    private func checkSuspiciousApps() -> Bool {
        let suspiciousSchemes = [
            "cydia://",
            "sileo://",
            "zbra://",
            "filza://"
        ]

        for scheme in suspiciousSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                print("⚠️ Şüpheli uygulama bulundu: \(scheme)")
                return true
            }
        }

        return false
    }

    // MARK: - Security Check Result

    /// Güvenlik durumunu döndür
    func getSecurityStatus() -> SecurityStatus {
        let jailbroken = isJailbroken()

        return SecurityStatus(
            isJailbroken: jailbroken,
            isSecure: !jailbroken
        )
    }
}

// MARK: - Security Status Model

struct SecurityStatus {
    let isJailbroken: Bool
    let isSecure: Bool

    var warningMessage: String? {
        if isJailbroken {
            return "Bu cihaz jailbreak'li. Güvenlik nedeniyle bazı özellikler devre dışı bırakıldı."
        }
        return nil
    }
}
