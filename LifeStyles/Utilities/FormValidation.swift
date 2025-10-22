//
//  FormValidation.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation

/// Hedef form validasyon helper'ları
struct GoalValidation {
    /// Başlık validasyonu
    /// - Parameter title: Kontrol edilecek başlık
    /// - Returns: Hata mesajı (nil ise geçerli)
    static func validateTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "Başlık boş olamaz"
        }

        if trimmed.count < 3 {
            return "Başlık en az 3 karakter olmalı"
        }

        if trimmed.count > 100 {
            return "Başlık en fazla 100 karakter olabilir"
        }

        return nil
    }

    /// Tarih validasyonu
    /// - Parameter date: Kontrol edilecek tarih
    /// - Returns: Hata mesajı (nil ise geçerli)
    static func validateDate(_ date: Date) -> String? {
        let calendar = Calendar.current
        let now = Date()

        // Geçmiş tarih kontrolü
        if calendar.isDate(date, inSameDayAs: now) {
            // Bugün seçilmişse kabul et
            return nil
        }

        if date < now {
            return "Hedef tarihi gelecekte olmalı"
        }

        // Çok uzak gelecek kontrolü (10 yıl)
        if let tenYearsLater = calendar.date(byAdding: .year, value: 10, to: now),
           date > tenYearsLater {
            return "Hedef tarihi 10 yıldan uzak olamaz"
        }

        return nil
    }

    /// Açıklama validasyonu
    /// - Parameter description: Kontrol edilecek açıklama
    /// - Returns: Hata mesajı (nil ise geçerli)
    static func validateDescription(_ description: String) -> String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Açıklama opsiyonel, boş olabilir
        if trimmed.isEmpty {
            return nil
        }

        if trimmed.count > 500 {
            return "Açıklama en fazla 500 karakter olabilir"
        }

        return nil
    }

    /// Tüm hedef alanlarını validate et
    /// - Parameters:
    ///   - title: Başlık
    ///   - date: Hedef tarihi
    ///   - description: Açıklama
    /// - Returns: İlk bulunan hata mesajı (nil ise tümü geçerli)
    static func validateAll(title: String, date: Date, description: String) -> String? {
        if let titleError = validateTitle(title) {
            return titleError
        }

        if let dateError = validateDate(date) {
            return dateError
        }

        if let descError = validateDescription(description) {
            return descError
        }

        return nil
    }
}

/// Alışkanlık form validasyon helper'ları
struct HabitValidation {
    /// İsim validasyonu
    /// - Parameter name: Kontrol edilecek isim
    /// - Returns: Hata mesajı (nil ise geçerli)
    static func validateName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "Alışkanlık ismi boş olamaz"
        }

        if trimmed.count < 2 {
            return "İsim en az 2 karakter olmalı"
        }

        if trimmed.count > 80 {
            return "İsim en fazla 80 karakter olabilir"
        }

        return nil
    }

    /// Hedef sayısı validasyonu
    /// - Parameter targetCount: Kontrol edilecek hedef sayısı
    /// - Returns: Hata mesajı (nil ise geçerli)
    static func validateTargetCount(_ targetCount: Int) -> String? {
        if targetCount < 1 {
            return "Hedef sayısı en az 1 olmalı"
        }

        if targetCount > 100 {
            return "Hedef sayısı en fazla 100 olabilir"
        }

        return nil
    }

    /// Açıklama validasyonu
    /// - Parameter description: Kontrol edilecek açıklama
    /// - Returns: Hata mesajı (nil ise geçerli)
    static func validateDescription(_ description: String) -> String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Açıklama opsiyonel
        if trimmed.isEmpty {
            return nil
        }

        if trimmed.count > 300 {
            return "Açıklama en fazla 300 karakter olabilir"
        }

        return nil
    }

    /// Tüm alışkanlık alanlarını validate et
    /// - Parameters:
    ///   - name: İsim
    ///   - targetCount: Hedef sayısı
    ///   - description: Açıklama
    /// - Returns: İlk bulunan hata mesajı (nil ise tümü geçerli)
    static func validateAll(name: String, targetCount: Int, description: String) -> String? {
        if let nameError = validateName(name) {
            return nameError
        }

        if let countError = validateTargetCount(targetCount) {
            return countError
        }

        if let descError = validateDescription(description) {
            return descError
        }

        return nil
    }
}
