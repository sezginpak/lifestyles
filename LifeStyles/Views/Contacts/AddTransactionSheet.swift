//
//  AddTransactionSheet.swift
//  LifeStyles
//
//  Created by Claude on 27.10.2025.
//  Borç/Alacak Ekleme Formu - Kompakt Tasarım
//

import SwiftUI
import SwiftData

struct AddTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let friend: Friend

    @State private var amount: String = ""
    @State private var transactionDescription: String = ""
    @State private var transactionType: TransactionType = .debt
    @State private var currency: String = "TL"
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var hasDueDate: Bool = true
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let currencies = ["TL", "USD", "EUR"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header - Kompakt
                    headerSection

                    // Transaction Type Picker - Kompakt
                    transactionTypePicker

                    // Amount + Currency - Birleştirildi
                    amountAndCurrencySection

                    // Description - Kompakt
                    descriptionSection

                    // Due Date - Kompakt
                    dueDateSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "nav.yeni.işlem"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.save", comment: "Save button")) {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                    .disabled(amount.isEmpty || transactionDescription.isEmpty)
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button(String(localized: "button.tamam"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Section (Kompakt + Fotoğraf)

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Profil Fotoğrafı veya Emoji
            Group {
                if let imageData = friend.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Text(friend.avatarEmoji ?? "👤")
                        .font(.system(size: 28))
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color(.systemGray5)))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                if let phone = friend.phoneNumber {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Transaction Type Picker (Kompakt)

    private var transactionTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "transaction.type", comment: "Transaction type"))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                // Borç Button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        transactionType = .debt
                    }
                    HapticFeedback.light()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(transactionType == .debt ? .white : .red)

                        Text(String(localized: "transaction.debt", comment: "Debt"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(transactionType == .debt ? .white : .primary)

                        Text(String(localized: "transaction.i.owe", comment: "I owe them"))
                            .font(.caption2)
                            .foregroundStyle(transactionType == .debt ? .white.opacity(0.8) : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(transactionType == .debt ? Color.red : Color(.systemGray6))
                    )
                }

                // Alacak Button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        transactionType = .credit
                    }
                    HapticFeedback.light()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title3)
                            .foregroundStyle(transactionType == .credit ? .white : .green)

                        Text(String(localized: "transaction.credit", comment: "Credit"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(transactionType == .credit ? .white : .primary)

                        Text(String(localized: "transaction.they.owe", comment: "They owe me"))
                            .font(.caption2)
                            .foregroundStyle(transactionType == .credit ? .white.opacity(0.8) : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(transactionType == .credit ? Color.green : Color(.systemGray6))
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Amount + Currency Section (Birleştirildi)

    private var amountAndCurrencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "label.tutar"), systemImage: "banknote")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("0", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Picker("", selection: $currency) {
                    ForEach(currencies, id: \.self) { curr in
                        Text(curr).tag(curr)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Description Section (Kompakt)

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "label.açıklama"), systemImage: "text.alignleft")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            TextField(String(localized: "placeholder.örn.yemek.parası.bilet"), text: $transactionDescription)
                .font(.body)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Due Date Section (Kompakt)

    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $hasDueDate) {
                Label(String(localized: "label.vade.tarihi"), systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .tint(.teal)

            if hasDueDate {
                DatePicker("", selection: $dueDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.teal)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Actions

    private func saveTransaction() {
        // Validate amount
        guard let amountValue = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")),
              amountValue > 0 else {
            errorMessage = "Geçerli bir tutar girin"
            showError = true
            return
        }

        // Create transaction
        let transaction = Transaction(
            amount: amountValue,
            currency: currency,
            description: transactionDescription,
            transactionType: transactionType,
            date: Date(),
            dueDate: hasDueDate ? dueDate : nil,
            friend: friend
        )

        modelContext.insert(transaction)

        // Add to friend's transactions
        if friend.transactions == nil {
            friend.transactions = []
        }
        friend.transactions?.append(transaction)

        // Save context
        do {
            try modelContext.save()
            HapticFeedback.success()
            dismiss()
        } catch {
            errorMessage = "Kaydetme hatası: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    let friend = Friend(
        name: "Ahmet Yılmaz",
        avatarEmoji: "🧑‍💼"
    )

    AddTransactionSheet(friend: friend)
        .modelContainer(for: [Friend.self, Transaction.self])
}
