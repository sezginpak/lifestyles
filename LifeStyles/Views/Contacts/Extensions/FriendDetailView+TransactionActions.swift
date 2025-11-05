//
//  FriendDetailView+TransactionActions.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Transaction action methods extracted from FriendDetailTabs.swift
//

import SwiftUI
import SwiftData

extension FriendDetailView {
    func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)

        // Remove from friend's transactions array
        if let index = friend.transactions?.firstIndex(where: { $0.id == transaction.id }) {
            friend.transactions?.remove(at: index)
        }

        do {
            try modelContext.save()
            HapticFeedback.success()
        } catch {
            print("❌ Transaction silinemedi: \(error)")
        }
    }

    func markTransactionAsPaid(_ transaction: Transaction) {
        transaction.isPaid = true
        transaction.paidDate = Date()
        transaction.paidAmount = transaction.amount

        do {
            try modelContext.save()
            HapticFeedback.success()
        } catch {
            print("❌ Transaction güncellenemedi: \(error)")
        }
    }

    func markTransactionAsUnpaid(_ transaction: Transaction) {
        transaction.isPaid = false
        transaction.paidDate = nil
        transaction.paidAmount = 0

        do {
            try modelContext.save()
            HapticFeedback.success()
        } catch {
            print("❌ Transaction güncellenemedi: \(error)")
        }
    }
}
