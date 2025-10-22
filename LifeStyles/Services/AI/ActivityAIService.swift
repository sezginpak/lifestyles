//
//  ActivityAIService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import FoundationModels
import CoreLocation

@available(iOS 26.0, *)
@Observable
class ActivityAIService {
    static let shared = ActivityAIService()

    private var model: SystemLanguageModel
    private var session: LanguageModelSession?
    private let languageManager = LanguageManager.shared

    private init() {
        self.model = SystemLanguageModel.default
    }

    // MARK: - Language Support

    private var currentLanguage: AppLanguage {
        languageManager.currentLanguage
    }

    // MARK: - AI Öneri Oluşturma

    /// Konum bazlı akıllı aktivite önerisi
    func generateActivityRecommendation(
        location: CLLocationCoordinate2D?,
        locationType: LocationType?,
        timeOfDay: Date = Date(),
        userGoals: [Goal] = [],
        recentActivities: [ActivitySuggestion] = []
    ) async throws -> ActivityRecommendation {
        let session = createSession()
        let prompt = buildActivityPrompt(
            location: location,
            locationType: locationType,
            timeOfDay: timeOfDay,
            userGoals: userGoals,
            recentActivities: recentActivities
        )

        do {
            let response = try await session.respond(
                to: prompt,
                generating: ActivityRecommendation.self
            )
            return response.content
        } catch {
            print("❌ Aktivite AI hatası: \(error)")
            return ActivityRecommendation.default(for: locationType ?? .other, timeOfDay: timeOfDay)
        }
    }

