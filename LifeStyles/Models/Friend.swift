//
//  Friend.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//  Refactored on 21.10.2025 - Core models only
//

import Foundation
import SwiftData

@Model
final class Friend {
    var id: UUID
    var name: String
    var phoneNumber: String?
    var frequencyRaw: String
    var lastContactDate: Date?
    var isImportant: Bool
    var notes: String?
    var createdAt: Date
    var avatarEmoji: String? // Özel emoji avatar
    var profileImageData: Data? // Rehberden alınan profil fotoğrafı

    // İlişki Tipi
    var relationshipTypeRaw: String

    // Sevgili için özel alanlar
    var relationshipStartDate: Date? // İlişki başlangıç tarihi
    var anniversaryDate: Date? // Yıldönümü tarihi
    var loveLanguageRaw: String? // Sevgi dili
    var favoriteThings: String? // Favori şeyler (yemek, film, vb.)
    var partnerNotesRaw: String? // Partner notları (JSON string)

    // Ortak ilgi alanları ve aktiviteler (tüm ilişki tipleri için)
    var sharedInterests: String? // Ortak ilgi alanları (müzik, spor, vb.)
    var favoriteActivities: String? // Birlikte yapılan favori aktiviteler

    // İlişkiler
    @Relationship(deleteRule: .cascade, inverse: \ContactHistory.friend)
    var contactHistory: [ContactHistory]?

    @Relationship(deleteRule: .cascade, inverse: \SpecialDate.friend)
    var specialDates: [SpecialDate]?

    @Relationship(deleteRule: .nullify)
    var memories: [Memory]?

    @Relationship(deleteRule: .cascade, inverse: \Transaction.friend)
    var transactions: [Transaction]?

    var frequency: ContactFrequency {
        get { ContactFrequency(rawValue: frequencyRaw) ?? .weekly }
        set { frequencyRaw = newValue.rawValue }
    }

    var relationshipType: RelationshipType {
        get { RelationshipType(rawValue: relationshipTypeRaw) ?? .friend }
        set { relationshipTypeRaw = newValue.rawValue }
    }

    var loveLanguage: LoveLanguage? {
        get {
            guard let raw = loveLanguageRaw else { return nil }
            return LoveLanguage(rawValue: raw)
        }
        set { loveLanguageRaw = newValue?.rawValue }
    }

    var partnerNotes: [PartnerNote] {
        get {
            guard let raw = partnerNotesRaw, let data = raw.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([PartnerNote].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let string = String(data: data, encoding: .utf8) else {
                partnerNotesRaw = nil
                return
            }
            partnerNotesRaw = string
        }
    }

    // Sevgili için computed properties
    var isPartner: Bool {
        return relationshipType == .partner
    }

    // İlişki süresi (gün)
    var relationshipDays: Int? {
        guard let startDate = relationshipStartDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: Date()).day
    }

