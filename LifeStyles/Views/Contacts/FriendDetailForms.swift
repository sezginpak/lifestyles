//
//  FriendDetailForms.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from FriendDetailView.swift - Add/Edit forms
//

import SwiftUI
import SwiftData

// MARK: - Data Models

struct FriendAchievement {
    let icon: String
    let title: String
    let color: Color
}

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: String
    let count: Int
}

struct MoodData: Identifiable {
    let id = UUID()
    let mood: String
    let count: Int
}

// MARK: - Add Contact History View (Kept from original)

struct AddContactHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let friend: Friend

    @State private var notes: String = ""
    @State private var selectedMood: ContactMood? = nil
    @State private var selectedDate: Date = Date()
    @State private var selectedChannel: ContactChannel? = nil
    @State private var selectedTags: [ContactTag] = []
    @State private var showingTagPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Tarih ve Saat") {
                    DatePicker("Tarih", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Görüşme Nasıl Geçti?") {
                    Picker("Ruh Hali", selection: $selectedMood) {
                        Text(String(localized: "common.not.selected", comment: "Not selected")).tag(nil as ContactMood?)
                        ForEach([ContactMood.great, .good, .okay, .notGreat], id: \.self) { mood in
                            HStack {
                                Text(mood.emoji)
                                Text(mood.displayName)
                            }
                            .tag(mood as ContactMood?)
                        }
                    }
                }

                Section("İletişim Kanalı") {
                    Picker("Kanal", selection: $selectedChannel) {
                        Text("Seçilmedi").tag(nil as ContactChannel?)
                        ForEach(ContactChannel.allCases, id: \.self) { channel in
                            Label {
                                Text(channel.displayName)
                            } icon: {
                                Image(systemName: channel.icon)
                            }
                            .tag(channel as ContactChannel?)
                        }
                    }
                    .pickerStyle(.menu)

                    if let channel = selectedChannel {
                        HStack {
                            Image(systemName: channel.icon)
                                .foregroundStyle(Color(channel.color))
                            Text(channel.displayName)
                                .font(.subheadline)
                        }
                    }
                }

                Section {
                    Button {
                        showingTagPicker.toggle()
                    } label: {
                        HStack {
                            Label("Etiketler", systemImage: "tag.fill")
                            Spacer()
                            if !selectedTags.isEmpty {
                                Text("\(selectedTags.count) seçili")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !selectedTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedTags) { tag in
                                    ContactTagChip(tag: tag, onRemove: {
                                        selectedTags.removeAll { $0.id == tag.id }
                                    })
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Notlar") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(String(localized: "friends.add.contact.history", comment: "Add Contact History"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
                        saveHistory()
                    }
                }
            }
            .sheet(isPresented: $showingTagPicker) {
                ContactTagPickerView(selectedTags: $selectedTags)
            }
        }
    }

    private func saveHistory() {
        let history = ContactHistory(
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes,
            mood: selectedMood,
            channel: selectedChannel
        )
        history.friend = friend
        history.tags = selectedTags.isEmpty ? nil : selectedTags

        modelContext.insert(history)

        if selectedDate > (friend.lastContactDate ?? Date.distantPast) {
            friend.lastContactDate = selectedDate
        }

        do {
            try modelContext.save()
            HapticFeedback.success()
            dismiss()
        } catch {
            print("❌ Geçmiş kaydedilemedi: \(error)")
        }
    }
}

// MARK: - Edit Friend View (Kept from original)

