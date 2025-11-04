//
//  NotificationPriorityEngine.swift
//  LifeStyles
//
//  Manages notification priorities and queuing
//  Bildirimleri önceliklerine göre sıralar ve yönetir
//

import Foundation
import UserNotifications

@Observable
class NotificationPriorityEngine {
    static let shared = NotificationPriorityEngine()

    // Priority queue
    private var queue: [PriorityQueueItem] = []

    // Daily notification limit
    private var dailyLimit: Int = 20
    private var sentToday: Int = 0
    private var lastResetDate: Date = Date()

    // Throttling
    private var lastSentTime: Date?
    private let minimumInterval: TimeInterval = 300 // 5 dakika

    private init() {
        loadDailyStats()
    }

    // MARK: - Queue Management

    /// Bildirimi kuyruğa ekle
    func enqueue(
        notificationId: String,
        category: String,
        priority: NotificationPriority,
        scheduledTime: Date = Date(),
        userInfo: [String: Any] = [:]
    ) {

        let item = PriorityQueueItem(
            notificationId: notificationId,
            priority: priority,
            scheduledTime: scheduledTime,
            category: category,
            userInfo: userInfo
        )

        queue.append(item)
        queue.sort() // Otomatik öncelik sıralaması

        print("➕ Kuyruğa eklendi: \(category) (Priority: \(priority.level.rawValue))")
        print("   Kuyruk boyutu: \(queue.count)")
    }

    /// Kuyruktaki bir bildirimi çıkar ve gönder
    func dequeue() -> PriorityQueueItem? {
        // Günlük limiti kontrol et
        if hasExceededDailyLimit() {
            print("⚠️ Günlük bildirim limiti aşıldı")
            return nil
        }

        // Throttling kontrolü
        if let lastSent = lastSentTime {
            let elapsed = Date().timeIntervalSince(lastSent)
            if elapsed < minimumInterval {
                print("⏳ Throttling aktif, \(Int(minimumInterval - elapsed))s bekle")
                return nil
            }
        }

        // En yüksek öncelikli bildirimi al
        guard let item = queue.first else {
            return nil
        }

        // Expired kontrolü
        if let expiry = item.priority.expiresAt, expiry < Date() {
            print("⏰ Bildirim expired: \(item.category)")
            queue.removeFirst()
            return dequeue() // Bir sonrakini dene
        }

        queue.removeFirst()

        // İstatistikleri güncelle
        sentToday += 1
        lastSentTime = Date()
        saveDailyStats()

        print("➖ Kuyruktan çıkarıldı: \(item.category)")
        return item
    }

    /// Kuyruğu temizle
    func clearQueue() {
        queue.removeAll()
        print("🗑️ Kuyruk temizlendi")
    }

    /// Kategori bazlı kuyruğu temizle
    func clearQueue(for category: String) {
        let before = queue.count
        queue.removeAll { $0.category == category }
        let removed = before - queue.count

        print("🗑️ \(removed) bildirim kaldırıldı: \(category)")
    }

    // MARK: - Priority Calculation

    /// Contact reminder için öncelik hesapla
    func calculateContactPriority(
        friend: Friend
    ) -> NotificationPriority {

        return PriorityCalculator.calculateContactPriority(
            isVIP: friend.isImportant, // Friend modelinde isImportant property'si kullanılıyor
            daysOverdue: friend.daysOverdue,
            frequency: friend.frequency,
            lastEngagement: 0.7 // TODO: Gerçek engagement skorunu UserBehaviorAnalyzer'dan al
        )
    }

    /// Goal reminder için öncelik hesapla
    func calculateGoalPriority(
        goal: Goal
    ) -> NotificationPriority {

        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: goal.targetDate).day ?? 0