    // İlişki süresi (yıl, ay, gün formatında)
    var relationshipDuration: (years: Int, months: Int, days: Int)? {
        guard let startDate = relationshipStartDate else { return nil }
        let components = Calendar.current.dateComponents([.year, .month, .day], from: startDate, to: Date())
        return (components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    // Sonraki yıldönümüne kalan gün
    var daysUntilAnniversary: Int? {
        guard let anniversary = anniversaryDate else { return nil }

        let calendar = Calendar.current
        let today = Date()

        // Bu yılki yıldönümü tarihini hesapla
        var components = calendar.dateComponents([.month, .day], from: anniversary)
        components.year = calendar.component(.year, from: today)

        guard var thisYearAnniversary = calendar.date(from: components) else { return nil }

        // Eğer bu yılki yıldönümü geçtiyse, gelecek yılki tarihi hesapla
        if thisYearAnniversary < today {
            thisYearAnniversary = calendar.date(byAdding: .year, value: 1, to: thisYearAnniversary) ?? thisYearAnniversary
        }

        return calendar.dateComponents([.day], from: today, to: thisYearAnniversary).day
    }

    // Sonraki iletişim tarihi
    var nextContactDate: Date {
        guard let lastDate = lastContactDate else {
            return Date()
        }
        return Calendar.current.date(byAdding: .day, value: frequency.days, to: lastDate) ?? Date()
    }

    // Gecikme günü
    var daysOverdue: Int {
        let today = Date()
        let next = nextContactDate
        if today > next {
            return Calendar.current.dateComponents([.day], from: next, to: today).day ?? 0
        }
        return 0
    }

    // Kalan gün
    var daysRemaining: Int {
        let today = Date()
        let next = nextContactDate
        if next > today {
            return Calendar.current.dateComponents([.day], from: today, to: next).day ?? 0
        }
        return 0
    }

    // İletişim gerekli mi?
    var needsContact: Bool {
        return nextContactDate <= Date()
    }

    // Toplam iletişim sayısı
    var totalContactCount: Int {
        return (contactHistory?.count ?? 0) + (lastContactDate != nil ? 1 : 0)
    }

    // MARK: - Transaction Computed Properties

    // Toplam borç (Ben onlara borçluyum)
    var totalDebt: Decimal {
        guard let transactions = transactions else { return 0 }
        return transactions
            .filter { $0.transactionType == .debt && !$0.isPaid }
            .reduce(0) { $0 + $1.remainingAmount }
    }

    // Toplam alacak (Onlar bana borçlu)
    var totalCredit: Decimal {
        guard let transactions = transactions else { return 0 }
        return transactions
            .filter { $0.transactionType == .credit && !$0.isPaid }
            .reduce(0) { $0 + $1.remainingAmount }
    }

    // Net durum (+ alacak, - borç)
    var balance: Decimal {
        return totalCredit - totalDebt
    }

    // Formatted balance
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TL"
        formatter.locale = Locale(identifier: "tr_TR")

        if balance > 0 {
            return "+ \(formatter.string(from: balance as NSDecimalNumber) ?? "₺\(balance)")"
        } else if balance < 0 {
            return "- \(formatter.string(from: abs(balance) as NSDecimalNumber) ?? "₺\(abs(balance))")"
        } else {
            return "Dengede"
        }
    }

    // Ödenmemiş borç/alacak var mı?
    var hasOutstandingTransactions: Bool {
        guard let transactions = transactions, !transactions.isEmpty else { return false }
        return totalDebt > 0 || totalCredit > 0
    }

    // Gecikmiş transaction'lar
    var overdueTransactions: [Transaction] {
        guard let transactions = transactions else { return [] }
        return transactions.filter { $0.isOverdue }
    }

    // Yaklaşan vadeler (7 gün içinde)
    var upcomingDueTransactions: [Transaction] {
        guard let transactions = transactions else { return [] }
        return transactions.filter { transaction in
            guard let days = transaction.daysUntilDue, !transaction.isPaid else { return false }
            return days >= 0 && days <= 7
        }
    }

    // Son transaction'lar (son 5)
    var recentTransactions: [Transaction] {
        guard let transactions = transactions else { return [] }
        return Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }

    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String? = nil,
        frequency: ContactFrequency = .weekly,
        lastContactDate: Date? = nil,
        isImportant: Bool = false,
        notes: String? = nil,
        avatarEmoji: String? = nil,
        profileImageData: Data? = nil,
        createdAt: Date = Date(),
        relationshipType: RelationshipType = .friend,
        relationshipStartDate: Date? = nil,
        anniversaryDate: Date? = nil,
        loveLanguage: LoveLanguage? = nil,
        favoriteThings: String? = nil,
        sharedInterests: String? = nil,
        favoriteActivities: String? = nil
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.frequencyRaw = frequency.rawValue
        self.lastContactDate = lastContactDate
        self.isImportant = isImportant
        self.notes = notes
        self.avatarEmoji = avatarEmoji
        self.profileImageData = profileImageData
        self.createdAt = createdAt
        self.relationshipTypeRaw = relationshipType.rawValue
        self.relationshipStartDate = relationshipStartDate
        self.anniversaryDate = anniversaryDate
        self.loveLanguageRaw = loveLanguage?.rawValue
        self.favoriteThings = favoriteThings
        self.sharedInterests = sharedInterests
        self.favoriteActivities = favoriteActivities
    }
}

// MARK: - Special Date Model

@Model
final class SpecialDate {
    var id: UUID
    var title: String
    var date: Date
    var emoji: String?
    var notes: String?
    var createdAt: Date

    @Relationship
    var friend: Friend?

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        emoji: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.emoji = emoji
        self.notes = notes
        self.createdAt = createdAt
    }

    // Tarihe kalan gün
    var daysUntil: Int {
        let calendar = Calendar.current
        let today = Date()

        // Bu yılki özel günü hesapla
        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = calendar.component(.year, from: today)

        guard var thisYearDate = calendar.date(from: components) else { return 0 }

        // Eğer bu yılki tarih geçtiyse, gelecek yılki tarihi hesapla
        if thisYearDate < today {
            thisYearDate = calendar.date(byAdding: .year, value: 1, to: thisYearDate) ?? thisYearDate
        }

        return calendar.dateComponents([.day], from: today, to: thisYearDate).day ?? 0
    }

    // Geçmiş mi?
    var isPast: Bool {
        return daysUntil < 0
    }

    // Yaklaşıyor mu? (30 gün içinde)
    var isUpcoming: Bool {
        return daysUntil >= 0 && daysUntil <= 30
    }
}

// MARK: - İletişim Geçmişi Modeli

@Model
final class ContactHistory {
    var id: UUID
    var date: Date
    var notes: String?
    var mood: ContactMood? // Görüşme nasıl geçti?

    @Relationship
    var friend: Friend?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        notes: String? = nil,
        mood: ContactMood? = nil
    ) {
        self.id = id
        self.date = date
        self.notes = notes
        self.mood = mood
    }
}

enum ContactMood: String, Codable {
    case great = "great"
    case good = "good"
    case okay = "okay"
    case notGreat = "notGreat"

    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .notGreat: return "😕"
        }
    }

    var displayName: String {
        switch self {
        case .great: return String(localized: "contact.mood.great", comment: "Great mood")
        case .good: return String(localized: "contact.mood.good", comment: "Good mood")
        case .okay: return String(localized: "contact.mood.okay", comment: "Okay mood")
        case .notGreat: return String(localized: "contact.mood.notGreat", comment: "Not great mood")
        }
    }
}
