//
//  HabitAIService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Observable
class HabitAIService {
    static let shared = HabitAIService()

    private var model: SystemLanguageModel
    private var session: LanguageModelSession?

    private init() {
        self.model = SystemLanguageModel.default
    }

    // MARK: - AI Öneri Oluşturma

    /// Alışkanlık için detaylı insight oluşturur
    func generateInsight(for habit: Habit) async throws -> HabitInsight {
        let session = createSession()
        let prompt = buildInsightPrompt(for: habit)

        do {
            let response = try await session.respond(
                to: prompt,
                generating: HabitInsight.self
            )
            return response.content
        } catch {
            print("❌ Habit AI hatası: \(error)")
            return HabitInsight.default(for: habit)
        }
    }

    /// Yeni alışkanlık önerisi
    func suggestHabit(category: String = "", userGoals: [Goal] = []) async throws -> String {
        let session = createSession()

        var prompt = """
        Kullanıcıya etkili bir alışkanlık öner.
        """

        if !category.isEmpty {
            prompt += "\nKategori: \(category)"
        }

        if !userGoals.isEmpty {
            let goals = userGoals.map { "\($0.category.displayName): \($0.title)" }.joined(separator: ", ")
            prompt += "\nKullanıcının mevcut hedefleri: \(goals)"
        }

        prompt += """


        Lütfen Türkçe olarak:
        1. Uygulanabilir bir alışkanlık öner
        2. Neden faydalı olduğunu açıkla (1 cümle)
        3. Başlama için pratik ipucu ver

        Maksimum 3 cümle, kısa ve net.
        """

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Alışkanlık önerisi hatası: \(error)")
            return "Her sabah 10 dakika meditasyon yap. Zihinsel berraklık sağlar ve günün stresini azaltır. Başlamak için basit nefes egzersizleriyle başla."
        }
    }

    /// Seri motivasyon mesajı
    func generateStreakMotivation(for habit: Habit) async throws -> String {
        let session = createSession()
        let prompt = buildStreakPrompt(for: habit)

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Seri motivasyonu hatası: \(error)")
            return getFallbackStreakMotivation(for: habit)
        }
    }

    /// Trigger-Reward analizi
    func analyzeTriggerReward(for habit: Habit, recentCompletions: [HabitCompletion]) async throws -> String {
        let session = createSession()

        var prompt = """
        \(habit.name) alışkanlığı için trigger (tetikleyici) ve reward (ödül) analizi yap.

        Alışkanlık: \(habit.name)
        Sıklık: \(habit.frequency == .daily ? "Günlük" : habit.frequency == .weekly ? "Haftalık" : "Aylık")
        Mevcut seri: \(habit.currentStreak) gün
        """

        if !recentCompletions.isEmpty {
            prompt += "\nSon \(recentCompletions.count) tamamlama kaydedildi"
        }

        prompt += """


        Lütfen Türkçe olarak:
        1. Etkili bir tetikleyici (trigger) öner
        2. Ödüllendirme sistemi (reward) öner
        3. Alışkanlığı sürdürülebilir kılmak için ipucu ver

        Kısa ve uygulanabilir tavsiyeler ver (maksimum 4 cümle).
        """

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Trigger-Reward analizi hatası: \(error)")
            return "Tetikleyici olarak sabah kahveni kullan - kahve içerken hemen sonra \(habit.name) yap. Ödül olarak her tamamlamada kendine bir ✓ koy ve 7 günde bir küçük bir şey ısmarlat. Alışkanlık zincirine bakınca gurur duyacaksın!"
        }
    }

    /// Streaming motivasyon
    func streamMotivation(for habit: Habit) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let session = createSession()
                let prompt = buildStreamingPrompt(for: habit)

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

    private func buildInsightPrompt(for habit: Habit) -> String {
        var prompt = """
        Kullanıcının alışkanlığı hakkında detaylı analiz yap ve yapılandırılmış insight oluştur.

        Alışkanlık Bilgileri:
        - İsim: \(habit.name)
        - Sıklık: \(habit.frequency == .daily ? "Günlük" : habit.frequency == .weekly ? "Haftalık" : "Aylık")
        - Mevcut seri: \(habit.currentStreak) gün 🔥
        - En uzun seri: \(habit.longestStreak) gün
        """

        if !habit.habitDescription.isEmpty {
            prompt += "\n- Açıklama: \(habit.habitDescription)"
        }

        let completedToday = habit.isCompletedToday()
        if completedToday {
            prompt += "\n- Bugün tamamlandı ✅"
        } else {
            prompt += "\n- Bugün henüz tamamlanmadı ⏳"
        }

        if habit.currentStreak > 0 {
            prompt += "\n- Seri devam ediyor! 💪"
        }

        prompt += """


        Lütfen JSON formatında şu alanları doldur:
        - suggestion: Alışkanlığı güçlendirmek için öneri (1-2 cümle)
        - trigger: Etkili bir tetikleyici (trigger) önerisi
        - reward: Ödüllendirme sistemi önerisi
        - encouragement: Motive edici mesaj (1-2 cümle, samimi ve destekleyici)

        Her şey Türkçe olmalı ve kullanıcıya "sen" diye hitap et.
        """

        return prompt
    }

    private func buildStreakPrompt(for habit: Habit) -> String {
        var prompt = """
        \(habit.name) alışkanlığı için seri motivasyon mesajı oluştur.

        Mevcut seri: \(habit.currentStreak) gün
        En uzun seri: \(habit.longestStreak) gün
        """

        if habit.currentStreak == 0 {
            prompt += "\nSeri kırıldı, kullanıcıyı yeniden başlamaya motive et."
        } else if habit.currentStreak >= habit.longestStreak {
            prompt += "\nKullanıcı rekor kırıyor!"
        } else if habit.currentStreak >= 7 {
            prompt += "\nHarika bir seri! Kullanıcıyı kutla."
        }

        prompt += """


        Lütfen Türkçe olarak samimi ve motive edici bir mesaj yaz.
        Kullanıcıya "sen" diye hitap et. Maksimum 3 cümle.
        Emojiler kullanabilirsin ama abartma.
        """

        return prompt
    }

    private func buildStreamingPrompt(for habit: Habit) -> String {
        """
        \(habit.name) alışkanlığı için detaylı motivasyon ve rehberlik sun.

        Seri: \(habit.currentStreak) gün
        Bugün tamamlandı mı: \(habit.isCompletedToday() ? "Evet" : "Hayır")

        Lütfen Türkçe olarak:
        1. Mevcut durumu değerlendir
        2. Seri koruma stratejileri sun
        3. Pozitif motivasyon mesajı ver

        Destekleyici ve pratik ol.
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
                Sen kullanıcının alışkanlıklarını geliştirmesine yardımcı olan bir yaşam koçusun.
                Her zaman Türkçe yanıt ver.
                Alışkanlık psikolojisini iyi bilirsin (Atomic Habits, Tiny Habits prensipleri).
                Trigger-Reward döngüsünü kullan.
                Destekleyici, pozitif ve pratik tavsiyeler ver.
                Kullanıcıya "sen" diye hitap et.
                """
            }
        )

        self.session = newSession
        return newSession
    }

    private func getFallbackStreakMotivation(for habit: Habit) -> String {
        if habit.currentStreak == 0 {
            return "Seri kırıldı ama sorun değil! \(habit.name) için yeniden başlamak hiç zor değil. Bugün tekrar başla! 💪"
        } else if habit.currentStreak >= habit.longestStreak && habit.longestStreak > 0 {
            return "🎉 Rekor! \(habit.name) için \(habit.currentStreak) günlük yeni rekor kırdın! Devam et, imkansız yok!"
        } else if habit.currentStreak >= 21 {
            return "🔥 \(habit.currentStreak) gün! \(habit.name) artık bir alışkanlık haline geldi. Süper iş!"
        } else if habit.currentStreak >= 7 {
            return "⭐️ 1 hafta tamamlandı! \(habit.name) serinde \(habit.currentStreak) güne ulaştın. Devam et!"
        } else {
            return "\(habit.name) için \(habit.currentStreak) günlük seri! Her gün biraz daha güçleniyorsun. 💪"
        }
    }
}