struct EditFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let friend: Friend

    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var selectedFrequency: ContactFrequency = .weekly
    @State private var isImportant: Bool = false
    @State private var avatarEmoji: String = ""

    // Relationship Type & Partner Properties
    @State private var relationshipType: RelationshipType = .friend
    @State private var relationshipStartDate: Date = Date()
    @State private var anniversaryDate: Date = Date()
    @State private var selectedLoveLanguage: LoveLanguage? = nil
    @State private var favoriteThings: String = ""

    // Ortak ilgi alanları ve aktiviteler
    @State private var sharedInterests: String = ""
    @State private var favoriteActivities: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Kişi Bilgileri") {
                    TextField("İsim", text: $name)
                    TextField("Telefon", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Avatar Emoji", text: $avatarEmoji)
                }

                Section("İlişki Tipi") {
                    Picker("Tip", selection: $relationshipType) {
                        ForEach(RelationshipType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.emoji)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Partner için özel bölümler
                if relationshipType == .partner {
                    Section("İlişki Bilgileri") {
                        DatePicker("İlişki Başlangıcı", selection: $relationshipStartDate, displayedComponents: .date)
                        DatePicker("Yıldönümü Tarihi", selection: $anniversaryDate, displayedComponents: .date)
                    }

                    Section("Sevgi Dili") {
                        Picker("Sevgi Dili", selection: $selectedLoveLanguage) {
                            Text(String(localized: "common.not.selected", comment: "Not selected")).tag(nil as LoveLanguage?)
                            ForEach(LoveLanguage.allCases, id: \.self) { language in
                                HStack {
                                    Text(language.emoji)
                                    VStack(alignment: .leading) {
                                        Text(language.displayName)
                                        Text(language.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(language as LoveLanguage?)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Section {
                        TextEditor(text: $favoriteThings)
                            .frame(height: 80)
                    } header: {
                        Text(String(localized: "friend.favorite.things", comment: "Favorite things"))
                    } footer: {
                        Text(String(localized: "friends.favorite.placeholder", comment: "Favorite items placeholder"))
                    }
                }

                // Ortak ilgi alanları ve aktiviteler (tüm ilişki tipleri için)
                Section {
                    TextField("Örn: Müzik, spor, seyahat", text: $sharedInterests)
                } header: {
                    Text(String(localized: "friend.shared.interests", comment: "Shared interests"))
                } footer: {
                    Text(String(localized: "friend.comma.separated", comment: "Separate with commas"))
                }

                Section {
                    TextEditor(text: $favoriteActivities)
                        .frame(height: 80)
                } header: {
                    Text(String(localized: "friends.favorite.activities", comment: "Favorite Activities"))
                } footer: {
                    Text(String(localized: "friend.activities.footer", comment: "Activities you do or want to do together (comma separated)"))
                }

                Section("İletişim Sıklığı") {
                    Picker("Sıklık", selection: $selectedFrequency) {
                        ForEach([ContactFrequency.daily, .twoDays, .threeDays, .weekly, .biweekly, .monthly], id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                }

                Section {
                    Toggle("Önemli Kişi", isOn: $isImportant)
                }
            }
            .navigationTitle(String(localized: "common.edit", comment: "Edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
                        saveFriend()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = friend.name
                phoneNumber = friend.phoneNumber ?? ""
                selectedFrequency = friend.frequency
                isImportant = friend.isImportant
                avatarEmoji = friend.avatarEmoji ?? ""

                // Relationship & Partner Properties
                relationshipType = friend.relationshipType
                relationshipStartDate = friend.relationshipStartDate ?? Date()
                anniversaryDate = friend.anniversaryDate ?? Date()
                selectedLoveLanguage = friend.loveLanguage
                favoriteThings = friend.favoriteThings ?? ""

                // Ortak ilgi alanları ve aktiviteler
                sharedInterests = friend.sharedInterests ?? ""
                favoriteActivities = friend.favoriteActivities ?? ""
            }
        }
    }

    private func saveFriend() {
        friend.name = name
        friend.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        friend.frequency = selectedFrequency
        friend.isImportant = isImportant
        friend.avatarEmoji = avatarEmoji.isEmpty ? nil : avatarEmoji

        // Relationship & Partner Properties
        friend.relationshipType = relationshipType
        if relationshipType == .partner {
            friend.relationshipStartDate = relationshipStartDate
            friend.anniversaryDate = anniversaryDate
            friend.loveLanguage = selectedLoveLanguage
            friend.favoriteThings = favoriteThings.isEmpty ? nil : favoriteThings
        } else {
            // Partner değilse partner özelliklerini temizle
            friend.relationshipStartDate = nil
            friend.anniversaryDate = nil
            friend.loveLanguage = nil
            friend.favoriteThings = nil
        }

        // Ortak ilgi alanları ve aktiviteler (tüm ilişki tipleri için)
        friend.sharedInterests = sharedInterests.isEmpty ? nil : sharedInterests
        friend.favoriteActivities = favoriteActivities.isEmpty ? nil : favoriteActivities

        do {
            try modelContext.save()
            HapticFeedback.success()
            dismiss()
        } catch {
            print("❌ Arkadaş güncellenemedi: \(error)")
        }
    }
}

