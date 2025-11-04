//
//  PlaceBasedSuggestions.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Bulunulan yere göre akıllı aktivite önerileri
//

import Foundation
import SwiftData

struct PlaceSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let action: SuggestionAction?
    let priority: Int // 1-5, higher = more important
}

enum SuggestionAction {
    case openApp(String) // Bundle ID
    case openURL(URL)
    case custom(String) // Custom action identifier
}

struct PlaceBasedSuggestions {
    static let shared = PlaceBasedSuggestions()

    private init() {}

    // MARK: - Main Suggestion Engine

    /// Get suggestions for a specific place
    func getSuggestions(for place: SavedPlace, timeOfDay: PlaceTimeOfDay? = nil) -> [PlaceSuggestion] {
        let time = timeOfDay ?? getCurrentPlaceTimeOfDay()

        var suggestions: [PlaceSuggestion] = []

        // Category-based suggestions
        suggestions.append(contentsOf: getCategorySuggestions(for: place.category, time: time))

        // Time-based suggestions
        suggestions.append(contentsOf: getTimeSuggestions(time: time, placeCategory: place.category))

        // Custom place-specific suggestions
        suggestions.append(contentsOf: getCustomSuggestions(for: place))

        // Sort by priority
        return suggestions.sorted { $0.priority > $1.priority }
    }

    // MARK: - Category Suggestions

    private func getCategorySuggestions(for category: PlaceCategory, time: PlaceTimeOfDay) -> [PlaceSuggestion] {
        switch category {
        case .home:
            return getHomeSuggestions(time: time)
        case .work:
            return getWorkSuggestions(time: time)
        case .gym:
            return getGymSuggestions(time: time)
        case .cafe:
            return getCafeSuggestions(time: time)
        case .shopping:
            return getShoppingSuggestions()
        case .restaurant:
            return getRestaurantSuggestions()
        case .park:
            return getParkSuggestions(time: time)
        case .school:
            return getSchoolSuggestions()
        case .hospital:
            return getHospitalSuggestions()
        case .custom:
            return []
        }
    }

    // MARK: - Home Suggestions

    private func getHomeSuggestions(time: PlaceTimeOfDay) -> [PlaceSuggestion] {
        var suggestions: [PlaceSuggestion] = []

        switch time {
        case .morning:
            suggestions.append(PlaceSuggestion(
                title: String(localized: "activity.home.start.day.title", comment: "Start day"),
                description: String(localized: "activity.home.start.day.desc", comment: "Start day desc"),
                icon: "sunrise.fill",
                action: nil,
                priority: 4
            ))
            suggestions.append(PlaceSuggestion(
                title: String(localized: "activity.home.review.goals.title", comment: "Review goals"),
                description: String(localized: "activity.home.review.goals.desc", comment: "Review goals desc"),
                icon: "target",
                action: nil,
                priority: 3
            ))

        case .afternoon:
            suggestions.append(PlaceSuggestion(
                title: String(localized: "activity.home.short.break.title", comment: "Short break"),
                description: String(localized: "activity.home.short.break.desc", comment: "Short break desc"),
                icon: "pause.circle.fill",
                action: nil,
                priority: 3
            ))

        case .evening:
            suggestions.append(PlaceSuggestion(
                title: String(localized: "activity.home.connect.friends.title", comment: "Connect friends"),
                description: String(localized: "activity.home.connect.friends.desc", comment: "Connect friends desc"),
                icon: "phone.fill",
                action: nil,
                priority: 5
            ))
            suggestions.append(PlaceSuggestion(
                title: String(localized: "activity.home.write.journal.title", comment: "Write journal"),
                description: String(localized: "activity.home.write.journal.desc", comment: "Write journal desc"),
                icon: "book.fill",
                action: nil,
                priority: 4
            ))
            suggestions.append(PlaceSuggestion(
                title: String(localized: "activity.home.relax.time.title", comment: "Relax time"),
                description: String(localized: "activity.home.relax.time.desc", comment: "Relax time desc"),
                icon: "sparkles",
                action: nil,
                priority: 3
            ))

        case .night:
            suggestions.append(PlaceSuggestion(
                title: "Uyku Rutini",
                description: String(localized: "activity.home.prepare.tomorrow.desc", comment: "Prepare tomorrow"),
                icon: "moon.fill",
                action: nil,
                priority: 5
            ))
        }

        // Always available
        suggestions.append(PlaceSuggestion(
            title: String(localized: "activity.cafe.read.book.title", comment: "Read book"),
            description: "Zihnini dinlendir",
            icon: "book.closed.fill",
            action: nil,
            priority: 2
        ))

        return suggestions
    }

