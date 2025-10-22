//
//  FriendAIService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Observable
class FriendAIService {
    static let shared = FriendAIService()

    private var model: SystemLanguageModel

    private init() {
        // Varsayılan modeli kullan
        self.model = SystemLanguageModel.default
        checkModelAvailability()
    }

    /// Model kullanılabilirlik durumunu kontrol et
    func checkModelAvailability() {
        Task {
            do {
                let testSession = LanguageModelSession(
                    model: model,
                    instructions: { "Test" }
                )

                let testResponse = try await testSession.respond(to: "Hello")
                print("✅ Foundation Models AVAILABLE and WORKING!")
                print("✅ Test response: \(testResponse.content)")
            } catch let error as LanguageModelSession.GenerationError {
                print("❌ Foundation Models ERROR: \(error)")

                // Error türünü string olarak kontrol et
                let errorString = String(describing: error)

                if errorString.contains("assetsUnavailable") {
                    print("⚠️ MODEL NOT DOWNLOADED")
                    print("⚠️ Solution: Settings → Apple Intelligence & Siri → Download Model")
                } else if errorString.contains("rateLimited") {
                    print("⚠️ RATE LIMITED - Too many requests, wait a moment")
                } else if errorString.contains("serverUnavailable") {
                    print("⚠️ SERVER UNAVAILABLE - Check internet connection")
                } else {
                    print("⚠️ UNKNOWN ERROR: \(errorString)")
                }

                print("⚠️ Using fallback AI instead")
            } catch {
                print("❌ UNEXPECTED ERROR: \(error)")
                print("⚠️ Using fallback AI instead")
            }
        }
    }

    // MARK: - AI Öneri Oluşturma

