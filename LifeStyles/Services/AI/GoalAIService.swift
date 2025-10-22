//
//  GoalAIService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Observable
class GoalAIService {
    static let shared = GoalAIService()

    private var model: SystemLanguageModel
    private var session: LanguageModelSession?

    private init() {
        self.model = SystemLanguageModel.default
    }

    // MARK: - AI Öneri Oluşturma

    /// Hedef için akıllı insight oluşturur
    func generateInsight(for goal: Goal) async throws -> GoalInsight {
        let session = createSession()
        let prompt = buildInsightPrompt(for: goal)

        do {
            let response = try await session.respond(
                to: prompt,
                generating: GoalInsight.self
            )
            return response.content
        } catch {
            print("❌ Goal AI hatası: \(error)")
            return GoalInsight.default(for: goal)
        }
    }

    /// Hedef önerisi oluşturur (kategori bazlı)
    func suggestGoal(category: GoalCategory, userContext: String = "") async throws -> String {
        let session = createSession()

        var prompt = """
        \(category.displayName) kategorisinde kullanıcıya bir hedef öner.
        """

        if !userContext.isEmpty {
            prompt += "\n\nKullanıcı bağlamı: \(userContext)"
        }

        prompt += """


        Lütfen Türkçe olarak, SMART (Specific, Measurable, Achievable, Relevant, Time-bound) kriterine uygun,
        kısa ve net bir hedef önerisi yaz (maksimum 2 cümle).
        """

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Hedef önerisi hatası: \(error)")
            return getFallbackGoalSuggestion(for: category)
        }
    }

    /// Motivasyon mesajı oluşturur
    func generateMotivation(for goal: Goal) async throws -> String {
        let session = createSession()
        let prompt = buildMotivationPrompt(for: goal)

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Motivasyon mesajı hatası: \(error)")
            return getFallbackMotivation(for: goal)
        }
    }

    /// Streaming insight (gerçek zamanlı)
    func streamInsight(for goal: Goal) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let session = createSession()
                let prompt = buildStreamingPrompt(for: goal)

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

    private func buildInsightPrompt(for goal: Goal) -> String {
        var prompt = """
        Kullanıcının hedefi hakkında detaylı analiz yap ve yapılandırılmış insight oluştur.

        Hedef Bilgileri:
        - Başlık: \(goal.title)
        - Kategori: \(goal.category.displayName) \(goal.category.emoji)
        - İlerleme: %\(goal.progressPercentage)
        """

        if !goal.goalDescription.isEmpty {
            prompt += "\n- Açıklama: \(goal.goalDescription)"
        }

        if goal.isOverdue {
            let overdueBy = abs(goal.daysRemaining)
            prompt += "\n- Durum: Hedef \(overdueBy) gün gecikmiş ⚠️"
        } else if goal.daysRemaining <= 7 {
            prompt += "\n- Durum: Sadece \(goal.daysRemaining) gün kaldı! ⏰"
        } else {
            prompt += "\n- Durum: \(goal.daysRemaining) gün kaldı"
        }

        if goal.isCompleted {
            prompt += "\n- Tamamlandı ✅"
        }

        prompt += """


        Lütfen JSON formatında şu alanları doldur:
        - summary: Hedef hakkında kısa özet (1 cümle)
        - strategy: Hedefe ulaşmak için somut strateji (2-3 adım)
        - motivation: Motive edici mesaj (1-2 cümle, samimi)
        - nextSteps: Öncelikli sonraki adımlar (liste halinde, 2-3 madde)
        - urgency: Aciliyet seviyesi ("low", "medium", "high", "overdue")

        Her şey Türkçe olmalı ve kullanıcıya "sen" diye hitap et.
        """

        return prompt
    }

    private func buildMotivationPrompt(for goal: Goal) -> String {
        var prompt = """
        \(goal.title) hedefi için motive edici bir mesaj oluştur.

        - Kategori: \(goal.category.displayName)
        - İlerleme: %\(goal.progressPercentage)
        - Kalan süre: \(goal.daysRemaining) gün
        """

        if goal.isOverdue {
            prompt += "\n- Hedef gecikmiş, ancak hala tamamlanabilir!"
        }

        prompt += """


        Lütfen Türkçe olarak, samimi ve güçlü bir motivasyon mesajı yaz.
        Kullanıcıya "sen" diye hitap et. Maksimum 3 cümle.
        Pozitif ve ilham verici ol.
        """

        return prompt
    }

    private func buildStreamingPrompt(for goal: Goal) -> String {
        """
        \(goal.title) hedefi için detaylı analiz ve rehberlik sun.

        İlerleme: %\(goal.progressPercentage)
        Kalan süre: \(goal.daysRemaining) gün

        Lütfen Türkçe olarak:
        1. Mevcut durumu değerlendir
        2. Somut aksiyon önerileri sun
        3. Motivasyon mesajı ekle

        Samimi ve destekleyici bir ton kullan.
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
                Sen kullanıcının hedeflerine ulaşmasına yardımcı olan bir yaşam koçusun.
                Her zaman Türkçe yanıt ver.
                Motive edici, destekleyici ve pratik tavsiyelerde bulun.
                SMART hedef kriterlerini kullan.
                Kullanıcıya "sen" diye hitap et.
                """
            }
        )

        self.session = newSession
        return newSession
    }

    private func getFallbackGoalSuggestion(for category: GoalCategory) -> String {
        switch category {
        case .health:
            return "Her gün 10.000 adım at ve düzenli uyku düzeni oluştur."
        case .social:
            return "Haftada en az 3 arkadaşınla yüz yüze görüş ve yeni insanlarla tanış."
        case .career:
            return "Alanında bir sertifika programını tamamla ve portföyünü güçlendir."
        case .personal:
            return "Her gün 30 dakika okuma yap ve yeni bir beceri öğren."
        case .fitness:
            return "Haftada 4 gün spor yap ve dengeli beslen."
        case .other:
            return "Kendine bir hedef belirle ve onu küçük adımlara böl."
        }
    }

    private func getFallbackMotivation(for goal: Goal) -> String {
        if goal.isOverdue {
            return "Her şey için bir zaman var. \(goal.title) hedefini tamamlamak için asla geç değil. Bugün küçük bir adım at!"
        } else if goal.progressPercentage >= 75 {
            return "Harikasın! \(goal.title) hedefinde %\(goal.progressPercentage) ilerleme kaydettiniz. Son hamle için hadi!"
        } else if goal.daysRemaining <= 7 {
            return "\(goal.daysRemaining) gün kaldı! \(goal.title) için şimdi tam zamanı. Sen yaparsın!"
        } else {
            return "\(goal.title) için adım adım ilerliyorsun. Devam et, başarı yakın!"
        }
    }
}

// MARK: - Supporting Types

@available(iOS 26.0, *)
@Generable
struct GoalInsight: Codable {
    let summary: String
    let strategy: String
    let motivation: String
    let nextSteps: String
    let urgency: String

    static func `default`(for goal: Goal) -> GoalInsight {
        let urgency: String
        if goal.isOverdue {
            urgency = "overdue"
        } else if goal.daysRemaining <= 7 {
            urgency = "high"
        } else if goal.daysRemaining <= 30 {
            urgency = "medium"
        } else {
            urgency = "low"
        }

        return GoalInsight(
            summary: "\(goal.title) hedefinde %\(goal.progressPercentage) ilerleme kaydedildi.",
            strategy: "Hedefini küçük adımlara böl ve her gün biraz ilerleme kaydet.",
            motivation: "Her gün bir adım seni hedefe yaklaştırıyor. Devam et!",
            nextSteps: "• Bugün için somut bir görev belirle\n• İlerlemeyi kaydet\n• Kendini ödüllendir",
            urgency: urgency
        )
    }
}
