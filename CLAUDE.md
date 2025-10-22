# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Proje Hakkında

LifeStyles, hayat kalitesini artırmak için tasarlanmış bir iOS uygulamasıdır. İletişim takibi, konum bazlı öneriler, hedef ve alışkanlık yönetimi sunar.

## Geliştirme Komutları

### Build ve Çalıştırma
```bash
# Xcode'da aç
open LifeStyles.xcodeproj

# Simulator'da çalıştır (Xcode içinde)
# Product → Run (Cmd + R)

# Build (Xcode içinde)
# Product → Build (Cmd + B)
```

### TestFlight Archive
```bash
# Archive oluştur (Xcode içinde)
# Product → Archive (Cmd + Shift + B)
```

## Mimari ve Yapı

### MVVM Pattern
Proje MVVM (Model-View-ViewModel) mimarisini kullanır:

- **Models/**: SwiftData modelleri (`@Model` ile işaretli)
- **ViewModels/**: Observable sınıflar, view logic ve state yönetimi
- **Views/**: SwiftUI view'ları (Dashboard, Contacts, Location, Goals, Settings, Onboarding)
- **Services/**: Business logic ve platform API'leri (Contacts, Location, Notifications, CallLog, PermissionManager)

### SwiftData + CloudKit
- Tüm modeller `LifeStylesApp.swift:14` içinde `ModelContainer` ile kayıtlı
- CloudKit senkronizasyonu `ModelConfiguration(cloudKitDatabase: .automatic)` ile aktif
- Schema değişikliklerinde `LifeStylesApp.swift:15` içindeki `Schema([...])` dizisini güncelle

### Model İlişkileri
- `Friend` ↔ `ContactHistory`: One-to-many cascade delete ile iletişim geçmişi takibi
- `Habit` ↔ `HabitCompletion`: One-to-many inverse relationship
- İlişkilerde `@Relationship` attribute'unu kullan, `deleteRule` belirt

### View Hierarchy
Ana yapı `ContentView.swift:12` içinde `TabView` ile 5 tab:
1. DashboardView - Genel özet ve istatistikler
2. FriendsView - Arkadaş yönetimi ve iletişim takibi
   - FriendDetailView - Detaylı arkadaş ekranı (geçmiş, notlar, istatistikler)
3. LocationView - Konum bazlı aktivite önerileri
4. GoalsView - Hedef ve alışkanlık yönetimi
5. SettingsView - Uygulama ayarları

### Service Layer Pattern
Servisler singleton pattern ile (`shared` static property):
- `LocationService` - CLLocationManager wrapper
- `NotificationService` - UNUserNotificationCenter wrapper, Friend bildirimleri
- `PermissionManager` - Merkezi izin yönetimi

Servisler `@Observable` macro ile işaretli, izin yönetimi ve async/await kullanır.

## Önemli Notlar

### Onboarding Flow
İlk açılışta modern onboarding ekranı gösterilir:
- 4 sayfa: Hoş geldiniz, İletişim, Konum, Bildirimler
- Her izin için ayrı sayfa ve açıklama
- `OnboardingViewModel.hasCompletedOnboarding()` ile kontrol
- `LifeStylesApp.swift:13` içinde durum yönetimi

### İzinler
İzin açıklamaları `Info.plist` dosyasında:
- NSContactsUsageDescription - Rehber erişimi
- NSLocationWhenInUseUsageDescription - Konum (kullanım sırasında)
- NSLocationAlwaysUsageDescription - Konum (her zaman)
- NSLocationAlwaysAndWhenInUseUsageDescription - Konum (karma)

`PermissionManager.swift` servisi tüm izinleri merkezi olarak yönetir.

### Capabilities
Xcode → Target → Signing & Capabilities:
- iCloud (CloudKit enabled)
- Background Modes (Location updates, Background fetch, Background processing)

### Bundle ID ve Team
Yeni kurulumda:
1. Bundle ID değiştir: `com.sizinisim.LifeStyles`
2. Apple Developer Team seçilmeli
3. CloudKit container otomatik oluşturulur

### iOS Sürüm Gereksinimleri
- Minimum iOS 17.0
- SwiftData ve CloudKit için gerekli
- Deployment Target: iOS 17.0+

### Pil Optimizasyonu
- Arka plan konum takibi pil tüketir
- Geofencing ile optimize edilmiş
- LocationService'de `allowsBackgroundLocationUpdates` kontrol ediliyor

### Konum Takibi ve Harita Görünümü
- **Periyodik Kayıt**: 10 saniyede bir otomatik konum kaydı (TEST modu)
- **Reverse Geocoding**: Koordinattan adres bilgisi otomatik alınır
- **Harita Görünümü**: MapKit ile interaktif harita
- **Polyline Rota**: Konumlar arası otomatik çizgi çekimi
- **Rota İstatistikleri**: Toplam mesafe, nokta sayısı
- **Başlangıç/Bitiş**: Özel pinler (arrival/flag.checkered)
- **Liste/Harita Geçişi**: Segmented control ile görünüm değiştirme
- **Detaylı Kartlar**: Konum detayları, adres, doğruluk, rota sırası
- **Rota Toggle**: Çizgiyi açıp kapatabilme
- Production için: `LocationService.swift:27` içinde 15 dakika kullan

### Arkadaş ve İletişim Takibi
Uygulama arkadaşlarla düzenli iletişimi takip eder:
- **Friend Modeli**: İsim, telefon, iletişim sıklığı, önem durumu
- **ContactHistory Modeli**: Her iletişim kaydı, tarih, notlar, ruh hali
- **FriendDetailView**: Detaylı arkadaş ekranı
  - İletişim geçmişi timeline'ı
  - Düzenlenebilir notlar bölümü
  - İstatistikler (toplam iletişim, geçen süre)
  - Hızlı eylemler (ara, mesaj, iletişim tamamla)
- **Otomatik Hatırlatmalar**: İletişim süresi geçince bildirim
- **Emoji Avatar**: Her arkadaş için özel emoji avatar seçilebilir

## Kod Standartları

### SwiftData Model Oluşturma
```swift
@Model
final class YeniModel {
    var id: UUID
    var createdAt: Date

    // Relationship varsa:
    @Relationship(deleteRule: .cascade, inverse: \DigerModel.property)
    var iliskiliNesneler: [DigerModel]?

    init(...) { ... }
}
```

### ViewModel Pattern
```swift
@Observable
class YeniViewModel {
    private let service: SomeService
    var state: ViewState = .idle

    init(service: SomeService = .shared) {
        self.service = service
    }

    func fetchData() async {
        // async/await ile veri çek
    }
}
```

### View ile ViewModel Bağlama
```swift
struct YeniView: View {
    @State private var viewModel = YeniViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        // UI kodu
    }
}
```

## Test ve Debugging

### Simulator'da Test
```bash
# Konum testi için
Simulator → Features → Location → Apple/Custom Location

# İzinleri sıfırla
Device → Erase All Content and Settings
```

### İzin Sorunları
Eğer izinler çıkmıyorsa:
1. Info tab'ında izin açıklamaları ekli mi kontrol et
2. Simulator'ı sıfırla
3. Clean Build Folder (Cmd + Shift + K)
4. Rebuild

### CloudKit Debugging
- Xcode Console'da CloudKit logları kontrol et
- iCloud hesabı gerekli (Settings → Apple ID → iCloud)
- Container ID Bundle ID ile eşleşmeli

## Deployment

### TestFlight Yükleme
1. Archive oluştur: Product → Archive
2. Organizer → Distribute App
3. TestFlight & App Store → Upload
4. 5-10 dakika içinde TestFlight'ta görünür

### Bundle Version
Her TestFlight yüklemesinde version veya build number artırılmalı:
- General → Identity → Version / Build