    /// Arkadaş bilgilerine göre akıllı öneri oluşturur
    func generateSuggestion(for friend: Friend) async throws -> String {
        let session = createSession()

        let prompt = buildPrompt(for: friend)

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ AI öneri hatası: \(error)")
            // Fallback: Basit öneri
            return getFallbackSuggestion(for: friend)
        }
    }

    /// Mesaj taslağı oluşturur
    func generateMessageDraft(for friend: Friend, context: MessageContext = .general) async throws -> String {
        let session = createSession()

        let prompt = buildMessagePrompt(for: friend, context: context)

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("❌ Mesaj taslağı hatası: \(error)")
            return getFallbackMessage(for: friend, context: context)
        }
    }

    /// Akışlı öneri oluşturur (gerçek zamanlı)
    func streamSuggestion(for friend: Friend) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let session = createSession()
                let prompt = buildPrompt(for: friend)

                do {
                    let stream = try await session.streamResponse(to: prompt)

                    for try await partial in stream {
                        // Partial içeriği direkt yield et
                        continuation.yield(partial.content)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// İletişim geçmişinden insight çıkarır
    func analyzeRelationshipInsights(for friend: Friend) async throws -> RelationshipInsight {
        let session = createSession()

        let prompt = buildAnalysisPrompt(for: friend)

        do {
            // Yapılandırılmış çıktı istiyoruz
            let response = try await session.respond(
                to: prompt,
                generating: RelationshipInsight.self
            )
            return response.content
        } catch {
            print("❌ Insight analizi hatası: \(error)")
            return RelationshipInsight.default
        }
    }

    // MARK: - Prompt Oluşturma

    private func buildPrompt(for friend: Friend) -> String {
        var prompt = """
        Kullanıcının arkadaşı \(friend.name) hakkında kısa ve samimi bir öneri oluştur.

        Bilgiler:
        - İsim: \(friend.name)
        - İletişim sıklığı: \(friend.frequency.displayName)
        """

        if friend.needsContact {
            prompt += "\n- Durum: \(friend.daysOverdue) gündür iletişim kurulmamış (iletişim gerekiyor)"
        } else {
            prompt += "\n- Durum: Sonraki iletişime \(friend.daysRemaining) gün var"
        }

        if let lastContact = friend.lastContactDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "tr_TR")
            prompt += "\n- Son iletişim: \(formatter.string(from: lastContact))"
        }

        if friend.isImportant {
            prompt += "\n- Önemli bir arkadaş"
        }

        if let history = friend.contactHistory, !history.isEmpty {
            prompt += "\n- Toplam \(history.count) kez iletişim kurulmuş"

            let recentMoods = history.suffix(3).compactMap { $0.mood?.displayName }
            if !recentMoods.isEmpty {
                prompt += "\n- Son ruh halleri: \(recentMoods.joined(separator: ", "))"
            }
        }

        if let notes = friend.notes, !notes.isEmpty {
            prompt += "\n- Notlar: \(notes)"
        }

        prompt += """


        Lütfen Türkçe olarak, samimi ve motive edici bir öneri cümlesi yaz (maksimum 2 cümle).
        Kullanıcıya "sen" diye hitap et.
        """

        return prompt
    }

    private func buildMessagePrompt(for friend: Friend, context: MessageContext) -> String {
        var prompt = """
        \(friend.name) için \(context.rawValue) bir WhatsApp mesajı taslağı oluştur.

        Bilgiler:
        - İsim: \(friend.name)
        """

        if friend.needsContact {
            prompt += "\n- \(friend.daysOverdue) gündür görüşülmemiş"
        }

        if let lastContact = friend.lastContactDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "tr_TR")
            prompt += "\n- Son görüşme: \(formatter.string(from: lastContact))"
        }

        if let notes = friend.notes, !notes.isEmpty {
            prompt += "\n- Notlar: \(notes)"
        }

        prompt += """


        Lütfen Türkçe olarak, samimi ve doğal bir mesaj taslağı oluştur.
        Mesaj kısa, içten ve konuşma dilinde olsun (maksimum 3 cümle).
        Emojiler kullanabilirsin ama abartma.
        """

        return prompt
    }

    private func buildAnalysisPrompt(for friend: Friend) -> String {
        var prompt = """
        \(friend.name) ile olan ilişkiyi analiz et ve yapılandırılmış bir insight çıkar.

        Bilgiler:
        - Toplam iletişim: \(friend.totalContactCount)
        - İletişim sıklığı hedefi: \(friend.frequency.displayName)
        """

        if let history = friend.contactHistory, !history.isEmpty {
            let moods = history.compactMap { $0.mood }
            if !moods.isEmpty {
                let moodCounts = Dictionary(grouping: moods, by: { $0 })
                    .mapValues { $0.count }
                prompt += "\n- Ruh hali dağılımı: \(moodCounts)"
            }

            let notes = history.compactMap { $0.notes }.filter { !$0.isEmpty }
            if !notes.isEmpty {
                prompt += "\n- Son notlardan örnekler: \(notes.prefix(3).joined(separator: "; "))"
            }
        }

        prompt += """


        Lütfen JSON formatında şu alanları doldur:
        - summary: Kısa özet (1 cümle)
        - strength: İlişkinin güçlü yönü
        - suggestion: İyileştirme önerisi
        - mood: Genel ruh hali ("positive", "neutral", "needs_attention")
        """

        return prompt
    }

    // MARK: - Yardımcı Fonksiyonlar

    private func createSession() -> LanguageModelSession {
        // Session cache'i kaldırdık - her çağrıda yeni session oluştur
        // Böylece önceki conversation'lar karışmaz
        let newSession = LanguageModelSession(
            model: model,
            instructions: {
                """
                Türkçe cevap ver. İlişki koçu gibi davran.
                Kısa, net ve samimi ol.
                Gereksiz tekrar yapma.
                Maksimum 3-4 cümle kullan.
                """
            }
        )

        return newSession
    }

    private func getFallbackSuggestion(for friend: Friend) -> String {
        if friend.needsContact {
            return "\(friend.name) ile \(friend.daysOverdue) gündür görüşmediniz. Bir kahve molası için haber vermeye ne dersiniz?"
        } else if friend.isImportant {
            return "\(friend.name) ile ilişkiniz harika gidiyor! Önemli arkadaşlarınızla düzenli iletişim kuruyorsunuz."
        } else {
            return "\(friend.name) ile sonraki görüşmenize \(friend.daysRemaining) gün var. İyi gidiyorsunuz!"
        }
    }

    private func getFallbackMessage(for friend: Friend, context: MessageContext) -> String {
        switch context {
        case .general:
            return "Selam \(friend.name)! Nasılsın? Uzun zamandır görüşemedik, bir kahve içelim mi?"
        case .birthday:
            return "Doğum günün kutlu olsun \(friend.name)! 🎉 Keyifli ve güzel bir yıl dilerim!"
        case .checkIn:
            return "Merhaba \(friend.name), nasılsın? Uzun zamandır haberleşemedik, merak ettim."
        case .celebrate:
            return "Tebrikler \(friend.name)! Çok sevindim, kutlamak için buluşalım mı?"
        }
    }
}

