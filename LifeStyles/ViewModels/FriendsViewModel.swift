//
//  FriendsViewModel.swift
//  LifeStyles
//
//  Created by Claude on 16.10.2025.
//

import Foundation
import SwiftData
import Contacts

// MARK: - Sort Options

enum FriendSortOption: String, CaseIterable {
    case smart = "Akıllı"
    case name = "İsim"
    case lastContact = "Son İletişim"
    case nextContact = "Sonraki İletişim"
    case importance = "Önem"

    var icon: String {
        switch self {
        case .smart: return "brain.head.profile"
        case .name: return "textformat.abc"
        case .lastContact: return "clock.arrow.circlepath"
        case .nextContact: return "calendar"
        case .importance: return "star.fill"
        }
    }
}

@Observable
@MainActor
class FriendsViewModel {
    var friends: [Friend] = []
    var searchText: String = ""
    var showingAddFriend: Bool = false
    var selectedFriend: Friend?
    var selectedRelationshipType: RelationshipType? = nil // Filtre için
    var sortOption: FriendSortOption = .smart // Yeni: Sıralama seçeneği

    private var modelContext: ModelContext?

    // Filtrelenmiş arkadaşlar
    var filteredFriends: [Friend] {
        var result = friends

        // Relationship type filtreleme
        if let selectedType = selectedRelationshipType {
            result = result.filter { $0.relationshipType == selectedType }
        }

        // Arama filtreleme
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Akıllı sıralama
        return sortFriends(result, by: sortOption)
    }

    // MARK: - Smart Sorting

    private func sortFriends(_ friends: [Friend], by option: FriendSortOption) -> [Friend] {
        switch option {
        case .smart:
            return friends.sorted { calculatePriorityScore($0) > calculatePriorityScore($1) }

        case .name:
            return friends.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        case .lastContact:
            return friends.sorted {
                guard let date1 = $0.lastContactDate, let date2 = $1.lastContactDate else {
                    return $0.lastContactDate != nil
                }
                return date1 < date2
            }

        case .nextContact:
            return friends.sorted { $0.nextContactDate < $1.nextContactDate }

        case .importance:
            return friends.sorted {
                if $0.isImportant == $1.isImportant {
                    return $0.nextContactDate < $1.nextContactDate
                }
                return $0.isImportant && !$1.isImportant
            }
        }
    }

    private func calculatePriorityScore(_ friend: Friend) -> Int {
        var score = 0

        // Önemli arkadaş bonusu
        if friend.isImportant {
            score += 100
        }

        // Partner en üst
        if friend.relationshipType == .partner {
            score += 200
        }

        // Gecikme durumu (her geciken gün için 10 puan)
        if friend.needsContact {
            score += friend.daysOverdue * 10
        }

        // Yaklaşan tarih bonusu (3 günden az kalmışsa)
        if !friend.needsContact && friend.daysRemaining <= 3 {
            score += 20
        }

        // Frequency'e göre ağırlık
        switch friend.frequency {
        case .daily:
            score += 15
        case .twoDays:
            score += 12
        case .threeDays:
            score += 10
        case .weekly:
            score += 8
        case .biweekly:
            score += 6
        case .monthly:
            score += 4
        case .quarterly:
            score += 2
        case .yearly:
            score += 1
        }

        return score
    }

    // Relationship type'a göre arkadaşlar
    func friendsForType(_ type: RelationshipType) -> [Friend] {
        friends.filter { $0.relationshipType == type }
    }

    // Partner varsa getir
    var partner: Friend? {
        friends.first { $0.relationshipType == .partner }
    }

    // İletişim gerekenlerin sayısı
    var friendsNeedingAttention: Int {
        friends.filter { $0.needsContact }.count
    }

    // Yakında iletişim gerekenlerin sayısı (3 gün veya daha az)
    var friendsSoonCount: Int {
        friends.filter { !$0.needsContact && $0.daysRemaining <= 3 }.count
    }

    // Önemli arkadaşlar
    var importantFriends: [Friend] {
        friends.filter { $0.isImportant }
    }