        return PriorityCalculator.calculateGoalPriority(
            daysUntilDeadline: daysUntilDeadline,
            progress: goal.progress,
            isImportant: goal.priority == .high
        )
    }

    /// Streak warning için öncelik hesapla
    func calculateStreakPriority(
        currentStreak: Int,
        hoursRemaining: Int
    ) -> NotificationPriority {

        return PriorityCalculator.calculateStreakPriority(
            currentStreak: currentStreak,
            hoursRemaining: hoursRemaining
        )
    }

    /// Activity suggestion için öncelik hesapla
    func calculateSuggestionPriority(
        contextScore: Double = 0.7,
        lastShownHoursAgo: Int = 24
    ) -> NotificationPriority {

        return PriorityCalculator.calculateSuggestionPriority(
            contextScore: contextScore,
            lastShownHoursAgo: lastShownHoursAgo
        )
    }

    // MARK: - Throttling & Limits

    /// Günlük limit aşıldı mı?
    func hasExceededDailyLimit() -> Bool {
        checkAndResetDaily()
        return sentToday >= dailyLimit
    }

    /// Throttling aktif mi?
    func isThrottling() -> Bool {
        guard let lastSent = lastSentTime else {
            return false
        }

        let elapsed = Date().timeIntervalSince(lastSent)
        return elapsed < minimumInterval
    }

    /// Kalan günlük kota
    func getRemainingQuota() -> Int {
        checkAndResetDaily()
        return max(0, dailyLimit - sentToday)
    }

    /// Günlük limiti ayarla
    func setDailyLimit(_ limit: Int) {
        dailyLimit = max(1, min(50, limit)) // 1-50 arası
        saveDailyStats()
    }

    /// Minimum aralığı ayarla
    func setMinimumInterval(_ seconds: TimeInterval) {
        print("⚙️ Minimum interval ayarlandı: \(Int(seconds))s")
    }

    private func checkAndResetDaily() {
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            // Yeni gün, sıfırla
            sentToday = 0
            lastResetDate = Date()
            saveDailyStats()
            print("🔄 Günlük stats sıfırlandı")
        }
    }

    // MARK: - Persistence

    private func loadDailyStats() {
        sentToday = UserDefaults.standard.integer(forKey: "priority_engine_sent_today")
        if let lastReset = UserDefaults.standard.object(forKey: "priority_engine_last_reset") as? Date {
            lastResetDate = lastReset
        }

        checkAndResetDaily()
    }

    private func saveDailyStats() {
        UserDefaults.standard.set(sentToday, forKey: "priority_engine_sent_today")
        UserDefaults.standard.set(lastResetDate, forKey: "priority_engine_last_reset")
    }

    // MARK: - Analytics

    /// Kuyruk durumunu göster
    func printQueueStatus() {
        print("\n📋 === Priority Queue Status ===")
        print("Kuyruk boyutu: \(queue.count)")
        print("Bugün gönderilen: \(sentToday)/\(dailyLimit)")
        print("Kalan kota: \(getRemainingQuota())")

        if !queue.isEmpty {
            print("\nİlk 5 bildirim:")
            for (index, item) in queue.prefix(5).enumerated() {
                print("   \(index + 1). \(item.category)")
                print("      Priority: \(item.priority.level.rawValue)")
                print("      Score: \(String(format: "%.2f", item.priority.weightedScore * 100))")
            }
        }

        print("================================\n")
    }

    /// Öncelik dağılımını göster
    func getPriorityDistribution() -> [PriorityLevel: Int] {
        var distribution: [PriorityLevel: Int] = [:]

        for item in queue {
            let level = item.priority.level
            distribution[level, default: 0] += 1
        }

        return distribution
    }

    /// Kategori dağılımını göster
    func getCategoryDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]

        for item in queue {
            distribution[item.category, default: 0] += 1
        }

        return distribution
    }

    // MARK: - Batch Operations

    /// Toplu öncelik güncelleme
    func updatePriorities(for category: String, newPriority: NotificationPriority) {
        for index in queue.indices {
            if queue[index].category == category {
                // Priority queue item immutable olduğu için yeniden oluştur
                let old = queue[index]
                queue[index] = PriorityQueueItem(
                    notificationId: old.notificationId,
                    priority: newPriority,
                    scheduledTime: old.scheduledTime,
                    category: old.category
                )
            }
        }

        // Yeniden sırala
        queue.sort()

        print("🔄 \(category) kategorisi için öncelikler güncellendi")
    }

    /// Expired bildirimleri temizle
    func removeExpiredNotifications() {
        let before = queue.count
        queue.removeAll { item in
            if let expiry = item.priority.expiresAt {
                return expiry < Date()
            }
            return false
        }

        let removed = before - queue.count
        if removed > 0 {
            print("🗑️ \(removed) expired bildirim kaldırıldı")
        }
    }

    /// Otomatik queue yönetimi başlat
    func startAutoManagement() {
        // Her 5 dakikada bir expired bildirimleri temizle
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.removeExpiredNotifications()
        }

        print("✅ Otomatik queue yönetimi başlatıldı")
    }
}

// MARK: - Queue Statistics

struct QueueStatistics {
    let totalInQueue: Int
    let sentToday: Int
    let remainingQuota: Int
    let priorityDistribution: [PriorityLevel: Int]
    let categoryDistribution: [String: Int]
    let isThrottling: Bool

    var utilizationRate: Double {
        guard totalInQueue > 0 else { return 0.0 }
        let dailyLimit = 20 // TODO: Dynamic
        return Double(sentToday) / Double(dailyLimit)
    }
}

extension NotificationPriorityEngine {
    func getStatistics() -> QueueStatistics {
        return QueueStatistics(
            totalInQueue: queue.count,
            sentToday: sentToday,
            remainingQuota: getRemainingQuota(),
            priorityDistribution: getPriorityDistribution(),
            categoryDistribution: getCategoryDistribution(),
            isThrottling: isThrottling()
        )
    }
}
