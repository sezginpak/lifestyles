//
//  APIUsageStatsView.swift
//  LifeStyles
//
//  API Usage Statistics View
//  Created by Claude on 04.11.2025.
//

import SwiftUI

struct APIUsageStatsView: View {
    @State private var claudeService = ClaudeHaikuService.shared
    @State private var limiter = APIUsageLimiter.shared

    var body: some View {
        List {
            // Quota Section
            Section {
                LabeledContent("Bugün Kullanılan") {
                    Text("\(limiter.requestsToday)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Günlük Limit") {
                    Text("100")
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(limiter.requestsToday), total: 100)
                    .tint(limiter.requestsToday > 80 ? .red : .blue)

                LabeledContent("Kalan Quota") {
                    Text("\(limiter.remainingDailyQuota)")
                        .foregroundStyle(limiter.remainingDailyQuota < 20 ? .red : .green)
                        .bold()
                }
            } header: {
                Text("Günlük Kullanım")
            }

            // Hourly Stats
            Section {
                LabeledContent("Bu Saat") {
                    Text("\(limiter.requestsThisHour) / 20")
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(limiter.requestsThisHour), total: 20)
                    .tint(limiter.requestsThisHour > 15 ? .orange : .green)
            } header: {
                Text("Saatlik Kullanım")
            }

            // Cost Section
            Section {
                LabeledContent("Toplam Request") {
                    Text("\(claudeService.totalRequests)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Input Tokens") {
                    Text("\(claudeService.totalInputTokens)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                LabeledContent("Output Tokens") {
                    Text("\(claudeService.totalOutputTokens)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                LabeledContent("Tahmini Maliyet") {
                    Text("$\(String(format: "%.4f", claudeService.estimatedCost))")
                        .foregroundStyle(.green)
                        .bold()
                }
            } header: {
                Text("Tüm Zamanlar İstatistikleri")
            } footer: {
                Text("Claude 3.5 Haiku fiyatlandırması: $0.25/1M input, $1.25/1M output tokens")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Warning Section
            if limiter.remainingDailyQuota < 20 {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Günlük Quota Dolmak Üzere")
                                .font(.subheadline)
                                .bold()
                            Text("Kalan: \(limiter.remainingDailyQuota) request")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Actions Section
            Section {
                Button(role: .destructive) {
                    claudeService.resetCostTracking()
                } label: {
                    Label("Maliyet İstatistiklerini Sıfırla", systemImage: "trash")
                }

                #if DEBUG
                Button {
                    limiter.resetUsage()
                } label: {
                    Label("Rate Limit Sıfırla (Debug)", systemImage: "arrow.counterclockwise")
                }
                #endif
            } header: {
                Text("İşlemler")
            }
        }
        .navigationTitle("API Kullanım İstatistikleri")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        APIUsageStatsView()
    }
}
