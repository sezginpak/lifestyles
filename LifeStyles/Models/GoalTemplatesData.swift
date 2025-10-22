//
//  GoalTemplatesData.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation

/// Hedef şablon modeli
struct GoalTemplate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let emoji: String
    let category: GoalCategory
    let suggestedDays: Int // Önerilen gün sayısı
    let description: String

    /// Hedef tarihi hesapla (bugünden itibaren suggestedDays sonra)
    var suggestedTargetDate: Date {
        Calendar.current.date(byAdding: .day, value: suggestedDays, to: Date()) ?? Date()
    }
}

/// Tüm hazır hedef şablonları
struct GoalTemplatesData {
    static let templates: [GoalTemplate] = [
        // MARK: - Health (Sağlık)
        GoalTemplate(
            title: "10 Kilo Ver",
            emoji: "💪",
            category: .health,
            suggestedDays: 90,
            description: "Sağlıklı beslenme ve düzenli egzersizle ideal kilomu yakala"
        ),
        GoalTemplate(
            title: "Her Gün 10K Adım At",
            emoji: "👟",
            category: .health,
            suggestedDays: 30,
            description: "Günlük 10.000 adım hedefiyle aktif bir yaşam sür"
        ),
        GoalTemplate(
            title: "Su İçme Alışkanlığı",
            emoji: "💧",
            category: .health,
            suggestedDays: 21,
            description: "Her gün 2 litre su içmeyi alışkanlık haline getir"
        ),
        GoalTemplate(
            title: "Sağlıklı Beslenme",
            emoji: "🥗",
            category: .health,
            suggestedDays: 60,
            description: "Dengeli ve besleyici yiyeceklerle sağlıklı beslen"
        ),

        // MARK: - Fitness
        GoalTemplate(
            title: "Haftada 3 Gün Spor",
            emoji: "🏋️",
            category: .fitness,
            suggestedDays: 90,
            description: "Düzenli spor yaparak formda kal"
        ),
        GoalTemplate(
            title: "Yarı Maraton Koş",
            emoji: "🏃",
            category: .fitness,
            suggestedDays: 120,
            description: "21 km koşu için kendini hazırla"
        ),
        GoalTemplate(
            title: "Yoga ile Esneklik",
            emoji: "🧘",
            category: .fitness,
            suggestedDays: 60,
            description: "Düzenli yoga ile esnekliğini ve dengeyi artır"
        ),
        GoalTemplate(
            title: "Kas Kütlesi Artır",
            emoji: "💪",
            category: .fitness,
            suggestedDays: 90,
            description: "Güç antrenmanlarıyla kas kütleni artır"
        ),

        // MARK: - Career (Kariyer)
        GoalTemplate(
            title: "Yeni Beceri Öğren",
            emoji: "📚",
            category: .career,
            suggestedDays: 90,
            description: "Kariyerine değer katacak yeni bir beceri kazan"
        ),
        GoalTemplate(
            title: "Terfi Al",
            emoji: "📈",
            category: .career,
            suggestedDays: 180,
            description: "Performansını artırarak bir sonraki seviyeye geç"
        ),
        GoalTemplate(
            title: "Sertifika Al",
            emoji: "🎓",
            category: .career,
            suggestedDays: 120,
            description: "Alanında profesyonel sertifika kazan"
        ),
        GoalTemplate(
            title: "Network Genişlet",
            emoji: "🤝",
            category: .career,
            suggestedDays: 90,
            description: "Sektöründe 50+ yeni bağlantı kur"
        ),

        // MARK: - Social (Sosyal İlişkiler)
        GoalTemplate(
            title: "Haftada 1 Arkadaş Gör",
            emoji: "👥",
            category: .social,
            suggestedDays: 30,
            description: "Sosyal bağlarını güçlendirmek için düzenli görüş"
        ),
        GoalTemplate(
            title: "Yeni Arkadaşlar Edin",
            emoji: "🎉",
            category: .social,
            suggestedDays: 60,
            description: "Yeni aktivitelerle 10+ yeni arkadaş edin"
        ),
        GoalTemplate(
            title: "Aile Zamanı",
            emoji: "👨‍👩‍👧‍👦",
            category: .social,
            suggestedDays: 30,
            description: "Ailenle kaliteli vakit geçir"
        ),

        // MARK: - Personal (Kişisel Gelişim)
        GoalTemplate(
            title: "Her Gün Kitap Oku",
            emoji: "📖",
            category: .personal,
            suggestedDays: 30,
            description: "Günde 30 dakika okuma alışkanlığı edin"
        ),
        GoalTemplate(
            title: "Yeni Dil Öğren",
            emoji: "🗣️",
            category: .personal,
            suggestedDays: 180,
            description: "Temel seviyede yeni bir dil öğren"
        ),
        GoalTemplate(
            title: "Meditasyon Alışkanlığı",
            emoji: "🧘‍♀️",
            category: .personal,
            suggestedDays: 21,
            description: "Günlük 10 dakika meditasyon yap"
        ),
        GoalTemplate(
            title: "Sabah Rutini",
            emoji: "☀️",
            category: .personal,
            suggestedDays: 30,
            description: "Sabahları 6:00'da kalk ve rutin oluştur"
        ),
        GoalTemplate(
            title: "Yaratıcı Hobi",
            emoji: "🎨",
            category: .personal,
            suggestedDays: 60,
            description: "Resim, müzik gibi yaratıcı bir hobi edin"
        ),

        // MARK: - Other (Diğer)
        GoalTemplate(
            title: "Para Biriktir",
            emoji: "💰",
            category: .other,
            suggestedDays: 180,
            description: "Düzenli tasarruf yaparak hedef miktara ulaş"
        ),
        GoalTemplate(
            title: "Ev Projesi Tamamla",
            emoji: "🏠",
            category: .other,
            suggestedDays: 60,
            description: "Ertelediğin ev projesini tamamla"
        )
    ]

    /// Kategoriye göre şablonları filtrele
    static func templates(for category: GoalCategory) -> [GoalTemplate] {
        templates.filter { $0.category == category }
    }

    /// Popüler şablonlar (en kısa süreliler)
    static var popularTemplates: [GoalTemplate] {
        templates.sorted { $0.suggestedDays < $1.suggestedDays }.prefix(6).map { $0 }
    }
}