    // ModelContext'i ayarla
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchFriends()
    }

    // Arkadaşları getir
    func fetchFriends() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Friend>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            friends = try context.fetch(descriptor)
        } catch {
            print("❌ Arkadaşlar getirilemedi: \(error)")
        }
    }

    // Yeni arkadaş ekle
    func addFriend(
        name: String,
        phoneNumber: String?,
        frequency: ContactFrequency,
        isImportant: Bool,
        notes: String?,
        avatarEmoji: String?,
        profileImageData: Data? = nil,
        relationshipType: RelationshipType = .friend,
        relationshipStartDate: Date? = nil,
        anniversaryDate: Date? = nil,
        loveLanguage: LoveLanguage? = nil,
        favoriteThings: String? = nil
    ) -> Bool {
        guard let context = modelContext else { return false }

        // Duplicate kontrolü
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPhone = phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines)

        // İsim kontrolü (case-insensitive)
        let nameExists = friends.contains { friend in
            friend.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedName.lowercased()
        }

        // Telefon numarası kontrolü (boş değilse)
        var phoneExists = false
        if let phone = normalizedPhone, !phone.isEmpty {
            phoneExists = friends.contains { friend in
                if let friendPhone = friend.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return friendPhone == phone
                }
                return false
            }
        }

        // Duplicate varsa ekleme
        if nameExists || phoneExists {
            print("❌ Duplicate arkadaş: \(nameExists ? "isim" : "telefon") zaten mevcut")
            return false
        }

        let friend = Friend(
            name: trimmedName,
            phoneNumber: normalizedPhone,
            frequency: frequency,
            lastContactDate: Date(), // İlk eklediğinde bugün iletişim kurulmuş sayılır
            isImportant: isImportant,
            notes: notes,
            avatarEmoji: avatarEmoji,
            profileImageData: profileImageData,
            relationshipType: relationshipType,
            relationshipStartDate: relationshipStartDate,
            anniversaryDate: anniversaryDate,
            loveLanguage: loveLanguage,
            favoriteThings: favoriteThings
        )

        context.insert(friend)

        do {
            try context.save()
            fetchFriends()
            print("✅ \(relationshipType.displayName) eklendi: \(trimmedName)")
            return true
        } catch {
            print("❌ Eklenemedi: \(error)")
            return false
        }
    }

    // Arkadaşı güncelle
    func updateFriend(_ friend: Friend, name: String, phoneNumber: String?, frequency: ContactFrequency, isImportant: Bool, notes: String?, avatarEmoji: String?) {
        friend.name = name
        friend.phoneNumber = phoneNumber
        friend.frequency = frequency
        friend.isImportant = isImportant
        friend.notes = notes
        friend.avatarEmoji = avatarEmoji

        do {
            try modelContext?.save()
            fetchFriends()
            print("✅ Arkadaş güncellendi: \(name)")
        } catch {
            print("❌ Arkadaş güncellenemedi: \(error)")
        }
    }

    // Arkadaşı sil
    func deleteFriend(_ friend: Friend) {
        guard let context = modelContext else { return }

        context.delete(friend)

        do {
            try context.save()
            fetchFriends()
            print("✅ Arkadaş silindi")
        } catch {
            print("❌ Arkadaş silinemedi: \(error)")
        }
    }

    // İletişim tamamlandı olarak işaretle
    func markAsContacted(_ friend: Friend) {
        friend.lastContactDate = Date()

        // Geçmişe kayıt ekle
        let history = ContactHistory(date: Date(), notes: nil, mood: nil)
        history.friend = friend
        modelContext?.insert(history)

        do {
            try modelContext?.save()
            fetchFriends()
            print("✅ İletişim kaydedildi: \(friend.name)")

            // Bildirim gönder
            NotificationService.shared.sendContactCompletedNotification(for: friend)
        } catch {
            print("❌ İletişim kaydedilemedi: \(error)")
        }
    }

    // Rehberden kişi seç
    func importFromContacts() async -> [CNContact] {
        let store = CNContactStore()

        // İzin kontrolü
        let status = CNContactStore.authorizationStatus(for: .contacts)
        guard status == .authorized else {
            print("❌ Rehber erişim izni yok")
            return []
        }

        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactThumbnailImageDataKey
        ] as [CNKeyDescriptor]

        do {
            let request = CNContactFetchRequest(keysToFetch: keys)
            var contacts: [CNContact] = []
            var count = 0
            let maxContacts = 500 // Memory overflow önlemek için sınır

            try store.enumerateContacts(with: request) { contact, stop in
                // Sadece telefon numarası olan kişileri al
                guard !contact.phoneNumbers.isEmpty else { return }

                contacts.append(contact)
                count += 1

                // Çok fazla contact yüklenmesini engelle
                if count >= maxContacts {
                    stop.pointee = true
                }
            }

            print("✅ \(contacts.count) kişi yüklendi")
            return contacts
        } catch {
            print("❌ Rehber okunamadı: \(error)")
            return []
        }
    }

    // Rehberdeki kişiyi ekle
    func addFriendFromPhoneBook(
        _ cnContact: CNContact,
        frequency: ContactFrequency,
        isImportant: Bool,
        relationshipType: RelationshipType = .friend,
        relationshipStartDate: Date? = nil,
        anniversaryDate: Date? = nil
    ) -> Bool {
        let name = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces)
        let phoneNumber = cnContact.phoneNumbers.first?.value.stringValue

        // Profil fotoğrafını al
        var profileImageData: Data?
        if cnContact.areKeysAvailable([CNContactImageDataKey as CNKeyDescriptor]),
           let imageData = cnContact.imageData {
            profileImageData = imageData
        } else if cnContact.areKeysAvailable([CNContactThumbnailImageDataKey as CNKeyDescriptor]),
                  let thumbnailData = cnContact.thumbnailImageData {
            profileImageData = thumbnailData
        }

        return addFriend(
            name: name,
            phoneNumber: phoneNumber,
            frequency: frequency,
            isImportant: isImportant,
            notes: nil,
            avatarEmoji: nil,
            profileImageData: profileImageData,
            relationshipType: relationshipType,
            relationshipStartDate: relationshipStartDate,
            anniversaryDate: anniversaryDate
        )
    }
}
