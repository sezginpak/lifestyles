//
//  MoodHeatmapCalendar.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Tam ay mood heatmap calendar (Apple Health tarzı)
//

import SwiftUI

struct MoodHeatmapCalendar: View {
    let heatmapData: [MoodDayData]
    let month: Date
    @State private var selectedDay: MoodDayData?
    @State private var showingDetail: Bool = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Month + Year
            HStack {
                Text(monthYearText)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(heatmapData.filter { $0.moodType != nil }.count) gün")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            // Weekday headers
            HStack(spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                // Leading empty cells (for first week)
                ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                    Color.clear
                        .frame(height: 44)
                }

                // Days
                ForEach(monthDays) { dayData in
                    MoodHeatmapCell(data: dayData)
                        .onTapGesture {
                            selectedDay = dayData
                            showingDetail = true
                            HapticFeedback.light()
                        }
                }
            }

            // Legend
            heatmapLegend
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .sheet(isPresented: $showingDetail) {
            if let day = selectedDay {
                MoodDayDetailPopup(dayData: day)
                    .presentationDetents([.height(300)])
            }
        }
    }

    // MARK: - Helpers

    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: month)
    }

    private var weekdaySymbols: [String] {
        var symbols = calendar.veryShortWeekdaySymbols
        // Move Sunday to end (Mon-Sun order)
        if let sunday = symbols.first {
            symbols.removeFirst()
            symbols.append(sunday)
        }
        return symbols
    }

    private var leadingEmptyDays: Int {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return 0
        }

        var weekday = calendar.component(.weekday, from: firstDay)
        // Convert to Mon=0, Sun=6
        weekday = weekday == 1 ? 6 : weekday - 2
        return weekday
    }

    private var monthDays: [MoodDayData] {
        // Filter heatmap data for this month
        let monthStart = calendar.startOfDay(for: month)
        guard let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return []
        }

        return heatmapData.filter {
            $0.date >= monthStart && $0.date <= monthEnd
        }
    }

    private var heatmapLegend: some View {
        HStack(spacing: 12) {
            Text("Daha az")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ForEach(0..<5, id: \.self) { intensity in
                RoundedRectangle(cornerRadius: 3)
                    .fill(legendColor(intensity: intensity))
                    .frame(width: 16, height: 16)
            }

            Text("Daha çok")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func legendColor(intensity: Int) -> Color {
        switch intensity {
        case 0: return Color(.tertiarySystemFill)
        case 1: return Color(hex: "10B981") ?? .green.opacity(0.3)
        case 2: return Color(hex: "10B981") ?? .green.opacity(0.5)
        case 3: return Color(hex: "10B981") ?? .green.opacity(0.7)
        case 4: return Color(hex: "10B981") ?? .green
        default: return Color(.tertiarySystemFill)
        }
    }
}

// MARK: - Heatmap Cell

struct MoodHeatmapCell: View {
    let data: MoodDayData

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cellColor)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                data.isToday ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                    )

                Text("\(data.dayNumber)")
                    .font(.caption)
                    .fontWeight(data.isToday ? .bold : .regular)
                    .foregroundStyle(textColor)
            }
        }
    }

    private var cellColor: Color {
        guard let mood = data.moodType, let score = data.averageScore else {
            return Color(.tertiarySystemFill)
        }

        // Score: -2 ile +2 arası
        // Renk intensity: score'a göre
        let normalizedScore = (score + 2.0) / 4.0 // 0-1 arası normalize

        if normalizedScore > 0.75 {
            return mood.color.opacity(0.9)
        } else if normalizedScore > 0.5 {
            return mood.color.opacity(0.6)
        } else if normalizedScore > 0.25 {
            return mood.color.opacity(0.3)
        } else {
            return mood.color.opacity(0.15)
        }
    }

    private var textColor: Color {
        guard let score = data.averageScore else {
            return .secondary
        }

        let normalizedScore = (score + 2.0) / 4.0
        return normalizedScore > 0.6 ? .white : .primary
    }
}

// MARK: - Day Detail Popup

struct MoodDayDetailPopup: View {
    let dayData: MoodDayData

    var body: some View {
        VStack(spacing: 20) {
            // Date
            VStack(spacing: 4) {
                Text(dayData.weekdayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(dayData.dayNumber)")
                    .font(.system(size: 48, weight: .bold))
            }

            if let mood = dayData.moodType {
                // Mood emoji
                Text(mood.emoji)
                    .font(.system(size: 60))

                // Mood name
                Text(mood.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(mood.color)

                // Score
                if let score = dayData.averageScore {
                    Text("Skor: \(String(format: "%.1f", score))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    Text("Bu gün mood kaydı yok")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    VStack {
        MoodHeatmapCalendar(
            heatmapData: [
                MoodDayData(date: Date(), moodType: .happy, averageScore: 1.5),
                MoodDayData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, moodType: .veryHappy, averageScore: 2.0),
                MoodDayData(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, moodType: .sad, averageScore: -1.0)
            ],
            month: Date()
        )
    }
    .padding()
}
