//
//  Transaction.swift
//  LifeStyles
//
//  Created by Claude on 27.10.2025.
//  Borç/Alacak Transaction Model
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID = UUID()
    var amount: Decimal = 0
    var currency: String = "TL" // "TL", "USD", "EUR"
    var transactionDescription: String = ""
    var transactionTypeRaw: String = "Borç" // Raw value for SwiftData
    var date: Date = Date()
    var dueDate: Date?
    var isPaid: Bool = false
    var paidDate: Date?
    var paidAmount: Decimal = 0
    var category: String?
    var createdAt: Date = Date()

    // Relationship - inverse tanımlı Friend tarafında
    var friend: Friend?

    // Computed property for transactionType
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRaw) ?? .debt }
        set { transactionTypeRaw = newValue.rawValue }
    }

    init(
        amount: Decimal,
        currency: String = "TL",
        description: String,
        transactionType: TransactionType,
        date: Date = Date(),
        dueDate: Date? = nil,
        isPaid: Bool = false,
        paidDate: Date? = nil,
        paidAmount: Decimal = 0,
        category: String? = nil,
        friend: Friend? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.currency = currency
        self.transactionDescription = description
        self.transactionTypeRaw = transactionType.rawValue // Store raw value
        self.date = date
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.paidDate = paidDate
        self.paidAmount = paidAmount
        self.category = category
        self.createdAt = Date()
        self.friend = friend
    }
}

// MARK: - Transaction Type

enum TransactionType: String, Codable, CaseIterable {
    case debt = "Borç"       // Ben borçluyum (I owe them)
    case credit = "Alacak"   // Benden borçlu (They owe me)
    case payment = "Ödeme"   // Ödeme yapıldı

    var icon: String {
        switch self {
        case .debt: return "arrow.up.circle.fill"
        case .credit: return "arrow.down.circle.fill"
        case .payment: return "checkmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .debt: return "red"
        case .credit: return "green"
        case .payment: return "blue"
        }
    }
}

// MARK: - Transaction Extensions

extension Transaction {
    var remainingAmount: Decimal {
        return amount - paidAmount
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate, !isPaid else { return false }
        return Date() > dueDate
    }

    var daysUntilDue: Int? {
        guard let dueDate = dueDate, !isPaid else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: dueDate).day
        return days
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currency)"
    }

    var formattedRemainingAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: remainingAmount as NSDecimalNumber) ?? "\(remainingAmount) \(currency)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    var formattedDueDate: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: dueDate)
    }

    var statusText: String {
        if isPaid {
            return "Ödendi"
        } else if isOverdue {
            return "Gecikti"
        } else if let days = daysUntilDue {
            if days == 0 {
                return "Bugün"
            } else if days == 1 {
                return "Yarın"
            } else if days > 0 {
                return "\(days) gün"
            } else {
                return "\(-days) gün gecikti"
            }
        } else {
            return "Vade yok"
        }
    }
}
