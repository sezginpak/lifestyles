//
//  PhoneBookPickerView.swift
//  LifeStyles
//
//  Created by Claude on 16.10.2025.
//

import SwiftUI
import Contacts

struct PhoneBookPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: FriendsViewModel

    @State private var phoneContacts: [CNContact] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var selectedContact: ContactWrapper?

    // CNContact Identifiable yapmak için wrapper
    struct ContactWrapper: Identifiable {
        let id: String
        let contact: CNContact

        init(contact: CNContact) {
            self.id = contact.identifier
            self.contact = contact
        }
    }

    var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return phoneContacts
        } else {
            return phoneContacts.filter { contact in
                let fullName = "\(contact.givenName) \(contact.familyName)"
                return fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(String(localized: "contacts.loading", comment: "Loading contacts..."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if phoneContacts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)

                        Text(String(localized: "contacts.empty.title", comment: "Contacts empty"))
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(String(localized: "contacts.empty.message", comment: "No contacts found in your address book."))
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(filteredContacts, id: \.identifier) { contact in
                        PhoneContactRow(contact: contact)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedContact = ContactWrapper(contact: contact)
                            }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(String(localized: "contacts.select.from.phone", comment: "Select from Contacts"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Kişi Ara")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadContacts()
            }
            .sheet(item: $selectedContact) { wrapper in
                AddContactFromPhoneBookView(
                    contact: wrapper.contact,
                    viewModel: viewModel,
                    onComplete: {
                        dismiss()
                    }
                )
            }
        }
    }

    private func loadContacts() async {
        isLoading = true
        
        // Rehber izni kontrolü
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .notDetermined:
            // İzin iste
            let store = CNContactStore()
            do {
                let granted = try await store.requestAccess(for: .contacts)
                if granted {
                    phoneContacts = await viewModel.importFromContacts()
                } else {
                    phoneContacts = []
                }
            } catch {
                print("❌ İzin isteği başarısız: \(error)")
                phoneContacts = []
            }
        case .authorized:
            phoneContacts = await viewModel.importFromContacts()
        case .denied, .restricted:
            phoneContacts = []
            print("❌ Rehber erişimi reddedildi")
        @unknown default:
            phoneContacts = []
        }
        
        isLoading = false
    }
}

// MARK: - Rehber Kişi Satırı

struct PhoneContactRow: View {
    let contact: CNContact

    var fullName: String {
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "İsimsiz Kişi" : name
    }

    var phoneNumber: String? {
        contact.phoneNumbers.first?.value.stringValue
    }

    private var contactImage: UIImage? {
        // Güvenli şekilde thumbnail veriye erişim
        guard contact.areKeysAvailable([CNContactThumbnailImageDataKey as CNKeyDescriptor]),
              let imageData = contact.thumbnailImageData,
              !imageData.isEmpty else {
            return nil
        }
        return UIImage(data: imageData)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)

                if let uiImage = contactImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    let initial = contact.givenName.isEmpty ? "?" : String(contact.givenName.prefix(1)).uppercased()
                    Text(initial)
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(fullName)
                    .font(.headline)

                if let phone = phoneNumber {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Rehber Kişisini Ekle View

struct AddContactFromPhoneBookView: View {
    @Environment(\.dismiss) private var dismiss
    let contact: CNContact
    let viewModel: FriendsViewModel
    let onComplete: () -> Void

    @State private var selectedFrequency: ContactFrequency = .weekly
    @State private var isImportant: Bool = false
    @State private var notes: String = ""

    // Relationship Type & Partner Properties
    @State private var relationshipType: RelationshipType = .friend
    @State private var relationshipStartDate: Date = Date()
    @State private var anniversaryDate: Date = Date()

    var fullName: String {
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "İsimsiz Kişi" : name
    }

    var phoneNumber: String? {
        contact.phoneNumbers.first?.value.stringValue
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kişi Bilgileri") {
                    HStack {
                        Text(String(localized: "common.name", comment: "Name"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(fullName)
                            .fontWeight(.medium)
                    }

                    if let phone = phoneNumber {
                        HStack {
                            Text("Telefon")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(phone)
                                .fontWeight(.medium)
                        }
                    }
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

                // Partner için özel bölüm
                if relationshipType == .partner {
                    Section {
                        DatePicker("İlişki Başlangıcı", selection: $relationshipStartDate, displayedComponents: .date)
                        DatePicker("Yıldönümü Tarihi", selection: $anniversaryDate, displayedComponents: .date)
                    } header: {
                        Text("Partner Bilgileri")
                    } footer: {
                        Text(String(localized: "friend.partner.details.footer", comment: "You can add love language and other details later"))
                    }
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
                } footer: {
                    Text(String(localized: "friend.important.footer", comment: "Important people are shown with priority in widget"))
                }

                Section("Notlar (Opsiyonel)") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle(String(localized: "contacts.add.contact", comment: "Add Contact"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ekle") {
                        viewModel.addFriendFromPhoneBook(
                            contact,
                            frequency: selectedFrequency,
                            isImportant: isImportant,
                            relationshipType: relationshipType,
                            relationshipStartDate: relationshipType == .partner ? relationshipStartDate : nil,
                            anniversaryDate: relationshipType == .partner ? anniversaryDate : nil
                        )

                        // Notları manuel ekle
                        if !notes.isEmpty, let addedFriend = viewModel.friends.first(where: {
                            $0.name == fullName
                        }) {
                            addedFriend.notes = notes
                        }

                        HapticFeedback.success()
                        onComplete()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    PhoneBookPickerView(viewModel: FriendsViewModel())
}