// MARK: - Supporting Types

@available(iOS 26.0, *)
@Generable
struct HabitInsight: Codable {
    let suggestion: String
    let trigger: String
    let reward: String
    let encouragement: String

    static func `default`(for habit: Habit) -> HabitInsight {
        let suggestion: String
        let encouragement: String

        if habit.currentStreak == 0 {
            suggestion = "Küçük adımlarla başla. \(habit.name) için önce 2 dakikalık versiyonunu dene."
            encouragement = "Seri kırıldı ama sorun değil! Bugün yeniden başlamak için mükemmel bir gün. Sen yaparsın! 💪"
        } else if habit.currentStreak >= 21 {
            suggestion = "Alışkanlık yerleşmiş! Şimdi kaliteyi artırmaya odaklan."
            encouragement = "\(habit.currentStreak) gün! Artık bu senin yaşam tarzının bir parçası. Harikasın! 🌟"
        } else {
            suggestion = "Seriyi korumak için aynı saatte yapmayı dene. Tutarlılık anahtar!"
            encouragement = "\(habit.currentStreak) günlük serin harika! Devam et, momentum var. 🔥"
        }

        return HabitInsight(
            suggestion: suggestion,
            trigger: "Sabah rutininde sabit bir anı tetikleyici olarak kullan (örn: kahve içtikten sonra)",
            reward: "Her tamamlamada takvimde işaretle, 7 günde bir kendine küçük bir ödül ver",
            encouragement: encouragement
        )
    }
}