    // MARK: - Work Suggestions

    private func getWorkSuggestions(time: PlaceTimeOfDay) -> [PlaceSuggestion] {
        var suggestions: [PlaceSuggestion] = []

        suggestions.append(PlaceSuggestion(
            title: String(localized: "activity.work.focus.mode.title", comment: "Focus mode"),
            description: String(localized: "activity.work.focus.mode.desc", comment: "Focus mode desc"),
            icon: "moon.circle.fill",
            action: nil,
            priority: 5
        ))

        suggestions.append(PlaceSuggestion(
            title: "Pomodoro Tekniği",
            description: "25 dakika odaklan, 5 dakika mola",
            icon: "timer",
            action: nil,
            priority: 4
        ))

        if time == .afternoon || time == .evening {
            suggestions.append(PlaceSuggestion(
                title: String(localized: "activity.work.hydrate.title", comment: "Hydrate"),
                description: "Hidrasyon çok önemli!",
                icon: "drop.fill",
                action: nil,
                priority: 3
            ))

            suggestions.append(PlaceSuggestion(
                title: "5 Dakika Mola",
                description: "Gözlerini dinlendir, ayağa kalk",
                icon: "figure.stand",
                action: nil,
                priority: 4
            ))
        }

        return suggestions
    }

    // MARK: - Gym Suggestions

    private func getGymSuggestions(time: PlaceTimeOfDay) -> [PlaceSuggestion] {
        return [
            PlaceSuggestion(
                title: "Bugünün Antrenmanı",
                description: "Planladığın harekete başla",
                icon: "figure.run",
                action: nil,
                priority: 5
            ),
            PlaceSuggestion(
                title: "Isınma Yap",
                description: "Sakatlıkları önle",
                icon: "flame.fill",
                action: nil,
                priority: 4
            ),
            PlaceSuggestion(
                title: String(localized: "activity.work.hydrate.title", comment: "Hydrate"),
                description: "Antrenman öncesi hidrasyon",
                icon: "drop.fill",
                action: nil,
                priority: 4
            ),
            PlaceSuggestion(
                title: "Protein Tüket",
                description: "Antrenman sonrası kas yapımı",
                icon: "bolt.fill",
                action: nil,
                priority: 3
            )
        ]
    }

    // MARK: - Cafe Suggestions

    private func getCafeSuggestions(time: PlaceTimeOfDay) -> [PlaceSuggestion] {
        return [
            PlaceSuggestion(
                title: "Yaratıcı Çalışma Zamanı",
                description: "Rahat ortamda üretken ol",
                icon: "lightbulb.fill",
                action: nil,
                priority: 5
            ),
            PlaceSuggestion(
                title: String(localized: "activity.home.write.journal.title", comment: "Write journal"),
                description: "Kahve eşliğinde düşüncelerini kaydet",
                icon: "book.fill",
                action: nil,
                priority: 4
            ),
            PlaceSuggestion(
                title: String(localized: "activity.cafe.read.book.title", comment: "Read book"),
                description: "Huzurlu bir okuma molası",
                icon: "book.closed.fill",
                action: nil,
                priority: 3
            ),
            PlaceSuggestion(
                title: "Arkadaşınla Sohbet",
                description: "Sosyal etkileşim zamanı",
                icon: "person.2.fill",
                action: nil,
                priority: 4
            )
        ]
    }

    // MARK: - Shopping Suggestions

    private func getShoppingSuggestions() -> [PlaceSuggestion] {
        return [
            PlaceSuggestion(
                title: "Alışveriş Listeni Kontrol Et",
                description: "Hiçbir şey unutma",
                icon: "list.bullet",
                action: nil,
                priority: 5
            ),
            PlaceSuggestion(
                title: "Bütçe Takibi",
                description: "Harcamalarını kaydet",
                icon: "dollarsign.circle.fill",
                action: nil,
                priority: 3
            )
        ]
    }

