//
//  PatternMatcher.swift
//  LifeStyles
//
//  Created by AI Assistant on 04.11.2025.
//  AI öğrenen chat sistemi - Regex pattern matching
//

import Foundation

/// Konuşmalardan regex ile bilgi çıkaran servis
class PatternMatcher {
    static let shared = PatternMatcher()

    private init() {}

    // MARK: - Public Methods

    /// Mesajdan pattern matching ile bilgi çıkar
    func extract(from message: String) -> [ExtractedFact] {
        var facts: [ExtractedFact] = []

        // Normalize edilmiş mesaj (küçük harf)
        let normalized = message.lowercased()

        // 1. Kişisel Bilgiler
        facts.append(contentsOf: extractPersonalInfo(from: message, normalized: normalized))

        // 2. Tercihler
        facts.append(contentsOf: extractPreferences(from: message, normalized: normalized))

        // 3. Hedefler
        facts.append(contentsOf: extractGoals(from: message, normalized: normalized))

        // 4. Duygular ve Korkular
        facts.append(contentsOf: extractEmotions(from: message, normalized: normalized))

        // 5. İlişkiler
        facts.append(contentsOf: extractRelationships(from: message, normalized: normalized))

        // 6. Alışkanlıklar
        facts.append(contentsOf: extractHabits(from: message, normalized: normalized))

        // 7. Güncel Durum
        facts.append(contentsOf: extractCurrentSituation(from: message, normalized: normalized))

        return facts
    }

    // MARK: - Private Extraction Methods

