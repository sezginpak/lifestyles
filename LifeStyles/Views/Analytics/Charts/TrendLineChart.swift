//
//  TrendLineChart.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import SwiftUI
import Charts

/// Trend line chart component
struct TrendLineChart: View {
    let title: String
    let dataPoints: [ChartDataPoint]
    let color: Color
    let showAverage: Bool

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let label: String?

        init(date: Date, value: Double, label: String? = nil) {
            self.date = date
            self.value = value
            self.label = label
        }
    }

    init(
        title: String,
        dataPoints: [ChartDataPoint],
        color: Color = .blue,
        showAverage: Bool = true
    ) {
        self.title = title
        self.dataPoints = dataPoints
        self.color = color
        self.showAverage = showAverage
    }

    private var averageValue: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return dataPoints.map { $0.value }.reduce(0, +) / Double(dataPoints.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if showAverage && !dataPoints.isEmpty {
                    let avgText = String(localized: "analytics.chart.average", defaultValue: "Ort", comment: "Average label")
                    Text("\(avgText): \(averageValue, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            // Chart
            if dataPoints.isEmpty {
                emptyState
            } else {
                Chart {
                    // Area fill
                    ForEach(dataPoints) { point in
                        AreaMark(
                            x: .value(String(localized: "analytics.chart.date", defaultValue: "Tarih", comment: "Date axis label"), point.date),
                            y: .value(String(localized: "analytics.chart.value", defaultValue: "Değer", comment: "Value axis label"), point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    // Line
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value(String(localized: "analytics.chart.date", defaultValue: "Tarih", comment: "Date axis label"), point.date),
                            y: .value(String(localized: "analytics.chart.value", defaultValue: "Değer", comment: "Value axis label"), point.value)
                        )
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }

                    // Points
                    ForEach(dataPoints) { point in
                        PointMark(
                            x: .value(String(localized: "analytics.chart.date", defaultValue: "Tarih", comment: "Date axis label"), point.date),
                            y: .value(String(localized: "analytics.chart.value", defaultValue: "Değer", comment: "Value axis label"), point.value)
                        )
                        .foregroundStyle(color)
                        .symbolSize(50)
                    }

                    // Average line
                    if showAverage {
                        RuleMark(y: .value(String(localized: "analytics.chart.average", defaultValue: "Ortalama", comment: "Average line label"), averageValue))
                            .foregroundStyle(color.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text(String(localized: "analytics.chart.average", defaultValue: "Ort", comment: "Average label"))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.day().month(.abbreviated))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(doubleValue, specifier: "%.0f")")
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(String(localized: "analytics.chart.noData", defaultValue: "Veri yok", comment: "No data available"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = Date()

    let sampleData = Array((0..<7).map { offset in
        let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        let value = Double.random(in: 50...90)
        return TrendLineChart.ChartDataPoint(date: date, value: value)
    }.reversed())

    ScrollView {
        VStack(spacing: 16) {
            TrendLineChart(
                title: "Haftalık Ruh Hali Trendi",
                dataPoints: sampleData,
                color: .blue
            )

            TrendLineChart(
                title: "İletişim Sıklığı",
                dataPoints: sampleData,
                color: .green
            )
        }
        .padding()
    }
}