// MARK: - Supporting Types

@available(iOS 26.0, *)
enum MessageContext: String {
    case general = "genel"
    case birthday = "doğum günü"
    case checkIn = "hal hatır sorma"
    case celebrate = "kutlama"
}

@available(iOS 26.0, *)
@Generable
struct RelationshipInsight: Codable {
    let summary: String
    let strength: String
    let suggestion: String
    let mood: String

    static var `default`: RelationshipInsight {
        RelationshipInsight(
            summary: "İlişkiniz dengeli görünüyor.",
            strength: "Düzenli iletişim",
            suggestion: "Mevcut tempoyu koruyun",
            mood: "neutral"
        )
    }
}

/// Mesaj taslağı için structured output
@available(iOS 26.0, *)
@Generable
struct MessageDraft: Codable {
    let greeting: String      // "Selam Ahmet!"
    let mainMessage: String   // "Nasılsın? Uzun zamandır görüşemedik."
    let closing: String       // "Müsait olduğunda buluşalım mı?"
    let tone: String          // "casual", "formal", "warm"

    var fullMessage: String {
        [greeting, mainMessage, closing]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static var `default`: MessageDraft {
        MessageDraft(
            greeting: "Merhaba!",
            mainMessage: "Nasılsın? Uzun zamandır görüşemedik.",
            closing: "Vakit bulduğunda bir kahve içelim mi?",
            tone: "casual"
        )
    }
}

/// İlişki önerileri için structured output
@available(iOS 26.0, *)
@Generable
struct RelationshipAdvice: Codable {
    let summary: String               // Kısa durum özeti
    let suggestions: [String]         // Öneriler listesi (max 3)
    let priority: String              // "urgent", "normal", "good"
    let nextSteps: String?            // Somut adımlar

    static var `default`: RelationshipAdvice {
        RelationshipAdvice(
            summary: "İlişkiniz dengeli gidiyor.",
            suggestions: [
                "Düzenli iletişimi sürdürün",
                "Ara sıra sürpriz yapın",
                "Ortak aktiviteler planlayın"
            ],
            priority: "normal",
            nextSteps: "Bu hafta bir kahve buluşması planlayabilirsiniz."
        )
    }
}

// MARK: - iOS 17 Fallback

/// iOS 17 için basit fallback servisi (Foundation Models olmadan)
@available(iOS 17.0, *)
@Observable
class FriendAIServiceFallback {
    static let shared = FriendAIServiceFallback()

    private init() {}

    func generateSuggestion(for friend: Friend) async -> String {
        // Basit rule-based öneriler
        if friend.needsContact {
            return "\(friend.name) ile \(friend.daysOverdue) gündür görüşmediniz. Bir kahve molası için haber vermeye ne dersiniz?"
        } else if friend.isImportant {
            return "\(friend.name) ile ilişkiniz harika gidiyor! Önemli arkadaşlarınızla düzenli iletişim kuruyorsunuz."
        } else {
            return "\(friend.name) ile sonraki görüşmenize \(friend.daysRemaining) gün var. İyi gidiyorsunuz!"
        }
    }

    func generateMessageDraft(for friend: Friend) async -> String {
        return "Selam \(friend.name)! Nasılsın? Uzun zamandır görüşemedik, bir kahve içelim mi?"
    }
}
