//
//  BiometricAuthService.swift
//  LifeStyles
//
//  Created by Claude on 26.10.2025.
//  Face ID / Touch ID Authentication Service
//

import Foundation
import LocalAuthentication

/// Biyometrik kimlik doğrulama servisi
@Observable
class BiometricAuthService {
    static let shared = BiometricAuthService()

    private let context = LAContext()
    private let reason = "Gizli anılarınızı görüntülemek için kimlik doğrulaması yapın"

    /// Biyometrik doğrulama mevcut mu?
    var biometricType: BiometricType {
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("❌ Biometric unavailable: \(error?.localizedDescription ?? "Unknown")")
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }

    /// Cihaz passcode ile korunuyor mu?
    var isDeviceSecure: Bool {
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    /// Biyometrik doğrulama yap
    func authenticate() async -> Result<Void, AuthenticationError> {
        let context = LAContext()
        context.localizedCancelTitle = "İptal"
        context.localizedFallbackTitle = "Şifre Gir"

        do {
            // Önce biyometrik dene
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                print("✅ Biometric authentication successful")
                return .success(())
            } else {
                print("❌ Biometric authentication failed")
                return .failure(.failed)
            }
        } catch let error as LAError {
            print("❌ Authentication error: \(error.localizedDescription)")
            return .failure(mapError(error))
        } catch {
            print("❌ Unknown authentication error: \(error)")
            return .failure(.unknown)
        }
    }

    /// Cihaz sahipliği doğrulaması (biyometrik veya passcode)
    func authenticateWithPasscodeFallback() async -> Result<Void, AuthenticationError> {
        let context = LAContext()
        context.localizedCancelTitle = "İptal"

        do {
            // Biyometrik + Passcode fallback
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            if success {
                print("✅ Authentication successful (biometric or passcode)")
                return .success(())
            } else {
                return .failure(.failed)
            }
        } catch let error as LAError {
            return .failure(mapError(error))
        } catch {
            return .failure(.unknown)
        }
    }

    // MARK: - Private Helpers

    private func mapError(_ error: LAError) -> AuthenticationError {
        switch error.code {
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .authenticationFailed:
            return .failed
        case .passcodeNotSet:
            return .passcodeNotSet
        case .systemCancel:
            return .systemCancel
        default:
            return .unknown
        }
    }
}

// MARK: - Supporting Types

enum BiometricType {
    case faceID
    case touchID
    case opticID
    case none

    var displayName: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biyometrik Doğrulama"
        }
    }

    var iconName: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        }
    }
}

enum AuthenticationError: Error, LocalizedError {
    case userCancel         // Kullanıcı iptal etti
    case userFallback       // Passcode girmeyi seçti
    case notAvailable       // Biyometrik mevcut değil
    case notEnrolled        // Kayıtlı biyometrik yok
    case lockout            // Çok fazla başarısız deneme
    case failed             // Doğrulama başarısız
    case passcodeNotSet     // Cihaz passcode'u yok
    case systemCancel       // Sistem iptal etti (başka uygulama açıldı)
    case unknown            // Bilinmeyen hata

    var errorDescription: String? {
        switch self {
        case .userCancel:
            return "Kimlik doğrulama iptal edildi"
        case .userFallback:
            return "Passcode girmeyi seçtiniz"
        case .notAvailable:
            return "Bu cihazda biyometrik doğrulama mevcut değil"
        case .notEnrolled:
            return "Biyometrik doğrulama ayarlanmamış. Lütfen Ayarlar'dan yapılandırın"
        case .lockout:
            return "Çok fazla başarısız deneme. Lütfen cihaz şifrenizi girin"
        case .failed:
            return "Kimlik doğrulama başarısız"
        case .passcodeNotSet:
            return "Cihazınızda passcode ayarlanmamış. Lütfen Ayarlar'dan ayarlayın"
        case .systemCancel:
            return "Kimlik doğrulama sistem tarafından iptal edildi"
        case .unknown:
            return "Bilinmeyen bir hata oluştu"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notEnrolled:
            return "Ayarlar > Face ID ve Parola bölümünden Face ID'yi aktifleştirin"
        case .notAvailable:
            return "Bu özellik sadece Face ID/Touch ID destekleyen cihazlarda kullanılabilir"
        case .passcodeNotSet:
            return "Ayarlar > Parola bölümünden cihaz şifrenizi oluşturun"
        case .lockout:
            return "Cihaz şifrenizi girerek kilidi açabilirsiniz"
        default:
            return nil
        }
    }
}
