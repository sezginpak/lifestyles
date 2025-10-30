//
//  CallReminderWidget.swift
//  Widget Extension için
//
//  KULLANIM: Bu dosyayı Widget Extension oluşturduktan sonra
//  otomatik gelen widget dosyasının yerine kopyalayın
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct CallReminderWidgetBundle: WidgetBundle {
    var body: some Widget {
        CallReminderLiveActivity()
    }
}

// MARK: - Live Activity Widget

struct CallReminderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CallReminderAttributes.self) { context in
            // Lock Screen görünümü
            CallReminderLockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island görünümü
            DynamicIsland {
                // Expanded (genişletilmiş) görünüm
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.friendEmoji ?? "📞")
                            .font(.system(size: 32))

                        Text(context.state.friendName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("🔔")
                            .font(.system(size: 28))

                        Text(context.state.status.rawValue)
                            .font(.caption2)
                            .foregroundColor(context.state.status == .overdue ? .red : .secondary)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    // Boş bırak
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Kalan süre
                        Text(timeRemaining(from: context.state.reminderTime))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(context.state.status == .overdue ? .red : .primary)

                        // Durum mesajı
                        if context.state.status == .overdue {
                            Text("ZAMAN GEÇTİ! ⚠️")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(8)
                        } else {
                            Text("ile konuşma zamanı yaklaşıyor")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

            } compactLeading: {
                // Compact Leading (sol taraf - küçük)
                Text(context.attributes.friendEmoji ?? "📞")
                    .font(.system(size: 20))
            } compactTrailing: {
                // Compact Trailing (sağ taraf - küçük)
                Text(timeRemainingShort(from: context.state.reminderTime))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 40)
            } minimal: {
                // Minimal (en küçük görünüm)
                Text(context.attributes.friendEmoji ?? "📞")
                    .font(.system(size: 18))
            }
        }
    }

    // Kalan süreyi hesapla (uzun format)
    func timeRemaining(from date: Date) -> String {
        let diff = Int(date.timeIntervalSinceNow)

        if diff < 0 {
            let elapsed = abs(diff)
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            return String(format: "+%02d:%02d", minutes, seconds)
        }

        let minutes = diff / 60
        let seconds = diff % 60
        return String(format "%02d:%02d", minutes, seconds)
    }

    // Kalan süreyi hesapla (kısa format)
    func timeRemainingShort(from date: Date) -> String {
        let diff = Int(date.timeIntervalSinceNow)

        if diff < 0 {
            return "GEÇTİ"
        }

        if diff < 60 {
            return "\(diff)s"
        }

        let minutes = diff / 60
        return "\(minutes)m"
    }
}

// MARK: - Lock Screen View

struct CallReminderLockScreenView: View {
    let context: ActivityViewContext<CallReminderAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Sol: Emoji ve bilgi
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(context.attributes.friendEmoji ?? "📞")
                        .font(.system(size: 44))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.friendName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("ile konuşma zamanı")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Durum
                if context.state.status == .overdue {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Zaman Geçti!")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(6)
                }
            }

            Spacer()

            // Sağ: Countdown timer
            VStack(spacing: 4) {
                Text(timeRemaining(from: context.state.reminderTime))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(context.state.status == .overdue ? .red : .primary)

                if context.state.status != .overdue {
                    Text("kaldı")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
    }

    func timeRemaining(from date: Date) -> String {
        let diff = Int(date.timeIntervalSinceNow)

        if diff < 0 {
            let elapsed = abs(diff)
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            return String(format: "+%02d:%02d", minutes, seconds)
        }

        let minutes = diff / 60
        let seconds = diff % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