    /// Spesifik aktivite tipi için öneri
    func suggestActivity(type: ActivityType, context: String = "") async throws -> String {
        let session = createSession()

        let prompt = buildActivitySuggestionPrompt(type: type, context: context)

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Aktivite önerisi hatası: \(error)")
            return getFallbackActivity(for: type)
        }
    }

    private func buildActivitySuggestionPrompt(type: ActivityType, context: String) -> String {
        switch currentLanguage {
        case .turkish:
            var prompt = """
            \(type.displayName) kategorisinde kullanıcıya aktivite öner.
            """

            if !context.isEmpty {
                prompt += "\n\nBağlam: \(context)"
            }

            prompt += """


            Lütfen Türkçe olarak:
            - Kısa ve öz aktivite önerisi (1-2 cümle)
            - Neden faydalı olduğunu belirt
            - Pratik ve hemen yapılabilir olsun

            Maksimum 3 cümle.
            """
            return prompt

        case .english:
            var prompt = """
            Suggest an activity in the \(type.displayName) category to the user.
            """

            if !context.isEmpty {
                prompt += "\n\nContext: \(context)"
            }

            prompt += """


            Please provide in English:
            - Short and concise activity suggestion (1-2 sentences)
            - Explain why it's beneficial
            - Should be practical and immediately doable

            Maximum 3 sentences.
            """
            return prompt
        }
    }

    /// Çoklu aktivite önerileri (liste)
    func generateMultipleRecommendations(
        count: Int = 3,
        location: CLLocationCoordinate2D?,
        locationType: LocationType?,
        userGoals: [Goal] = []
    ) async throws -> [ActivityRecommendation] {
        let session = createSession()
        let prompt = buildMultipleActivitiesPrompt(
            count: count,
            location: location,
            locationType: locationType,
            userGoals: userGoals
        )

        do {
            // Her bir öneri için ayrı response al
            var recommendations: [ActivityRecommendation] = []

            for _ in 0..<count {
                let response = try await session.respond(
                    to: prompt,
                    generating: ActivityRecommendation.self
                )
                recommendations.append(response.content)
            }

            return recommendations
        } catch {
            print("❌ Çoklu aktivite hatası: \(error)")
            // Fallback: basit öneriler
            return [
                ActivityRecommendation.default(for: .home, timeOfDay: Date()),
                ActivityRecommendation.default(for: .work, timeOfDay: Date()),
                ActivityRecommendation.default(for: .other, timeOfDay: Date())
            ]
        }
    }

    /// Streaming aktivite önerisi
    func streamActivityRecommendation(
        location: CLLocationCoordinate2D?,
        locationType: LocationType?
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let session = createSession()
                let prompt = buildStreamingActivityPrompt(location: location, locationType: locationType)

                do {
                    let stream = try await session.streamResponse(to: prompt)

                    for try await partial in stream {
                        continuation.yield(partial.content)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Prompt Oluşturma

    private func buildActivityPrompt(
        location: CLLocationCoordinate2D?,
        locationType: LocationType?,
        timeOfDay: Date,
        userGoals: [Goal],
        recentActivities: [ActivitySuggestion]
    ) -> String {
        let hour = Calendar.current.component(.hour, from: timeOfDay)
        let timeContext = getTimeContext(hour: hour)

        var prompt = """
        Kullanıcıya kişiselleştirilmiş aktivite önerisi oluştur.

        Bağlam:
        - Zaman: \(timeContext)
        """

        if let locationType = locationType {
            let locationName = locationType == .home ? "Evde" : locationType == .work ? "İşte" : "Dışarıda"
            prompt += "\n- Konum: \(locationName)"
        }

        if !userGoals.isEmpty {
            let goals = userGoals.prefix(3).map { "\($0.category.displayName): \($0.title)" }.joined(separator: ", ")
            prompt += "\n- Kullanıcının hedefleri: \(goals)"
        }

        if !recentActivities.isEmpty {
            let recent = recentActivities.prefix(3).map { $0.title }.joined(separator: ", ")
            prompt += "\n- Son aktiviteler: \(recent)"
        }

        prompt += """


        Lütfen JSON formatında şu alanları doldur:
        - activity: Aktivite adı (kısa ve çekici)
        - reason: Neden bu aktivite öneriliyor (1 cümle)
        - location: Nerede yapılacak (örn: "Yakındaki park", "Evde", "Kafede")
        - estimatedDuration: Tahmini süre (örn: "30 dakika", "1 saat")
        - difficulty: Zorluk seviyesi ("kolay", "orta", "zor")
        - category: Aktivite kategorisi ("outdoor", "exercise", "social", "learning", "creative", "relax")

        Türkçe, pratik ve motive edici ol.
        """

        return prompt
    }

    private func buildMultipleActivitiesPrompt(
        count: Int,
        location: CLLocationCoordinate2D?,
        locationType: LocationType?,
        userGoals: [Goal]
    ) -> String {
        var prompt = """
        Kullanıcıya \(count) farklı aktivite önerisi sun. Her biri farklı kategoride olsun.

        Bağlam:
        """

        if let locationType = locationType {
            let locationName = locationType == .home ? "Evde" : locationType == .work ? "İşte" : "Dışarıda"
            prompt += "\n- Konum: \(locationName)"
        }

        if !userGoals.isEmpty {
            let goals = userGoals.prefix(3).map { $0.title }.joined(separator: ", ")
            prompt += "\n- Hedefler: \(goals)"
        }

        prompt += """


        Farklı kategorilerde (outdoor, exercise, social, learning, creative, relax) çeşitli öneriler sun.
        Her biri pratik, yapılabilir ve motive edici olmalı.
        """

        return prompt
    }

    private func buildStreamingActivityPrompt(
        location: CLLocationCoordinate2D?,
        locationType: LocationType?
    ) -> String {
        let locationName = locationType == .home ? "evde" : locationType == .work ? "işte" : "dışarıda"

        return """
        Kullanıcı şu anda \(locationName). Detaylı aktivite önerisi sun.

        Lütfen Türkçe olarak:
        1. Mevcut duruma uygun aktivite öner
        2. Neden faydalı olduğunu açıkla
        3. Nasıl başlanacağını anlat

        Samimi ve motive edici ol.
        """
    }

    // MARK: - Yardımcı Fonksiyonlar

    private func createSession() -> LanguageModelSession {
        if let existingSession = session {
            return existingSession
        }

        let newSession = LanguageModelSession(
            model: model,
            instructions: {
                """
                Sen kullanıcının aktif ve sağlıklı yaşamasına yardımcı olan bir yaşam koçusun.
                Her zaman Türkçe yanıt ver.
                Konum, zaman ve kullanıcı hedeflerine göre kişiselleştirilmiş aktivite önerileri sun.
                Pratik, uygulanabilir ve motive edici tavsiyeler ver.
                Kullanıcıya "sen" diye hitap et.
                """
            }
        )

        self.session = newSession
        return newSession
    }

    private func getTimeContext(hour: Int) -> String {
        switch hour {
        case 5..<12:
            return "Sabah (saat \(hour):00)"
        case 12..<17:
            return "Öğleden sonra (saat \(hour):00)"
        case 17..<21:
            return "Akşam (saat \(hour):00)"
        default:
            return "Gece (saat \(hour):00)"
        }
    }

    private func getFallbackActivity(for type: ActivityType) -> String {
        switch type {
        case .outdoor:
            return "30 dakika yürüyüş yap. Temiz hava ve doğa zihinsel berraklık sağlar. Yakındaki parkı keşfet!"
        case .exercise:
            return "15 dakika yoga veya stretching yap. Vücudunu uyandırır ve esneklik kazandırır. Evde kolayca yapabilirsin."
        case .social:
            return "Bir arkadaşını ara veya kahve içmeye çağır. Sosyal bağlar mutluluk ve sağlık için kritik."
        case .learning:
            return "İlgilendiğin bir konuda 20 dakika okuma yap. Sürekli öğrenme zihni genç tutar."
        case .creative:
            return "Bir şeyler yaz, çiz veya müzik dinle. Yaratıcılık ruh sağlığı için harikadır."
        case .relax:
            return "10 dakika meditasyon veya derin nefes egzersizi yap. Stresi azaltır ve odaklanmayı artırır."
        }
    }
}

// MARK: - Supporting Types

@available(iOS 26.0, *)
@Generable
struct ActivityRecommendation: Codable {
    let activity: String
    let reason: String
    let location: String
    let estimatedDuration: String
    let difficulty: String
    let category: String

    static func `default`(for locationType: LocationType, timeOfDay: Date) -> ActivityRecommendation {
        let hour = Calendar.current.component(.hour, from: timeOfDay)

        switch locationType {
        case .home:
            if hour < 12 {
                return ActivityRecommendation(
                    activity: "Sabah yoga ve meditasyon",
                    reason: "Günü enerjik ve odaklı başlamak için mükemmel",
                    location: "Evde, sessiz bir odada",
                    estimatedDuration: "20 dakika",
                    difficulty: "kolay",
                    category: "exercise"
                )
            } else {
                return ActivityRecommendation(
                    activity: "Yaratıcı hobi zamanı",
                    reason: "Zihinsel rahatlama ve yaratıcılık geliştirme",
                    location: "Evde, rahat bir köşede",
                    estimatedDuration: "30 dakika",
                    difficulty: "kolay",
                    category: "creative"
                )
            }

        case .work:
            return ActivityRecommendation(
                activity: "Kısa yürüyüş molası",
                reason: "Zihin berraklığı ve odaklanma için gerekli",
                location: "Ofis çevresinde veya bina içinde",
                estimatedDuration: "10 dakika",
                difficulty: "kolay",
                category: "outdoor"
            )

        case .other:
            return ActivityRecommendation(
                activity: "Keşif yürüyüşü",
                reason: "Yeni yerler keşfet, hem egzersiz hem de zihinsel tazelenme",
                location: "Yakındaki park veya sokaklar",
                estimatedDuration: "30 dakika",
                difficulty: "kolay",
                category: "outdoor"
            )
        }
    }
}
