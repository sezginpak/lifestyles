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
                LabeledContent(String(localized: "api.usage.today", comment: "")) {
                    Text(String(localized: "text.limiterrequeststoday"))
                        .foregroundStyle(.secondary)
                }

                LabeledContent(String(localized: "api.usage.daily.limit", comment: "")) {
                    Text("100")
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(limiter.requestsToday), total: 100)
                    .tint(limiter.requestsToday > 80 ? .red : .blue)

                LabeledContent(String(localized: "api.usage.remaining.quota", comment: "")) {
                    Text(String(localized: "text.limiterremainingdailyquota"))
                        .foregroundStyle(limiter.remainingDailyQuota < 20 ? .red : .green)
                        .bold()
                }
            } header: {
                Text(String(localized: "settings.api.daily.usage", comment: ""))
            }

            // Hourly Stats
            Section {
                LabeledContent(String(localized: "api.usage.this.hour", comment: "")) {
                    Text(String(localized: "text.limiterrequeststhishour.20"))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(limiter.requestsThisHour), total: 20)
                    .tint(limiter.requestsThisHour > 15 ? .orange : .green)
            } header: {
                Text(String(localized: "settings.api.hourly.usage", comment: ""))
            }

            // Cost Section
            Section {
                LabeledContent(String(localized: "api.usage.total.requests", comment: "")) {
                    Text(String(localized: "text.claudeservicetotalrequests"))
                        .foregroundStyle(.secondary)
                }

                LabeledContent(String(localized: "api.usage.input.tokens", comment: "")) {
                    Text(String(localized: "text.claudeservicetotalinputtokens"))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                LabeledContent(String(localized: "api.usage.output.tokens", comment: "")) {
                    Text(String(localized: "text.claudeservicetotaloutputtokens"))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                LabeledContent(String(localized: "api.usage.estimated.cost", comment: "")) {
                    Text("$\(String(format: "%.4f", claudeService.estimatedCost))")
                        .foregroundStyle(.green)
                        .bold()
                }
            } header: {
                Text(String(localized: "settings.api.all.time.stats", comment: ""))
            } footer: {
                Text(String(localized: "api.usage.claude.pricing", comment: ""))
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
                            Text(String(localized: "settings.api.quota.warning", comment: ""))
                                .font(.subheadline)
                                .bold()
                            Text(String(localized: "text.kalan.limiterremainingdailyquota.request"))
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
                    Label(String(localized: "api.usage.reset.cost.stats", comment: ""), systemImage: "trash")
                }

                #if DEBUG
                Button {
                    limiter.resetUsage()
                } label: {
                    Label(String(localized: "api.usage.reset.rate.limit", comment: ""), systemImage: "arrow.counterclockwise")
                }
                #endif
            } header: {
                Text(String(localized: "settings.api.actions", comment: ""))
            }
        }
        .navigationTitle(String(localized: "api.usage.stats.title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        APIUsageStatsView()
    }
}
