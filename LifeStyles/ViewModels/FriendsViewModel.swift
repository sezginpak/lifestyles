//
//  FriendsViewModel.swift
//  LifeStyles
//
//  Created by Claude on 16.10.2025.
//

import Foundation
import SwiftData
import Contacts

@Observable
class FriendsViewModel {
    var friends: [Friend] = []
    var searchText: String = ""
    var showingAddFriend: Bool = false
    var selectedFriend: Friend?
    var selectedRelationshipType: RelationshipType? = nil // Filtre için

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

        // Sıralama: önce iletişim gerekenleri, sonra tarihe göre
        return result.sorted { ($0.needsContact ? 0 : 1, $0.nextContactDate) < ($1.needsContact ? 0 : 1, $1.nextContactDate) }
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
    ) {
        guard let context = modelContext else { return }

        let friend = Friend(
            name: name,
            phoneNumber: phoneNumber,
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
            print("✅ \(relationshipType.displayName) eklendi: \(name)")
        } catch {
            print("❌ Eklenemedi: \(error)")
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
    ) {
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

        addFriend(
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
