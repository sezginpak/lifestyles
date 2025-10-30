//
//  LifeStylesApp.swift
//  LifeStyles
//
//  Created by sezgin paksoy on 15.10.2025.
//

import SwiftUI
import SwiftData

// MARK: - Schema Versioning
// NOTE: Migration plan disabled for development
// Production'da migration gerektiğinde aktif edilebilir

/*
// Schema versioning examples - Currently disabled
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Friend.self, ContactHistory.self, LocationLog.self, Goal.self, Habit.self, HabitCompletion.self, ActivitySuggestion.self]
    }
}
*/

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
    @State private var showSplashScreen = true
    @State private var isOnboardingComplete = OnboardingViewModel.hasCompletedOnboarding()
    @State private var deepLinkRouter = DeepLinkRouter()

    // SwiftData ModelContainer'ı CloudKit ile kur
    var sharedModelContainer: ModelContainer = {
        // NOT: DEBUG modda otomatik silme KAPATILDI
        // CloudKit sync çalışması için veriler korunmalı

        do {
            // Schema definition
            let schema = Schema([
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
                JournalEntry.self,
                UserProfile.self,
                ChatConversation.self,
                ChatMessage.self,
                JournalTemplate.self,
                SavedPlace.self, // NEW - Saved places
                PlaceVisit.self, // NEW - Place visits
                Memory.self, // NEW - Memories & Photos
                Transaction.self // NEW - Borç/Alacak
            ])

            // CloudKit configuration - Tekrar aktif
            // NOT: Validation uyarıları olabilir ama veriler senkronize olacak
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic // ✅ CloudKit açık - veriler geri gelecek
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // CloudKit sync'i aktif et
            container.mainContext.autosaveEnabled = true

            print("✅ ModelContainer oluşturuldu (20 model) + CloudKit aktif")
            print("🔄 CloudKit senkronizasyonu otomatik başlayacak...")
            print("💡 İlk sync birkaç dakika sürebilir, lütfen bekleyin")

            return container

        } catch {
            print("⚠️ ModelContainer oluşturma hatası: \(error)")
            print("🔍 Hata detayı: \(error.localizedDescription)")

            // Schema değişikliği nedeniyle migration gerekiyor
            // Lokal storage ile devam et (veriler korunur)
            print("🔄 CloudKit yerine lokal storage kullanılacak...")

            do {
                let schema = Schema([
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
                    JournalEntry.self,
                    UserProfile.self,
                    ChatConversation.self,
                    ChatMessage.self,
                    JournalTemplate.self,
                    SavedPlace.self,
                    PlaceVisit.self,
                    Memory.self,
                    Transaction.self
                ])

                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )

                let container = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                container.mainContext.autosaveEnabled = true
                print("✅ Lokal storage ile başarıyla oluşturuldu")
                print("💾 Verileriniz güvenli bir şekilde cihazınızda saklanacak")
                return container
            } catch let retryError {
                print("❌ Lokal storage hatası: \(retryError)")
                print("🆘 Emergency fallback: In-memory storage kullanılacak...")

                // Son çare: In-memory storage (uygulama kapanınca veriler silinir)
                do {
                    let schema = Schema([
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
                        JournalEntry.self,
                        UserProfile.self,
                        ChatConversation.self,
                        ChatMessage.self,
                        JournalTemplate.self,
                        SavedPlace.self,
                        PlaceVisit.self,
                        Memory.self,
                        Transaction.self
                    ])

                    let modelConfiguration = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: true // ✅ RAM'de geçici çalışır
                    )

                    let container = try ModelContainer(
                        for: schema,
                        configurations: [modelConfiguration]
                    )
                    container.mainContext.autosaveEnabled = false // In-memory için gerek yok

                    print("⚠️ EMERGENCY MODE: In-memory storage aktif")
                    print("⚠️ UYARI: Verileriniz uygulama kapandığında silinecek!")
                    print("⚠️ Lütfen uygulamayı yeniden yükleyin veya güncelleyin")

                    return container
                } catch let emergencyError {
                    // Artık gerçekten hiçbir şey yapamayız
                    print("💥 FATAL: Hiçbir storage oluşturulamadı: \(emergencyError)")
                    fatalError("❌ Kritik hata: Hiçbir storage sistemi oluşturulamadı. Lütfen uygulamayı silin ve yeniden yükleyin.")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplashScreen {
                    // MARK: - Splash Screen
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(2)
                } else {
                    // MARK: - Main Content
                    if isOnboardingComplete {
                        ContentView()
                            .modelContainer(sharedModelContainer)
                            .environment(deepLinkRouter)
                            .transition(.opacity)
                            .onAppear {
                                // Uygulama açıldığında otomatik konum takibini başlat
                                initializeLocationTracking()

                                // Notification sistemini başlat
                                initializeNotificationSystem()
                            }
                    } else {
                        OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                            .transition(.opacity)
                    }
                }
            }
            .onAppear {
                // Splash screen 2.5 saniye sonra kaybolsun
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplashScreen = false
                    }
                }
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

        // Geçmiş LocationLog kayıtlarını migrate et
        migrateLocationLogs(context: context)

        // SavedPlacesService'i initialize et
        let placesService = SavedPlacesService.shared
        placesService.setModelContext(context)
        placesService.startMonitoring()

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

    // Geçmiş LocationLog kayıtlarını migrate et
    private func migrateLocationLogs(context: ModelContext) {
        // Sadece bir kere çalışsın
        let migrationKey = "locationLogMigrationCompleted_v1"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }

        print("🔄 LocationLog migration başlatılıyor...")

        // Async olarak çalıştır - UI'yı bloklama
        Task.detached {
            let descriptor = FetchDescriptor<LocationLog>()

            do {
                let logs = try context.fetch(descriptor)

                // durationInMinutes 0 olanları düzelt
                var fixedCount = 0
                for log in logs {
                    if log.durationInMinutes == 0 {
                        log.durationInMinutes = 10 // Default 10 dakika
                        fixedCount += 1
                    }
                }

                if fixedCount > 0 {
                    try context.save()
                    print("✅ \(fixedCount) adet LocationLog kaydı güncellendi (durationInMinutes = 10)")
                } else {
                    print("✅ Tüm LocationLog kayıtları zaten güncel")
                }

                // Migration tamamlandı, bir daha çalıştırma
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: migrationKey)
                }

            } catch {
                // SwiftData hatası - silent fail, kullanıcı deneyimini bozma
                print("⚠️ LocationLog migration hatası: \(error.localizedDescription)")
                print("ℹ️  Uygulama normal şekilde çalışmaya devam edecek")

                // Yine de migration'ı tamamlanmış say ki tekrar deneme
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: migrationKey)
                }
            }
        }
    }
}
