# LifeStyles - Kişisel Yaşam Koçu

Hayat kalitenizi artırmak ve liderlik ruhunuzu geliştirmek için tasarlanmış iOS uygulaması.

## 🎯 Özellikler

### 📞 İletişim Takibi
- Rehber entegrasyonu
- Arama geçmişi takibi
- "X kişiyle Y gün konuşmadınız" hatırlatmaları
- Önemli kişilerle düzenli iletişim önerileri

### 📍 Konum Bazlı Öneriler
- GPS ile ev/iş konumu takibi
- "Evden çık, aktivite yap" bildirimleri
- Konum bazlı aktivite önerileri
- Geofencing ile otomatik tespit

### 🎯 Hedef ve Alışkanlık Takibi
- Kişisel hedef belirleme
- İlerleme takibi
- Alışkanlık seri takibi
- Motivasyon bildirimleri

### 📊 Dashboard
- Günlük istatistikler
- Genel özet
- Hızlı erişim
- Motivasyon mesajları

## 🛠️ Teknik Stack

- **SwiftUI**: Modern iOS UI framework
- **SwiftData**: Veri yönetimi
- **CloudKit**: iCloud senkronizasyonu (otomatik yedekleme)
- **CoreLocation**: Konum servisleri
- **Contacts Framework**: Rehber entegrasyonu
- **UserNotifications**: Push bildirimleri
- **CallKit**: Arama takibi

## 📱 Gereksinimler

- iOS 17.0+
- Xcode 15.0+
- Apple Developer hesabı (TestFlight için)

## 🚀 Kurulum

### 1. Xcode'da Açın
\`\`\`bash
open LifeStyles.xcodeproj
\`\`\`

### 2. Bundle ID Değiştirin
- Target → General → Bundle Identifier
- \`com.sizinisim.LifeStyles\` olarak değiştirin

### 3. Signing & Capabilities
- Team: Kendi Apple Developer hesabınızı seçin
- Signing: Automatically manage signing ✅
- **+ Capability** → **iCloud** ekleyin
  - ✅ CloudKit
  - Container: \`iCloud.com.sizinisim.LifeStyles\`

### 4. Info.plist Güncelleyin
Info.plist dosyasında CloudKit container adını güncelleyin:
\`\`\`xml
<key>iCloud.com.yourname.LifeStyles</key>
\`\`\`
↓
\`\`\`xml
<key>iCloud.com.sizinisim.LifeStyles</key>
\`\`\`

### 5. Build & Run
- Simulator veya gerçek cihazda çalıştırın
- İlk çalıştırmada izinleri verin

## 📦 TestFlight'a Yükleme

\`\`\`bash
# 1. Archive oluştur
Product → Archive

# 2. Distribute App
→ TestFlight & App Store
→ Upload

# 3. TestFlight'tan indir
5-10 dakika içinde TestFlight'ta görünür
\`\`\`

## 📂 Proje Yapısı

\`\`\`
LifeStyles/
├── Models/              # SwiftData modelleri
│   ├── Contact.swift
│   ├── CallLog.swift
│   ├── LocationLog.swift
│   ├── Goal.swift
│   ├── Habit.swift
│   └── ActivitySuggestion.swift
│
├── ViewModels/          # MVVM ViewModels
│   ├── DashboardViewModel.swift
│   ├── ContactsViewModel.swift
│   ├── LocationViewModel.swift
│   └── GoalsViewModel.swift
│
├── Views/               # SwiftUI Views
│   ├── Dashboard/
│   ├── Contacts/
│   ├── Location/
│   ├── Goals/
│   └── Settings/
│
├── Services/            # Business Logic
│   ├── ContactsService.swift
│   ├── LocationService.swift
│   ├── NotificationService.swift
│   └── CallLogService.swift
│
└── Utilities/
    └── Extensions/
\`\`\`

## 🔐 İzinler

Uygulama aşağıdaki izinleri kullanır:

- **Rehber Erişimi**: İletişim takibi için
- **Konum (Her Zaman)**: Ev/dışarı tespiti için
- **Bildirimler**: Hatırlatmalar için
- **Arka Plan Konum**: Sürekli takip için

## 💾 Veri Yedekleme

### Otomatik (iCloud)
- SwiftData + CloudKit entegrasyonu
- Telefonlar arası otomatik senkronizasyon
- iCloud hesabınızla şifrelenmiş depolama

### Manuel (Planlanan)
- JSON export/import
- Ayarlar → Yedek Al/Geri Yükle

## 🎨 Özelleştirme

### Ev Konumu Ayarlama
1. Aktivite sekmesine gidin
2. "Mevcut Konumu Ev Olarak Ayarla" butonuna dokunun

### Bildirim Ayarları
1. Ayarlar sekmesine gidin
2. Bildirim tercihlerini ayarlayın

### Kişi Hatırlatmaları
1. İletişim sekmesinden kişi seçin
2. Hatırlatma aralığını ayarlayın

## 🐛 Bilinen Kısıtlamalar

### iOS Kısıtlamaları
- **Arama Geçmişi**: iOS doğrudan arama geçmişine erişime izin vermez
  - CallKit ile gerçek zamanlı arama yakalama
  - Manuel kayıt ekleme özelliği

### Pil Kullanımı
- Arka planda konum takibi pil tüketir
- Geofencing ile optimize edilmiştir

## 📝 Yapılacaklar (TODO)

- [ ] Arama geçmişi manuel ekleme UI'ı
- [ ] Widget desteği
- [ ] Apple Watch uygulaması
- [ ] Veri export/import UI'ı
- [ ] Dark mode optimizasyonu
- [ ] Grafikler ve analizler
- [ ] Sosyal medya entegrasyonu

## 🤝 Katkıda Bulunma

Bu kişisel bir proje olduğundan şu anda katkı kabul edilmemektedir.

## 📄 Lisans

Kişisel kullanım için tasarlanmıştır.

## 📧 İletişim

Sorularınız için: [email@example.com]

---

**Not**: Bu uygulama kişisel kullanım için tasarlanmıştır. Gizlilik odaklıdır ve verileriniz sadece sizin cihazınızda ve iCloud'unuzda saklanır.
