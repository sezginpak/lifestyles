//
//  HabitTemplatesData.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation

/// Alışkanlık şablon modeli
struct HabitTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let emoji: String
    let frequency: HabitFrequency
    let targetCount: Int
    let description: String
    let defaultReminderHour: Int? // Örn: 7 (sabah 7:00)

    /// Önerilen hatırlatıcı zamanı
    var suggestedReminderTime: Date? {
        guard let hour = defaultReminderHour else { return nil }
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components)
    }
}

/// Tüm hazır alışkanlık şablonları
struct HabitTemplatesData {
    static let templates: [HabitTemplate] = [
        // MARK: - Daily (Günlük)
        HabitTemplate(
            name: "Sabah Meditasyonu",
            emoji: "🧘",
            frequency: .daily,
            targetCount: 1,
            description: "Her sabah 10 dakika meditasyon yap",
            defaultReminderHour: 7
        ),
        HabitTemplate(
            name: "Su İç",
            emoji: "💧",
            frequency: .daily,
            targetCount: 8,
            description: "Günde 8 bardak su iç",
            defaultReminderHour: 9
        ),
        HabitTemplate(
            name: "Sabah Egzersizi",
            emoji: "🏃",
            frequency: .daily,
            targetCount: 1,
            description: "Her sabah 30 dakika egzersiz yap",
            defaultReminderHour: 6
        ),
        HabitTemplate(
            name: "Kitap Oku",
            emoji: "📚",
            frequency: .daily,
            targetCount: 1,
            description: "Her gün en az 30 dakika kitap oku",
            defaultReminderHour: 21
        ),
        HabitTemplate(
            name: "Günlük Tutma",
            emoji: "📝",
            frequency: .daily,
            targetCount: 1,
            description: "Gün sonunda düşüncelerini yaz",
            defaultReminderHour: 22
        ),
        HabitTemplate(
            name: "Meyve/Sebze Ye",
            emoji: "🥗",
            frequency: .daily,
            targetCount: 5,
            description: "Günde 5 porsiyon meyve veya sebze tüket",
            defaultReminderHour: 12
        ),
        HabitTemplate(
            name: "İngilizce Çalış",
            emoji: "🇬🇧",
            frequency: .daily,
            targetCount: 1,
            description: "Her gün 20 dakika İngilizce pratik yap",
            defaultReminderHour: 19
        ),
        HabitTemplate(
            name: "Temiz Oda",
            emoji: "🧹",
            frequency: .daily,
            targetCount: 1,
            description: "Odanı her akşam toparla",
            defaultReminderHour: 20
        ),
        HabitTemplate(
            name: "Minnettar Ol",
            emoji: "🙏",
            frequency: .daily,
            targetCount: 3,
            description: "Her gün 3 şey için şükret",
            defaultReminderHour: 22
        ),
        HabitTemplate(
            name: "Erken Kalk",
            emoji: "☀️",
            frequency: .daily,
            targetCount: 1,
            description: "Her sabah 6:00'da kalk",
            defaultReminderHour: 6
        ),
        HabitTemplate(
            name: "Ekran Molası",
            emoji: "📱",
            frequency: .daily,
            targetCount: 1,
            description: "Akşam 21:00'den sonra ekran kullanma",
            defaultReminderHour: 20
        ),
        HabitTemplate(
            name: "Nefes Egzersizi",
            emoji: "💨",
            frequency: .daily,
            targetCount: 3,
            description: "Günde 3 kez 5 dakika nefes egzersizi",
            defaultReminderHour: 10
        ),

        // MARK: - Weekly (Haftalık)
        HabitTemplate(
            name: "Spor Salonuna Git",
            emoji: "🏋️",
            frequency: .weekly,
            targetCount: 3,
            description: "Haftada 3 gün spor salonu",
            defaultReminderHour: 18
        ),
        HabitTemplate(
            name: "Arkadaş Görüş",
            emoji: "👥",
            frequency: .weekly,
            targetCount: 1,
            description: "Haftada en az bir arkadaşınla görüş",
            defaultReminderHour: nil
        ),
        HabitTemplate(
            name: "Yemek Pişir",
            emoji: "👨‍🍳",
            frequency: .weekly,
            targetCount: 5,
            description: "Haftada 5 gün evde yemek yap",
            defaultReminderHour: 17
        ),
        HabitTemplate(
            name: "Yürüyüşe Çık",
            emoji: "🚶",
            frequency: .weekly,
            targetCount: 4,
            description: "Haftada 4 gün doğa yürüyüşü",
            defaultReminderHour: 10
        ),
        HabitTemplate(
            name: "Yoga Dersi",
            emoji: "🧘‍♀️",
            frequency: .weekly,
            targetCount: 2,
            description: "Haftada 2 yoga seansı",
            defaultReminderHour: 19
        ),
        HabitTemplate(
            name: "Podcast Dinle",
            emoji: "🎧",
            frequency: .weekly,
            targetCount: 3,
            description: "Haftada 3 eğitici podcast dinle",
            defaultReminderHour: nil
        ),

        // MARK: - Monthly (Aylık)
        HabitTemplate(
            name: "Kitap Oku",
            emoji: "📖",
            frequency: .monthly,
            targetCount: 2,
            description: "Ayda 2 kitap bitir",
            defaultReminderHour: nil
        ),
        HabitTemplate(
            name: "Yeni Şeyler Dene",
            emoji: "🎯",
            frequency: .monthly,
            targetCount: 1,
            description: "Her ay yeni bir aktivite dene",
            defaultReminderHour: nil
        ),
        HabitTemplate(
            name: "Müze/Sergi Gez",
            emoji: "🏛️",
            frequency: .monthly,
            targetCount: 1,
            description: "Ayda bir kültürel aktivite",
            defaultReminderHour: nil
        ),
        HabitTemplate(
            name: "Gönüllü Çalışma",
            emoji: "❤️",
            frequency: .monthly,
            targetCount: 1,
            description: "Ayda bir gün gönüllü çalışma yap",
            defaultReminderHour: nil
        ),
        HabitTemplate(
            name: "Finansal Kontrol",
            emoji: "💰",
            frequency: .monthly,
            targetCount: 1,
            description: "Ay sonunda bütçeni gözden geçir",
            defaultReminderHour: nil
        )
    ]

    /// Frekansa göre şablonları filtrele
    static func templates(for frequency: HabitFrequency) -> [HabitTemplate] {
        templates.filter { $0.frequency == frequency }
    }

    /// Günlük şablonlar
    static var dailyTemplates: [HabitTemplate] {
        templates(for: .daily)
    }

    /// Haftalık şablonlar
    static var weeklyTemplates: [HabitTemplate] {
        templates(for: .weekly)
    }

    /// Aylık şablonlar
    static var monthlyTemplates: [HabitTemplate] {
        templates(for: .monthly)
    }

    /// Popüler şablonlar (günlük olanların ilk 6'sı)
    static var popularTemplates: [HabitTemplate] {
        dailyTemplates.prefix(6).map { $0 }
    }
}
