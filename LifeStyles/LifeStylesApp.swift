//
//  LifeStylesApp.swift
//  LifeStyles
//
//  Created by sezgin paksoy on 15.10.2025.
//

import SwiftUI
import SwiftData

// MARK: - Schema Versioning

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Friend.self, ContactHistory.self, LocationLog.self, Goal.self, Habit.self, HabitCompletion.self, ActivitySuggestion.self]
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Friend.self,
            ContactHistory.self,
            LocationLog.self,
            Goal.self,
            Habit.self,
            HabitCompletion.self,
            ActivitySuggestion.self,
            UserActivityState.self,
            ActivityCompletion.self,
            Badge.self,
            ActivityStats.self,
            SpecialDate.self
        ]
    }
}

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Friend.self,
            ContactHistory.self,
            LocationLog.self,
            Goal.self,
            Habit.self,
            HabitCompletion.self,
            ActivitySuggestion.self,
            UserActivityState.self,
            ActivityCompletion.self,
            Badge.self,
            ActivityStats.self,
            SpecialDate.self,
            GoalMilestone.self // NEW - hedef milestone desteği
        ]
    }
}

enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Friend.self,
            ContactHistory.self,
            LocationLog.self,
            Goal.self,
            Habit.self,
            HabitCompletion.self,
            ActivitySuggestion.self,
            UserActivityState.self,
            ActivityCompletion.self,
            Badge.self,
            ActivityStats.self,
            SpecialDate.self,
            GoalMilestone.self,
            MoodEntry.self, // NEW - mood tracking
            JournalEntry.self // NEW - journal
        ]
    }
}

// MARK: - Migration Plan
enum LifeStylesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [
            // V1 -> V2 migration: Yeni modeller eklenmiş, mevcut veriler korunmalı
            MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self),
            // V2 -> V3 migration: GoalMilestone eklendi
            MigrationStage.lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self),
            // V3 -> V4 migration: Mood & Journal modülleri eklendi
            MigrationStage.lightweight(fromVersion: SchemaV3.self, toVersion: SchemaV4.self)
        ]
    }
}

// MARK: - Development Utilities

#if DEBUG
extension LifeStylesApp {
    /// Development amaçlı - SQLite dosyasını siler ve temiz başlar
    static func resetDataStore() {
        let url = URL.applicationSupportDirectory.appending(path: "default.store")
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                print("Veri tabanı dosyası silindi: \(url)")
            } catch {
                print("Veri tabanı silinemedi: \(error)")
            }
        }
    }
}
#endif

@main
struct LifeStylesApp: App {
    @State private var isOnboardingComplete = OnboardingViewModel.hasCompletedOnboarding()
    @State private var deepLinkRouter = DeepLinkRouter()

    // SwiftData ModelContainer'ı CloudKit ile kur
    var sharedModelContainer: ModelContainer = {
        do {
            // Basit container (migration olmadan) - Development için
            let container = try ModelContainer(
                for:
                    Friend.self,
                    ContactHistory.self,
                    LocationLog.self,
                    Goal.self,
                    Habit.self,
                    HabitCompletion.self,
                    ActivitySuggestion.self,
                    UserActivityState.self,
                    ActivityCompletion.self,
                    Badge.self,
                    ActivityStats.self,
                    SpecialDate.self,
                    GoalMilestone.self,
                    MoodEntry.self,
                    JournalEntry.self
            )

            // CloudKit sync'i aktif et
            container.mainContext.autosaveEnabled = true

            return container
        } catch {
            print("⚠️ ModelContainer oluşturma hatası: \(error)")

            #if DEBUG
            // Development modunda detaylı hata göster ama VERİLERİ SİLME!
            print("🔍 Hata detayı: \(error.localizedDescription)")
            print("⚠️ Migration hatası - veriler korunuyor, basit container oluşturuluyor")

            // Basit container oluştur (migration olmadan)
            do {
                return try ModelContainer(
                    for:
                        Friend.self,
                        ContactHistory.self,
                        LocationLog.self,
                        Goal.self,
                        Habit.self,
                        HabitCompletion.self,
                        ActivitySuggestion.self,
                        UserActivityState.self,
                        ActivityCompletion.self,
                        Badge.self,
                        ActivityStats.self,
                        SpecialDate.self,
                        GoalMilestone.self,
                        MoodEntry.self, // NEW
                        JournalEntry.self // NEW
                )
            } catch {
                fatalError("❌ Hiçbir ModelContainer oluşturulamadı: \(error)")
            }
            #else
            fatalError("❌ ModelContainer oluşturulamadı: \(error)")
            #endif
        }
    }()

    var body: some Scene {
        WindowGroup {
            if isOnboardingComplete {
                ContentView()
                    .modelContainer(sharedModelContainer)
                    .environment(deepLinkRouter)
                    .onAppear {
                        // Uygulama açıldığında otomatik konum takibini başlat
                        initializeLocationTracking()

                        // Notification sistemini başlat
                        initializeNotificationSystem()
                    }
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
            }
        }
    }

    // Konum takibini otomatik başlat
    private func initializeLocationTracking() {
        // Her Zaman izni var mı kontrol et
        guard PermissionManager.shared.hasAlwaysLocationPermission() else {
            print("ℹ️ Her Zaman konum izni yok, otomatik başlatma yapılamadı")
            return
        }

        // LocationService'in yüklenmiş durumunu kontrol et
        let service = LocationService.shared

        // ModelContext'i ayarla
        let context = sharedModelContainer.mainContext
        service.setModelContext(context)

        // Eğer takip durumu kaydedilmişse ve aktifse, yeniden başlat
        if service.isPeriodicTrackingActive {
            print("🔄 Uygulama açıldı, konum takibi devam ettiriliyor...")
            service.startPeriodicTracking()
        } else {
            print("✅ Her Zaman izni var, ilk kez otomatik başlatılıyor...")
            service.startPeriodicTracking()
        }
    }

    // Notification sistemini başlat
    private func initializeNotificationSystem() {
        // Notification sistemini setup et
        NotificationService.shared.initializeNotificationSystem()

        // Deep link callback'i ayarla
        NotificationDelegate.shared.setDeepLinkHandler { [self] path, parameters in
            print("🔗 Deep link received: \(path)")
            deepLinkRouter.handle(path: path, parameters: parameters)
        }

        // User behavior tracking başlat
        NotificationScheduler.shared.analyzeUserBehavior()

        // Tüm friend hatırlatmalarını zamanla
        scheduleFriendReminders()

        print("✅ Notification sistem tamamen başlatıldı")
    }

    // Tüm friend'ler için hatırlatmaları zamanla
    private func scheduleFriendReminders() {
        let context = sharedModelContainer.mainContext

        // Tüm friend'leri çek
        let fetchDescriptor = FetchDescriptor<Friend>()
        guard let friends = try? context.fetch(fetchDescriptor) else {
            print("⚠️ Friend'ler alınamadı")
            return
        }

        // İletişim hatırlatmalarını zamanla
        NotificationService.shared.scheduleContactReminders(for: friends)

        let needsContactCount = friends.filter { $0.needsContact }.count
        print("✅ \(friends.count) arkadaş için bildirimler zamanlandı (\(needsContactCount) kişi bekliyor)")
    }
}
