//
//  CorrelationMatrix.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import SwiftUI

/// Korelasyon matrisi görselleştirmesi
struct CorrelationMatrix: View {
    let title: String
    let correlations: [CorrelationItem]

    struct CorrelationItem: Identifiable {
        let id = UUID()
        let label1: String
        let label2: String
        let value: Double // -1.0 to 1.0
        let description: String?

        var strengthText: String {
            let abs = abs(value)
            switch abs {
            case 0.8...1.0: return String(localized: "analytics.correlation.veryStrong", defaultValue: "Çok Güçlü", comment: "Very strong correlation")
            case 0.6..<0.8: return String(localized: "analytics.correlation.strong", defaultValue: "Güçlü", comment: "Strong correlation")
            case 0.4..<0.6: return String(localized: "analytics.correlation.moderate", defaultValue: "Orta", comment: "Moderate correlation")
            case 0.2..<0.4: return String(localized: "analytics.correlation.weak", defaultValue: "Zayıf", comment: "Weak correlation")
            default: return String(localized: "analytics.correlation.veryWeak", defaultValue: "Çok Zayıf", comment: "Very weak correlation")
            }
        }

        var color: Color {
            if value > 0.6 {
                return .green
            } else if value > 0.3 {
                return .blue
            } else if value > 0 {
                return .gray
            } else if value > -0.3 {
                return .orange
            } else {
                return .red
            }
        }

        var directionIcon: String {
            value > 0 ? "arrow.up.right" : "arrow.down.right"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            if correlations.isEmpty {
                emptyState
            } else {
                // Correlation items
                ForEach(correlations) { correlation in
                    correlationRow(correlation)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func correlationRow(_ item: CorrelationItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Labels and value
            HStack(spacing: 8) {
                // Left label
                Text(item.label1)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: 70, alignment: .leading)

                // Arrow
                Image(systemName: item.directionIcon)
                    .font(.caption)
                    .foregroundStyle(item.color)
                    .frame(width: 16)

                // Right label
                Text(item.label2)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: 70, alignment: .leading)

                Spacer()

                // Value and strength
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.value, format: .number.precision(.fractionLength(2)))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(item.color)

                    Text(item.strengthText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 60)
            }

            // Visual bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [item.color.opacity(0.6), item.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(abs(item.value)), height: 8)
                }
            }
            .frame(height: 8)

            // Description
            if let description = item.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(item.color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(String(localized: "analytics.correlation.noData", defaultValue: "Korelasyon verisi yok", comment: "No correlation data"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            CorrelationMatrix(
                title: "Veri Korelasyonları",
                correlations: [
                    CorrelationMatrix.CorrelationItem(
                        label1: "Ruh Hali",
                        label2: "İletişim",
                        value: 0.72,
                        description: "Arkadaşlarla görüşmek ruh halini olumlu etkiliyor"
                    ),
                    CorrelationMatrix.CorrelationItem(
                        label1: "Ruh Hali",
                        label2: "Hedefler",
                        value: 0.65,
                        description: "Hedef tamamlamak mutluluk veriyor"
                    ),
                    CorrelationMatrix.CorrelationItem(
                        label1: "Ruh Hali",
                        label2: "Konum",
                        value: 0.58,
                        description: "Dışarıda olmak ruh halini iyileştiriyor"
                    ),
                    CorrelationMatrix.CorrelationItem(
                        label1: "İletişim",
                        label2: "Mobilite",
                        value: 0.45,
                        description: "Dışarı çıkmak sosyal etkileşimi artırıyor"
                    )
                ]
            )
        }
        .padding()
    }
}
