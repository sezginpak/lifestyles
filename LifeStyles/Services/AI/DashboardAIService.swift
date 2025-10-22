//
//  DashboardAIService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Observable
class DashboardAIService {
    static let shared = DashboardAIService()

    private var model: SystemLanguageModel
    private var session: LanguageModelSession?

    private init() {
        self.model = SystemLanguageModel.default
    }

    // MARK: - AI Günlük Özet

    /// Günlük kapsamlı insight oluşturur
    func generateDailyInsight(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend],
        recentLocations: [LocationLog],
        recentActivities: [ActivitySuggestion]
    ) async throws -> DailyInsight {
        let session = createSession()
        let prompt = buildDailyInsightPrompt(
            goals: goals,
            habits: habits,
            friends: friends,
            recentLocations: recentLocations,
            recentActivities: recentActivities
        )

        do {
            let response = try await session.respond(
                to: prompt,
                generating: DailyInsight.self
            )
            return response.content
        } catch {
            print("❌ Günlük insight hatası: \(error)")
            return DailyInsight.default()
        }
    }

    /// Haftalık özet
    func generateWeeklySummary(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend],
        completedActivities: [ActivitySuggestion]
    ) async throws -> String {
        let session = createSession()
        let prompt = buildWeeklySummaryPrompt(
            goals: goals,
            habits: habits,
            friends: friends,
            completedActivities: completedActivities
        )

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Haftalık özet hatası: \(error)")
            return "Bu hafta güzel ilerleme kaydettiniz! Hedeflerinize doğru adım adım ilerliyorsunuz. 💪"
        }
    }

    /// Motivasyon mesajı (sabah için)
    func generateMorningMotivation(
        todayGoals: [Goal],
        todayHabits: [Habit]
    ) async throws -> String {
        let session = createSession()

        var prompt = """
        Kullanıcıya güne motive başlaması için sabah mesajı oluştur.
        """

        if !todayGoals.isEmpty {
            let goalTitles = todayGoals.map { $0.title }.joined(separator: ", ")
            prompt += "\n\nBugünün hedefleri: \(goalTitles)"
        }

        if !todayHabits.isEmpty {
            let habitNames = todayHabits.map { $0.name }.joined(separator: ", ")
            prompt += "\nBugün tamamlanacak alışkanlıklar: \(habitNames)"
        }

        prompt += """


        Lütfen Türkçe olarak kısa, enerjik ve motive edici bir sabah mesajı yaz.
        Kullanıcıya "sen" diye hitap et. Maksimum 3 cümle.
        Pozitif ve ilham verici ol.
        """

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Sabah motivasyonu hatası: \(error)")
            return "Günaydın! Bugün yeni bir gün, yeni fırsatlar. Hedeflerine bir adım daha yaklaşmak için mükemmel bir gün! 🌅"
        }
    }

    /// Akşam değerlendirmesi
    func generateEveningReflection(
        completedGoals: [Goal],
        completedHabits: [Habit],
        contactedFriends: [Friend]
    ) async throws -> String {
        let session = createSession()

        var prompt = """
        Kullanıcının gününü değerlendiren akşam mesajı oluştur.

        Bugünkü başarılar:
        """

        if !completedGoals.isEmpty {
            prompt += "\n- \(completedGoals.count) hedefte ilerleme kaydedildi"
        }

        if !completedHabits.isEmpty {
            prompt += "\n- \(completedHabits.count) alışkanlık tamamlandı"
        }

        if !contactedFriends.isEmpty {
            prompt += "\n- \(contactedFriends.count) arkadaşla iletişim kuruldu"
        }

        if completedGoals.isEmpty && completedHabits.isEmpty && contactedFriends.isEmpty {
            prompt += "\n- Bugün fazla aktivite kaydedilmedi"
        }

        prompt += """


        Lütfen Türkçe olarak:
        - Günü olumlu değerlendir
        - Yarın için kısa motivasyon ver
        - Destekleyici ve sıcak bir ton kullan

        Maksimum 3 cümle.
        """

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Akşam değerlendirmesi hatası: \(error)")
            return "Bugün de geride kaldı. Küçük adımlar büyük yolculuklar yapar. Yarın yeni fırsatlar seni bekliyor! 🌙"
        }
    }

    /// Streaming günlük analiz
    func streamDailyAnalysis(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let session = createSession()
                let prompt = buildStreamingDailyPrompt(goals: goals, habits: habits, friends: friends)

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

    private func buildDailyInsightPrompt(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend],
        recentLocations: [LocationLog],
        recentActivities: [ActivitySuggestion]
    ) -> String {
        var prompt = """
        Kullanıcının günlük durumunu analiz et ve kapsamlı bir coach mesajı oluştur.

        # Mevcut Durum:
        """

        // Goals analizi
        if !goals.isEmpty {
            let activeGoals = goals.filter { !$0.isCompleted }
            let overdueGoals = goals.filter { $0.isOverdue }
            let nearDeadline = goals.filter { $0.daysRemaining <= 7 && !$0.isCompleted }

            prompt += "\n\n## Hedefler:"
            prompt += "\n- Toplam: \(goals.count) hedef"
            prompt += "\n- Aktif: \(activeGoals.count)"

            if !overdueGoals.isEmpty {
                prompt += "\n- ⚠️ Gecikmiş: \(overdueGoals.count)"
            }

            if !nearDeadline.isEmpty {
                prompt += "\n- 🔥 Son 7 gün içinde: \(nearDeadline.count)"
            }

            if let topGoal = activeGoals.max(by: { $0.progress < $1.progress }) {
                prompt += "\n- En ilerlemiş: \(topGoal.title) (%\(topGoal.progressPercentage))"
            }
        }

        // Habits analizi
        if !habits.isEmpty {
            let activeHabits = habits.filter { $0.isActive }
            let completedToday = habits.filter { $0.isCompletedToday() }
            let streakHabits = habits.filter { $0.currentStreak > 0 }

            prompt += "\n\n## Alışkanlıklar:"
            prompt += "\n- Toplam: \(habits.count) alışkanlık"
            prompt += "\n- Aktif: \(activeHabits.count)"

            if !completedToday.isEmpty {
                prompt += "\n- ✅ Bugün tamamlanan: \(completedToday.count)"
            }

            if let bestStreak = streakHabits.max(by: { $0.currentStreak < $1.currentStreak }) {
                prompt += "\n- 🔥 En iyi seri: \(bestStreak.name) (\(bestStreak.currentStreak) gün)"
            }
        }

        // Friends analizi
        if !friends.isEmpty {
            let needsContact = friends.filter { $0.needsContact }
            let important = friends.filter { $0.isImportant }

            prompt += "\n\n## Arkadaşlar:"
            prompt += "\n- Toplam: \(friends.count) arkadaş"

            if !needsContact.isEmpty {
                prompt += "\n- 📞 İletişim gerekli: \(needsContact.count)"
            }

            if !important.isEmpty {
                prompt += "\n- ⭐️ Önemli: \(important.count)"
            }
        }

        // Location analizi
        if !recentLocations.isEmpty {
            let homeTime = recentLocations.filter { $0.locationType == .home }.reduce(0) { $0 + $1.durationInMinutes }
            prompt += "\n\n## Konum:"
            prompt += "\n- Evde geçirilen süre: ~\(homeTime) dakika"
        }

        // Activities analizi
        if !recentActivities.isEmpty {
            let completed = recentActivities.filter { $0.isCompleted }
            prompt += "\n\n## Aktiviteler:"
            prompt += "\n- Önerilen: \(recentActivities.count)"
            prompt += "\n- Tamamlanan: \(completed.count)"
        }

        prompt += """


        Lütfen JSON formatında şu alanları ULTRA KISA doldur:
        - summary: TEK cümle, maksimum 60 karakter (Örn: "3 hedef tamamlandı, harika gidiyorsun!")
        - topPriority: 3-4 kelime, emoji kullan (Örn: "Spora odaklan")
        - motivationMessage: 4-6 kelime, motive edici (Örn: "Enerjik görünüyorsun!")
        - suggestions: Tek satır, 3 madde bullet formatında her biri 2-3 kelime (Örn: "• Spor yap • Kitap oku • Arkadaş ara")
        - mood: Genel durum ("excellent", "good", "needs_attention", "challenging")

        ÖNEMLİ: Metinler ÇOK KISA olmalı! Her karakter değerli. Emoji kullan. Türkçe ol.
        """

        return prompt
    }

    private func buildWeeklySummaryPrompt(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend],
        completedActivities: [ActivitySuggestion]
    ) -> String {
        var prompt = """
        Kullanıcının haftalık performansını özetle.

        Bu hafta:
        - \(goals.filter { $0.progress > 0 }.count) hedefte ilerleme
        - \(habits.filter { $0.currentStreak >= 7 }.count) alışkanlık 7+ gün seri
        - \(completedActivities.count) aktivite tamamlandı
        - \(friends.filter { !$0.needsContact }.count)/\(friends.count) arkadaşla düzenli iletişim

        Lütfen Türkçe olarak:
        - Haftayı olumlu değerlendir
        - Başarıları kutla
        - Gelecek hafta için motivasyon ver

        Maksimum 5 cümle, destekleyici ve ilham verici ol.
        """

        return prompt
    }

    private func buildStreamingDailyPrompt(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend]
    ) -> String {
        """
        Kullanıcının günlük durumunu detaylı analiz et.

        Hedefler: \(goals.count)
        Alışkanlıklar: \(habits.count)
        Arkadaşlar: \(friends.count)

        Lütfen Türkçe olarak:
        1. Mevcut durumu değerlendir
        2. Güçlü yönleri vurgula
        3. İyileştirme önerileri sun
        4. Motivasyon mesajı ver

        Destekleyici bir coach gibi konuş.
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
                Sen kullanıcının kişisel yaşam koçusun.
                Her zaman Türkçe yanıt ver.
                Holistic yaklaşım: hedefler, alışkanlıklar, sosyal ilişkiler, aktiviteler - hepsini dengele.
                Veri odaklı ama empatik ol.
                Pratik, uygulanabilir tavsiyeler ver.
                Kullanıcıya "sen" diye hitap et.
                Destekleyici, pozitif ve ilham verici ol.
                """
            }
        )

        self.session = newSession
        return newSession
    }
}

// MARK: - Supporting Types

@available(iOS 26.0, *)
@Generable
struct DailyInsight: Codable, Equatable {
    let summary: String
    let topPriority: String
    let motivationMessage: String
    let suggestions: String
    let mood: String

    static func `default`() -> DailyInsight {
        DailyInsight(
            summary: "Yeni bir gün, yeni fırsatlar seni bekliyor!",
            topPriority: "Hedefine odaklan",
            motivationMessage: "Harika gidiyorsun!",
            suggestions: "• Sabah rutini • Arkadaş ara • Hedefte ilerle",
            mood: "good"
        )
    }
}
