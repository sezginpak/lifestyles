//
//  BalanceSummaryView.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift
//

import SwiftUI

struct BalanceSummaryView: View {
    let transactions: [Transaction]

    var body: some View {
        let unpaidTransactions = transactions.filter { !$0.isPaid }

        if !unpaidTransactions.isEmpty {
            let totalDebt = unpaidTransactions.filter { $0.transactionType == .debt }.reduce(Decimal(0)) { $0 + $1.amount }
            let totalCredit = unpaidTransactions.filter { $0.transactionType == .credit }.reduce(Decimal(0)) { $0 + $1.amount }
            let balance = totalCredit - totalDebt

            HStack(spacing: 12) {
                // Net Balance
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Durum")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if balance > 0 {
                        Text("+ \(balance.description) TL")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    } else if balance < 0 {
                        Text("- \(abs(balance).description) TL")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                    } else {
                        Text("Dengede")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()

                // Badges
                HStack(spacing: 8) {
                    if totalDebt > 0 {
                        VStack(spacing: 2) {
                            Text(String(localized: "transaction.debt", comment: "Debt"))
                                .font(.caption2)
                            Text("\(totalDebt.description) TL")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
                    }

                    if totalCredit > 0 {
                        VStack(spacing: 2) {
                            Text("Alacak")
                                .font(.caption2)
                            Text("\(totalCredit.description) TL")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
