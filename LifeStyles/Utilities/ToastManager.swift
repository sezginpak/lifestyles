//
//  ToastManager.swift
//  LifeStyles
//
//  Toast bildirim sistemi - Merkezi state management
//  NotificationService ile entegre in-app bildirimler
//

import SwiftUI

// MARK: - Toast Type

/// Toast bildirim tipleri
enum ToastType {
    case success
    case error
    case warning
    case info
    case custom(icon: String, color: Color)

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .custom(let icon, _): return icon
        }
    }

    var color: Color {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        case .custom(_, let color): return color
        }
    }

    var hapticType: HapticFeedbackType {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        case .info: return .light
        case .custom: return .medium
        }
    }
}

// MARK: - Haptic Feedback Type

enum HapticFeedbackType {
    case success, error, warning, light, medium, heavy
}

// MARK: - Toast Model

/// Toast bildirim verisi
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String?
    let type: ToastType
    let duration: TimeInterval
    let emoji: String?

    init(
        title: String,
        message: String? = nil,
        type: ToastType = .info,
        duration: TimeInterval = 3.0,
        emoji: String? = nil
    ) {
        self.title = title
        self.message = message
        self.type = type
        self.duration = duration
        self.emoji = emoji
    }

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager

/// Toast bildirim yöneticisi - Singleton pattern, @Observable ile reactive
@Observable
class ToastManager {
    static let shared = ToastManager()

    private(set) var currentToast: Toast?
    private var toastQueue: [Toast] = []
    private var isShowingToast = false

    private init() {}

    // MARK: - Public Methods

    /// Toast göster
    func show(_ toast: Toast) {
        // Haptic feedback
        triggerHaptic(for: toast.type.hapticType)

        // Eğer bir toast gösteriliyorsa kuyruğa ekle
        if isShowingToast {
            toastQueue.append(toast)
            return
        }

        // Toast'u göster
        displayToast(toast)
    }

    /// Hızlı success toast
    func success(title: String, message: String? = nil, emoji: String? = nil) {
        let toast = Toast(
            title: title,
            message: message,
            type: .success,
            duration: 2.5,
            emoji: emoji ?? "✓"
        )
        show(toast)
    }

    /// Hızlı error toast
    func error(title: String, message: String? = nil, emoji: String? = nil) {
        let toast = Toast(
            title: title,
            message: message,
            type: .error,
            duration: 3.5,
            emoji: emoji ?? "✗"
        )
        show(toast)
    }

    /// Hızlı warning toast
    func warning(title: String, message: String? = nil, emoji: String? = nil) {
        let toast = Toast(
            title: title,
            message: message,
            type: .warning,
            duration: 3.0,
            emoji: emoji ?? "⚠️"
        )
        show(toast)
    }

    /// Hızlı info toast
    func info(title: String, message: String? = nil, emoji: String? = nil) {
        let toast = Toast(
            title: title,
            message: message,
            type: .info,
            duration: 2.5,
            emoji: emoji ?? "ℹ️"
        )
        show(toast)
    }

    /// Custom toast
    func custom(
        title: String,
        message: String? = nil,
        icon: String,
        color: Color,
        duration: TimeInterval = 3.0,
        emoji: String? = nil
    ) {
        let toast = Toast(
            title: title,
            message: message,
            type: .custom(icon: icon, color: color),
            duration: duration,
            emoji: emoji
        )
        show(toast)
    }

    /// Toast'u manuel olarak kapat
    func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentToast = nil
            isShowingToast = false
        }

        // Sıradaki toast'u göster
        showNextInQueue()
    }

    // MARK: - Private Methods

    private func displayToast(_ toast: Toast) {
        isShowingToast = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentToast = toast
        }

        // Otomatik kapanma
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))

            // Hala aynı toast gösteriliyorsa kapat
            if currentToast?.id == toast.id {
                dismiss()
            }
        }
    }

    private func showNextInQueue() {
        guard !toastQueue.isEmpty else { return }

        let nextToast = toastQueue.removeFirst()

        // Kısa bir gecikme ile sonraki toast'u göster
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 saniye
            displayToast(nextToast)
        }
    }

    private func triggerHaptic(for type: HapticFeedbackType) {
        switch type {
        case .success: HapticFeedback.success()
        case .error: HapticFeedback.error()
        case .warning: HapticFeedback.warning()
        case .light: HapticFeedback.light()
        case .medium: HapticFeedback.medium()
        case .heavy: HapticFeedback.heavy()
        }
    }
}
