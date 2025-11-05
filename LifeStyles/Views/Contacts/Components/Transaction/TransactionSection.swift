//
//  TransactionSection.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift
//

import SwiftUI

struct TransactionSection: View {
    let friend: Friend
    @Binding var showingAddTransaction: Bool
    let onMarkAsPaid: (Transaction) -> Void
    let onMarkAsUnpaid: (Transaction) -> Void
    let onDelete: (Transaction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Borç/Alacak", systemImage: "banknote")
                    .font(.headline)

                Spacer()

                Button {
                    showingAddTransaction = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }

            // Check if transactions exist
            if let transactions = friend.transactions, !transactions.isEmpty {
                VStack(spacing: 12) {
                    // Balance Summary
                    BalanceSummaryView(transactions: transactions)

                    // Transactions list
                    ForEach(transactions.sorted(by: { $0.date > $1.date }), id: \.id) { transaction in
                        TransactionRow(
                            transaction: transaction,
                            onMarkAsPaid: onMarkAsPaid,
                            onMarkAsUnpaid: onMarkAsUnpaid,
                            onDelete: onDelete
                        )
                    }
                }
            } else {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "banknote")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.5))

                    Text(String(localized: "transaction.empty", comment: "No transaction records"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        showingAddTransaction = true
                    } label: {
                        Text(String(localized: "transaction.add.first", comment: "Add first transaction"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionSheet(friend: friend)
        }
    }
}
