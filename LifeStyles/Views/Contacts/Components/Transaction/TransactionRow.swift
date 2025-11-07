//
//  TransactionRow.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Transaction row component
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    let onMarkAsPaid: (Transaction) -> Void
    let onMarkAsUnpaid: (Transaction) -> Void
    let onDelete: (Transaction) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon based on type
            Image(systemName: transaction.transactionType == .debt ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(transaction.transactionType == .debt ? .red : .green)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.transactionDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(transaction.transactionType.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Due Date Info
                if let dueDate = transaction.dueDate, !transaction.isPaid {
                    if let days = transaction.daysUntilDue {
                        if days < 0 {
                            // Overdue
                            Text(String(format: NSLocalizedString("transaction.overdue.days", comment: "Overdue by X days"), abs(days)))
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .fontWeight(.semibold)
                        } else if days == 0 {
                            Text(String(localized: "transaction.due.today", comment: "Due today"))
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .fontWeight(.semibold)
                        } else if days <= 3 {
                            Text(String(format: NSLocalizedString("transaction.due.within.days", comment: "Due within X days"), days))
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        } else {
                            Text(String(format: NSLocalizedString("transaction.due.days", comment: "Due in X days"), days))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(localized: "transaction.amount", defaultValue: "\(transaction.amount.description) \(transaction.currency)", comment: "Transaction amount"))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(transaction.transactionType == .debt ? .red : .green)

                if !transaction.isPaid {
                    Text(String(localized: "transaction.unpaid", comment: "Unpaid"))
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text(String(localized: "transaction.paid", comment: "Paid"))
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(12)
        .background(transaction.isOverdue && !transaction.isPaid ? Color.red.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(transaction.isOverdue && !transaction.isPaid ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .contextMenu {
            // Mark as Paid/Unpaid
            if !transaction.isPaid {
                Button {
                    onMarkAsPaid(transaction)
                } label: {
                    Label(String(localized: "button.mark.paid", comment: "Mark as paid"), systemImage: "checkmark.circle")
                }
            } else {
                Button {
                    onMarkAsUnpaid(transaction)
                } label: {
                    Label(String(localized: "button.mark.unpaid", comment: "Mark as unpaid"), systemImage: "xmark.circle")
                }
            }

            Divider()

            // Delete
            Button(role: .destructive) {
                onDelete(transaction)
            } label: {
                Label(String(localized: "button.delete", comment: "Delete button"), systemImage: "trash")
            }
        }
    }
}