    // MARK: - Restaurant Suggestions

    private func getRestaurantSuggestions() -> [PlaceSuggestion] {
        return [
            PlaceSuggestion(
                title: "Yemeğin Tadını Çıkar",
                description: "Telefonu bırak, anın tadını çıkar",
                icon: "fork.knife",
                action: nil,
                priority: 5
            ),
            PlaceSuggestion(
                title: "Sosyal Etkileşim",
                description: "Arkadaşlarınla keyifli vakit geçir",
                icon: "person.2.fill",
                action: nil,
                priority: 4
            )
        ]
    }

    // MARK: - Park Suggestions

    private func getParkSuggestions(time: PlaceTimeOfDay) -> [PlaceSuggestion] {
        return [
            PlaceSuggestion(
                title: "Yürüyüş Yap",
                description: "Doğada 20 dakika yürü",
                icon: "figure.walk",
                action: nil,
                priority: 5
            ),
            PlaceSuggestion(
                title: "Meditasyon",
                description: "Zihnini sakinleştir",
                icon: "sparkles",
                action: nil,
                priority: 4
            ),
            PlaceSuggestion(
                title: "Fotoğraf Çek",
                description: "Güzel anları kaydet",
                icon: "camera.fill",
                action: nil,
                priority: 3
            )
        ]
    }

    // MARK: - School Suggestions

    private func getSchoolSuggestions() -> [PlaceSuggestion] {
        return [
            PlaceSuggestion(
                title: "Derse Odaklan",
                description: "Aktif dinleme yap",
                icon: "ear.fill",
                action: nil,
                priority: 5
            ),
            PlaceSuggestion(
                title: "Not Tut",
                description: "Önemli noktaları kaydet",
                icon: "pencil",
                action: nil,
                priority: 4
            )
        ]
    }

    // MARK: - Hospital Suggestions

    private func getHospitalSuggestions() -> [PlaceSuggestion] {
        return [
            PlaceSuggestion(
                title: "Sakin Kal",
                description: "Derin nefes al",
                icon: "heart.fill",
                action: nil,
                priority: 5
            ),
            PlaceSuggestion(
                title: "Randevu Bilgilerini Kontrol Et",
                description: "Doktor, saat, bölüm",
                icon: "list.clipboard.fill",
                action: nil,
                priority: 4
            )
        ]
    }

    // MARK: - Time-Based Suggestions

    private func getTimeSuggestions(time: PlaceTimeOfDay, placeCategory: PlaceCategory) -> [PlaceSuggestion] {
        var suggestions: [PlaceSuggestion] = []

        // Morning routine (everywhere except work)
        if time == .morning && placeCategory != .work {
            suggestions.append(PlaceSuggestion(
                title: "Günaydın! 🌅",
                description: "Yeni güne enerjik başla",
                icon: "sunrise.fill",
                action: nil,
                priority: 3
            ))
        }

        // Evening reflection
        if time == .evening && placeCategory == .home {
            suggestions.append(PlaceSuggestion(
                title: "Günü Değerlendir",
                description: "Bugün neler başardın?",
                icon: "checkmark.circle.fill",
                action: nil,
                priority: 4
            ))
        }

        return suggestions
    }

    // MARK: - Custom Suggestions

    private func getCustomSuggestions(for place: SavedPlace) -> [PlaceSuggestion] {
        // Bu kısım kullanıcı özel notlarına göre özelleştirilebilir
        // Örneğin: place.notes içinde anahtar kelimeler arayıp öneri üretmek

        return []
    }

    // MARK: - Helper

    func getCurrentPlaceTimeOfDay() -> PlaceTimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<22: return .evening
        default: return .night
        }
    }
}

// MARK: - Time of Day

enum PlaceTimeOfDay {
    case morning    // 5-12
    case afternoon  // 12-18
    case evening    // 18-22
    case night      // 22-5

    var displayName: String {
        switch self {
        case .morning: return "Sabah"
        case .afternoon: return "Öğleden Sonra"
        case .evening: return "Akşam"
        case .night: return "Gece"
        }
    }

    var emoji: String {
        switch self {
        case .morning: return "🌅"
        case .afternoon: return "☀️"
        case .evening: return "🌆"
        case .night: return "🌙"
        }
    }
}