    /// Kişisel bilgiler (meslek, yaş, konum, vb)
    private func extractPersonalInfo(from message: String, normalized: String) -> [ExtractedFact] {
        var facts: [ExtractedFact] = []

        // Meslek patterns (TR + EN)
        let jobPatterns = [
            "ben (bir |)([a-zığüşçö]+)(y)?ım": 2,           // "ben yazılımcıyım"
            "i am (a |an |)([a-z ]+)": 2,                   // "I am a developer"
            "mesleğim ([a-zığüşçö]+)": 1,                   // "mesleğim doktor"
            "my job is ([a-z ]+)": 1,                       // "my job is teacher"
            "([a-zığüşçö]+) olarak çalış": 1,               // "yazılımcı olarak çalışıyorum"
            "work as (a |an |)([a-z ]+)": 2                 // "work as a designer"
        ]

        for (pattern, groupIndex) in jobPatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                let job = cleanExtractedText(match)
                // Çok yaygın kelimeler değilse ekle
                if !isCommonWord(job) && job.count > 2 {
                    facts.append(ExtractedFact(
                        category: .personalInfo,
                        key: "job",
                        value: job,
                        confidence: 0.9,
                        source: .userTold
                    ))
                }
            }
        }

        // Yaş patterns
        let agePatterns = [
            "(\\d{2}) yaşındayım": 1,                       // "25 yaşındayım"
            "i am (\\d{2}) years old": 1,                   // "I am 25 years old"
            "yaşım (\\d{2})": 1                             // "yaşım 30"
        ]

        for (pattern, groupIndex) in agePatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex),
               let age = Int(match), age >= 10 && age <= 100 {
                facts.append(ExtractedFact(
                    category: .personalInfo,
                    key: "age",
                    value: "\(age)",
                    confidence: 0.95,
                    source: .userTold
                ))
            }
        }

        // Şehir patterns
        let cityPatterns = [
            "(istanbul|ankara|izmir|bursa|antalya|adana|konya)'?[a-z]*\\s+(yaşıyorum|oturuyorum)": 1,
            "live in ([a-z]+)": 1,
            "i'm from ([a-z]+)": 1
        ]

        for (pattern, groupIndex) in cityPatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                let city = cleanExtractedText(match).capitalized
                facts.append(ExtractedFact(
                    category: .personalInfo,
                    key: "city",
                    value: city,
                    confidence: 0.85,
                    source: .userTold
                ))
            }
        }

        return facts
    }

    /// Tercihler (sevdiği/sevmediği şeyler)
    private func extractPreferences(from message: String, normalized: String) -> [ExtractedFact] {
        var facts: [ExtractedFact] = []

        // Sevdiği şeyler
        let likePatterns = [
            "([a-zığüşçö ]+)\\s+(çok |)severim": 1,         // "kahve severim"
            "([a-zığüşçö ]+)\\s+(çok )(seviyorum|beğeniyorum)": 1,  // "müzik seviyorum"
            "i (love|like) ([a-z ]+)": 2                    // "I love coffee"
        ]

        for (pattern, groupIndex) in likePatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                let item = cleanExtractedText(match)
                if !isCommonWord(item) && item.count > 2 {
                    facts.append(ExtractedFact(
                        category: .preferences,
                        key: "likes_\(item)",
                        value: "likes",
                        confidence: 0.8,
                        source: .userTold
                    ))
                }
            }
        }

        // Sevmediği şeyler
        let dislikePatterns = [
            "([a-zığüşçö ]+)\\s+sevmem": 1,                 // "kahve sevmem"
            "([a-zığüşçö ]+)'?(den|dan)\\s+nefret": 1,      // "sigara'dan nefret ediyorum"
            "i (hate|dislike|don't like) ([a-z ]+)": 2      // "I hate coffee"
        ]

        for (pattern, groupIndex) in dislikePatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                let item = cleanExtractedText(match)
                if !isCommonWord(item) && item.count > 2 {
                    facts.append(ExtractedFact(
                        category: .preferences,
                        key: "dislikes_\(item)",
                        value: "dislikes",
                        confidence: 0.8,
                        source: .userTold
                    ))
                }
            }
        }

        return facts
    }

    /// Hedefler ve istekler
    private func extractGoals(from message: String, normalized: String) -> [ExtractedFact] {
        var facts: [ExtractedFact] = []

        let goalPatterns = [
            "([a-zığüşçö ]+)\\s+(istiyorum|isterim)": 1,     // "kilo vermek istiyorum"
            "([a-zığüşçö ]+)\\s+hedefliyorum": 1,            // "İngilizce öğrenmeyi hedefliyorum"
            "i want to ([a-z ]+)": 1,                        // "I want to lose weight"
            "my goal is ([a-z ]+)": 1,                       // "my goal is to travel"
            "hedefim ([a-zığüşçö ]+)": 1                     // "hedefim kilo vermek"
        ]

        for (pattern, groupIndex) in goalPatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                let goal = cleanExtractedText(match)
                if !isCommonWord(goal) && goal.count > 3 {
                    facts.append(ExtractedFact(
                        category: .goals,
                        key: "goal_\(goal)",
                        value: goal,
                        confidence: 0.85,
                        source: .userTold
                    ))
                }
            }
        }

        return facts
    }

    /// Duygular ve korkular
    private func extractEmotions(from message: String, normalized: String) -> [ExtractedFact] {
        var facts: [ExtractedFact] = []

        // Korku patterns
        let fearPatterns = [
            "([a-zığüşçö ]+)'?(den|dan)\\s+korkuyorum": 1,  // "yükseklikten korkuyorum"
            "i (am|)\\s*afraid of ([a-z ]+)": 2,             // "I'm afraid of heights"
            "([a-zığüşçö ]+)\\s+beni korkutuyor": 1          // "karanlık beni korkutuyor"
        ]

        for (pattern, groupIndex) in fearPatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                let fear = cleanExtractedText(match)
                if !isCommonWord(fear) && fear.count > 2 {
                    facts.append(ExtractedFact(
                        category: .fears,
                        key: "fear_\(fear)",
                        value: fear,
                        confidence: 0.85,
                        source: .userTold
                    ))
                }
            }
        }

        // Stres triggers
        let stressPatterns = [
            "([a-zığüşçö ]+)\\s+(beni |)stresliyor": 1,     // "işten stresleniyorum"
            "([a-z ]+)\\s+stresses me": 1                   // "work stresses me"
        ]

        for (pattern, groupIndex) in stressPatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                let trigger = cleanExtractedText(match)
                if !isCommonWord(trigger) && trigger.count > 2 {
                    facts.append(ExtractedFact(
                        category: .triggers,
                        key: "stress_trigger_\(trigger)",
                        value: "stress",
                        confidence: 0.8,
                        source: .userTold
                    ))
                }
            }
        }

        return facts
    }

    /// İlişkiler
    private func extractRelationships(from message: String, normalized: String) -> [ExtractedFact] {
        var facts: [ExtractedFact] = []

        // Partner/eş patterns
        let partnerPatterns = [
            "eşim|partneri?m|sevgilim": 0,                   // "eşim", "partnerim"
            "my (wife|husband|partner|girlfriend|boyfriend)": 0
        ]

        for (pattern, groupIndex) in partnerPatterns {
            if extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) != nil {
                facts.append(ExtractedFact(
                    category: .relationships,
                    key: "has_partner",
                    value: "true",
                    confidence: 0.9,
                    source: .inferred
                ))
                break  // Sadece bir kez ekle
            }
        }

        // Aile patterns
        let familyPatterns = [
            "(annem|babam|ablam|ağabeyim|kardeşim)": 1,
            "my (mom|dad|mother|father|sister|brother)": 1
        ]

        for (pattern, groupIndex) in familyPatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                facts.append(ExtractedFact(
                    category: .relationships,
                    key: "has_\(match)",
                    value: "true",
                    confidence: 0.85,
                    source: .inferred
                ))
            }
        }

        return facts
    }

    /// Alışkanlıklar
    private func extractHabits(from message: String, normalized: String) -> [ExtractedFact] {
        var facts: [ExtractedFact] = []

        let habitPatterns = [
            "her (gün|sabah|akşam) ([a-zığüşçö ]+)": 2,     // "her gün koşuyorum"
            "every (day|morning|night) i ([a-z ]+)": 2,      // "every day I exercise"
            "genellikle ([a-zığüşçö ]+)": 1,                 // "genellikle yürürüm"
            "usually ([a-z ]+)": 1                           // "usually walk"
        ]

        for (pattern, groupIndex) in habitPatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                let habit = cleanExtractedText(match)
                if !isCommonWord(habit) && habit.count > 2 {
                    facts.append(ExtractedFact(
                        category: .habits,
                        key: "habit_\(habit)",
                        value: habit,
                        confidence: 0.75,
                        source: .pattern
                    ))
                }
            }
        }

        return facts
    }

    /// Güncel durum
    private func extractCurrentSituation(from message: String, normalized: String) -> [ExtractedFact] {
        var facts: [ExtractedFact] = []

        // Zaman bazlı context
        let timePatterns = [
            "(bu hafta|bu ay|şu sıralar) ([a-zığüşçö ]+)": 2,  // "bu hafta çok yoğunum"
            "(currently|right now) i am ([a-z ]+)": 2           // "currently I am busy"
        ]

        for (pattern, groupIndex) in timePatterns {
            if let match = extractWithRegex(pattern, from: normalized, groupIndex: groupIndex) {
                let situation = cleanExtractedText(match)
                if !isCommonWord(situation) && situation.count > 2 {
                    facts.append(ExtractedFact(
                        category: .currentSituation,
                        key: "current_state",
                        value: situation,
                        confidence: 0.7,
                        source: .inferred
                    ))
                }
            }
        }

        return facts
    }

    // MARK: - Helper Methods

    /// Regex ile text çıkar
    private func extractWithRegex(_ pattern: String, from text: String, groupIndex: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        // Capture group çıkar
        if groupIndex >= match.numberOfRanges {
            return nil
        }

        let matchRange = match.range(at: groupIndex)
        guard matchRange.location != NSNotFound,
              let range = Range(matchRange, in: text) else {
            return nil
        }

        return String(text[range])
    }

    /// Çıkarılan metni temizle
    private func cleanExtractedText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
    }

    /// Çok yaygın kelime mi kontrol et (noise filtreleme)
    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = [
            "ben", "sen", "o", "biz", "siz", "onlar",
            "i", "you", "he", "she", "it", "we", "they",
            "bir", "ve", "ama", "için", "ile", "gibi",
            "a", "an", "the", "and", "but", "for", "with", "like",
            "çok", "az", "daha", "en", "this", "that", "these", "those",
            "şey", "thing", "stuff"
        ]

        return commonWords.contains(word.lowercased())
    }
}
