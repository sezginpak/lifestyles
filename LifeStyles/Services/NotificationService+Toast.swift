//
//  NotificationService+Toast.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Toast notification display methods
//

import Foundation

extension NotificationService {

    // MARK: - Generic Toast Methods

    /// In-app toast bildirimi göster (sistem bildirimi yerine)
    /// Uygulama foreground'dayken kullanılır
    /// - Parameters:
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    ///   - type: Toast tipi (.info, .success, .warning, .error)
    ///   - emoji: İsteğe bağlı emoji
    func showToast(
        title: String,
        message: String? = nil,
        type: ToastType = .info,
        emoji: String? = nil
    ) {
        ToastManager.shared.show(
            Toast(
                title: title,
                message: message,
                type: type,
                duration: 3.0,
                emoji: emoji
            )
        )
    }

    // MARK: - Friend Toast

    /// Arkadaş için toast göster
    /// - Parameters:
    ///   - friend: Arkadaş
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    func showFriendToast(
        friend: Friend,
        title: String,
        message: String? = nil
    ) {
        ToastManager.shared.success(
            title: title,
            message: message,
            emoji: friend.avatarEmoji ?? "👤"
        )
    }

    // MARK: - Goal Toast

    /// Hedef için toast göster
    /// - Parameters:
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    ///   - isSuccess: Başarı durumu
    func showGoalToast(
        title: String,
        message: String? = nil,
        isSuccess: Bool = true
    ) {
        if isSuccess {
            ToastManager.shared.success(
                title: title,
                message: message,
                emoji: "🎯"
            )
        } else {
            ToastManager.shared.warning(
                title: title,
                message: message,
                emoji: "🎯"
            )
        }
    }

    // MARK: - Habit Toast

    /// Alışkanlık için toast göster
    /// - Parameters:
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    ///   - isCompleted: Tamamlama durumu
    func showHabitToast(
        title: String,
        message: String? = nil,
        isCompleted: Bool = true
    ) {
        if isCompleted {
            ToastManager.shared.success(
                title: title,
                message: message,
                emoji: "⭐"
            )
        } else {
            ToastManager.shared.info(
                title: title,
                message: message,
                emoji: "⭐"
            )
        }
    }

    // MARK: - Mood Toast

    /// Mood için toast göster
    /// - Parameters:
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    ///   - mood: Ruh hali emoji'si
    func showMoodToast(
        title: String,
        message: String? = nil,
        mood: String? = nil
    ) {
        ToastManager.shared.success(
            title: title,
            message: message,
            emoji: mood ?? "😊"
        )
    }

    // MARK: - Location Toast

    /// Konum için toast göster
    /// - Parameters:
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    ///   - type: Toast tipi
    func showLocationToast(
        title: String,
        message: String? = nil,
        type: ToastType = .info
    ) {
        ToastManager.shared.show(
            Toast(
                title: title,
                message: message,
                type: type,
                emoji: "📍"
            )
        )
    }

    // MARK: - Typed Toast Methods

    /// Genel başarı toast
    /// - Parameters:
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    ///   - emoji: Toast emoji'si
    func showSuccessToast(title: String, message: String? = nil, emoji: String? = nil) {
        ToastManager.shared.success(title: title, message: message, emoji: emoji)
    }

    /// Genel hata toast
    /// - Parameters:
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    ///   - emoji: Toast emoji'si
    func showErrorToast(title: String, message: String? = nil, emoji: String? = nil) {
        ToastManager.shared.error(title: title, message: message, emoji: emoji)
    }

    /// Genel uyarı toast
    /// - Parameters:
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    ///   - emoji: Toast emoji'si
    func showWarningToast(title: String, message: String? = nil, emoji: String? = nil) {
        ToastManager.shared.warning(title: title, message: message, emoji: emoji)
    }

    /// Genel bilgi toast
    /// - Parameters:
    ///   - title: Bildirim başlığı
    ///   - message: Bildirim mesajı
    ///   - emoji: Toast emoji'si
    func showInfoToast(title: String, message: String? = nil, emoji: String? = nil) {
        ToastManager.shared.info(title: title, message: message, emoji: emoji)
    }
}
