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

    // ⚠️ TEMİZLEME: Sadece bir kere çalıştır, sonra yorum satırına al!
    init() {
        // cleanupOldLocationData() // ← Sadece eski konum kayıtlarını sil (✅ Tamamlandı)
    }

    /// Eski konum kayıtlarını temizle (CloudKit quota için)
    func cleanupOldLocationData() {
        Task {
            let context = sharedModelContainer.mainContext

            // Son 7 günden eski konum kayıtlarını sil
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

            let descriptor = FetchDescriptor<LocationLog>(
                predicate: #Predicate { log in
                    log.timestamp < sevenDaysAgo
                }
            )

            do {
                let oldLogs = try context.fetch(descriptor)
                print("🗑️ Silinecek eski konum kaydı: \(oldLogs.count)")

                for log in oldLogs {
                    context.delete(log)
                }

                try context.save()
            } catch {
                print("❌ Temizleme hatası: \(error)")
            }
        }
    }

    // SwiftData ModelContainer'ı CloudKit ile kur
    var sharedModelContainer: ModelContainer = {
        // NOT: DEBUG modda otomatik silme KAPATILDI
        // CloudKit sync çalışması için veriler korunmalı

        do {
            // Schema definition
            let schema = Schema([
                Friend.self,
                ContactHistory.self,
                ContactTag.self, // NEW - Contact tagging system
                LocationLog.self,
                Goal.self,
                Habit.self,
                HabitCompletion.self,
                ActivitySuggestion.self,
                UserActivityState.self,
                ActivityCompletion.self,
                Badge.self, // Activity Badge (not gamification)
                GamificationBadge.self, // NEW - Gamification Badge
                UserProgress.self, // NEW - Gamification
                AcceptedSuggestion.self, // NEW - Smart Suggestions Progress
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
                Transaction.self, // NEW - Borç/Alacak
                NotificationTiming.self, // NEW - ML-based notification timing
                UserKnowledge.self // NEW - AI Learning System
            ])

            // CloudKit configuration
            // NOT: Development environment temizlendikten sonra aktif
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic // ✅ CloudKit aktif - Environment otomatik seçilir
                // Simulator = Development, Real Device = Production
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // CloudKit sync'i aktif et
            container.mainContext.autosaveEnabled = true

            // CloudKit durumunu kontrol et
            print("💡 İlk sync birkaç dakika sürebilir, lütfen bekleyin")

            return container

        } catch {
            print("⚠️ ModelContainer oluşturma hatası: \(error)")
            print("🔍 Hata detayı: \(error.localizedDescription)")

            // Schema değişikliği nedeniyle migration gerekiyor
            // Lokal storage ile devam et (veriler korunur)

            do {
                let schema = Schema([
                    Friend.self,
                    ContactHistory.self,
                    ContactTag.self, // NEW - Contact tagging system
                    LocationLog.self,
                    Goal.self,
                    Habit.self,
                    HabitCompletion.self,
                    ActivitySuggestion.self,
                    UserActivityState.self,
                    ActivityCompletion.self,
                    Badge.self, // Activity Badge (not gamification)
                    GamificationBadge.self, // NEW - Gamification Badge
                    UserProgress.self, // NEW - Gamification
                    AcceptedSuggestion.self, // NEW - Smart Suggestions Progress
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
                    Transaction.self,
                    NotificationTiming.self,
                    UserKnowledge.self
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
                        ContactTag.self, // NEW - Contact tagging system
                        LocationLog.self,
                        Goal.self,
                        Habit.self,
                        HabitCompletion.self,
                        ActivitySuggestion.self,
                        UserActivityState.self,
                        ActivityCompletion.self,
                        Badge.self, // Activity Badge (not gamification)
                        GamificationBadge.self, // NEW - Gamification Badge
                        UserProgress.self, // NEW - Gamification
                        AcceptedSuggestion.self, // NEW - Smart Suggestions Progress
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
                        Transaction.self,
                        NotificationTiming.self,
                        UserKnowledge.self
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
                    // Son çare: Minimal schema ile in-memory container
                    print("💥 KRITIK: Tüm storage denemeleri başarısız: \(emergencyError)")
                    print("🆘 MINIMAL SCHEMA ile devam ediliyor...")

                    do {
                        // Minimal schema - sadece temel modeller
                        let minimalSchema = Schema([
                            Friend.self,
                            ContactHistory.self,
                            LocationLog.self,
                            Goal.self,
                            Habit.self,
                            HabitCompletion.self
                        ])

                        let minimalConfig = ModelConfiguration(
                            schema: minimalSchema,
                            isStoredInMemoryOnly: true
                        )

                        let emergencyContainer = try ModelContainer(
                            for: minimalSchema,
                            configurations: [minimalConfig]
                        )

                        print("✅ EMERGENCY CONTAINER oluşturuldu (minimal özellikler)")
                        print("⚠️ UYARI: Sadece temel özellikler kullanılabilir")
                        print("⚠️ UYARI: Veriler geçici (uygulama kapanınca silinir)")

                        return emergencyContainer

                    } catch let finalError {
                        // Artık yapılacak bir şey yok - boş container döndür
                        print("💀 SON ÇARE: Boş container oluşturuluyor")
                        print("💀 Hata: \(finalError.localizedDescription)")

                        // Hiç model olmadan boş container (son çare)
                        let emptySchema = Schema([])
                        let emptyConfig = ModelConfiguration(
                            schema: emptySchema,
                            isStoredInMemoryOnly: true
                        )

                        do {
                            let emptyContainer = try ModelContainer(
                                for: emptySchema,
                                configurations: [emptyConfig]
                            )

                            print("⚠️ BOŞ CONTAINER - Veri işlemleri yapılamayacak")
                            return emptyContainer
                        } catch {
                            // Artık gerçekten yapılacak bir şey yok
                            // Ama yine de fatalError yerine boş bir context döndürelim
                            fatalError("❌ KRİTİK: ModelContainer oluşturulamadı. Uygulamayı yeniden yükleyin.")
                        }
                    }
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
                            .onOpenURL { url in
                                handleDeepLink(url)
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

    // MARK: - Deep Link Handling

    /// Widget'tan gelen deep link'leri handle et
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep Link alındı: \(url)")

        guard url.scheme == "lifestyles" else {
            print("⚠️ Bilinmeyen URL scheme: \(url.scheme ?? "nil")")
            return
        }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "complete-call":
            // lifestyles://complete-call/{friendId}
            guard let friendId = pathComponents.first,
                  let uuid = UUID(uuidString: friendId) else {
                print("❌ Geçersiz friend ID: \(pathComponents)")
                return
            }

            handleCompleteCall(friendId: uuid)

        case "snooze":
            // lifestyles://snooze/{friendId}
            guard let friendId = pathComponents.first,
                  let uuid = UUID(uuidString: friendId) else {
                print("❌ Geçersiz friend ID: \(pathComponents)")
                return
            }

            handleSnoozeReminder(friendId: uuid)

        case "call-reminder":
            // lifestyles://call-reminder/{friendId}
            guard let friendId = pathComponents.first,
                  let uuid = UUID(uuidString: friendId) else {
                print("❌ Geçersiz friend ID: \(pathComponents)")
                return
            }

            // Friend detay sayfasına git
            deepLinkRouter.handle(path: "friend/\(uuid.uuidString)", parameters: [:])

        case "friend-detail":
            // lifestyles://friend-detail/{friendId} (Widget)
            guard let friendId = pathComponents.first,
                  let uuid = UUID(uuidString: friendId) else {
                print("❌ Geçersiz friend ID: \(pathComponents)")
                return
            }

            // DeepLinkRouter ile friend detail'a git
            deepLinkRouter.friendId = friendId
            deepLinkRouter.shouldShowFriendDetail = true
            deepLinkRouter.activeTab = 1 // Contacts tab

        case "complete-contact":
            // lifestyles://complete-contact/{friendId} (Widget)
            guard let friendId = pathComponents.first,
                  let uuid = UUID(uuidString: friendId) else {
                print("❌ Geçersiz friend ID: \(pathComponents)")
                return
            }

            handleCompleteCall(friendId: uuid)

        case "call-friend":
            // lifestyles://call-friend/{friendId} (Widget)
            guard let friendId = pathComponents.first,
                  let uuid = UUID(uuidString: friendId) else {
                print("❌ Geçersiz friend ID: \(pathComponents)")
                return
            }

            // Friend detay sayfasına git
            deepLinkRouter.friendId = friendId
            deepLinkRouter.shouldShowFriendDetail = true
            deepLinkRouter.activeTab = 1 // Contacts tab

        default:
            print("⚠️ Bilinmeyen deep link host: \(host)")
        }
    }

    /// İletişimi tamamlanmış olarak işaretle
    private func handleCompleteCall(friendId: UUID) {
        let context = sharedModelContainer.mainContext

        Task { @MainActor in
            // Friend'i bul
            let fetchDescriptor = FetchDescriptor<Friend>(
                predicate: #Predicate { $0.id == friendId }
            )

            guard let friends = try? context.fetch(fetchDescriptor),
                  let friend = friends.first else {
                print("❌ Friend bulunamadı: \(friendId)")
                return
            }

            // İletişim geçmişi ekle
            let history = ContactHistory(
                date: Date(),
                notes: "Widget'tan hızlı aksiyon ile tamamlandı",
                mood: nil
            )
            history.friend = friend
            context.insert(history)

            // Friend'i güncelle
            friend.lastContactDate = Date()

            // Kaydet
            do {
                try context.save()

                // Toast göster
                NotificationService.shared.showFriendToast(
                    friend: friend,
                    title: "İletişim Tamamlandı",
                    message: "\(friend.name) ile iletişim kaydedildi"
                )

                // Live Activity'yi sonlandır
                if #available(iOS 16.1, *) {
                    LiveActivityService.shared.endCallReminder(friendId: friendId.uuidString)
                }

            } catch {
                print("❌ Kayıt hatası: \(error)")
            }
        }
    }

    /// Hatırlatmayı ertele
    private func handleSnoozeReminder(friendId: UUID) {
        let context = sharedModelContainer.mainContext

        Task { @MainActor in
            // Friend'i bul
            let fetchDescriptor = FetchDescriptor<Friend>(
                predicate: #Predicate { $0.id == friendId }
            )

            guard let friends = try? context.fetch(fetchDescriptor),
                  let friend = friends.first else {
                print("❌ Friend bulunamadı: \(friendId)")
                return
            }

            // 10 dakika sonra yeni hatırlatma
            NotificationService.shared.scheduleCallReminder(for: friend, after: 10)

            print("⏰ Hatırlatma 10 dakika ertelendi: \(friend.name)")

            // Toast göster
            NotificationService.shared.showInfoToast(
                title: "Hatırlatma Ertelendi",
                message: "10 dakika sonra tekrar hatırlatılacak",
                emoji: "⏰"
            )

            // Mevcut Live Activity'yi sonlandır
            if #available(iOS 16.1, *) {
                LiveActivityService.shared.endCallReminder(friendId: friendId.uuidString)
            }
        }
    }

    // Konum takibini otomatik başlat
    private func initializeLocationTracking() {
        // Her Zaman izni var mı kontrol et
        guard PermissionManager.shared.hasAlwaysLocationPermission() else {
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
            service.startPeriodicTracking()
        } else {
            service.startPeriodicTracking()
        }
    }

    // Notification sistemini başlat
    private func initializeNotificationSystem() {
        // Notification sistemini setup et
        NotificationService.shared.initializeNotificationSystem()

        // ML-based notification sistemini başlat
        let context = sharedModelContainer.mainContext
        UserBehaviorAnalyzer.shared.configure(with: context)

        // Context awareness servisini başlat
        ContextualAwarenessService.shared.updateContext()

        // Priority engine'i başlat
        NotificationPriorityEngine.shared.startAutoManagement()

        // Deep link callback'i ayarla
        NotificationDelegate.shared.setDeepLinkHandler { [self] path, parameters in
            print("🔗 Deep link received: \(path)")
            deepLinkRouter.handle(path: path, parameters: parameters)
        }

        // User behavior tracking başlat
        NotificationScheduler.shared.analyzeUserBehavior()

        // Tüm friend hatırlatmalarını zamanla
        scheduleFriendReminders()

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
    }

    // Geçmiş LocationLog kayıtlarını migrate et
    private func migrateLocationLogs(context: ModelContext) {
        // Sadece bir kere çalışsın
        let migrationKey = "locationLogMigrationCompleted_v1"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }


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
                } else {
                }

                // Migration tamamlandı, bir daha çalıştırma
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: migrationKey)
                }

            } catch {
                // SwiftData hatası - silent fail, kullanıcı deneyimini bozma
                print("⚠️ LocationLog migration hatası: \(error.localizedDescription)")

                // Yine de migration'ı tamamlanmış say ki tekrar deneme
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: migrationKey)
                }
            }
        }
    }
}
