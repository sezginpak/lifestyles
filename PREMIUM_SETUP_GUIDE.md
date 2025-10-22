# 🔥 Premium Abonelik Kurulum Rehberi

## 📊 Mevcut Durum Analizi

### ✅ Halihazırda Var Olanlar

1. **PurchaseManager.swift**
   - StoreKit 2 entegrasyonu
   - Aylık abonelik desteği
   - Transaction verification
   - Auto-renewable subscription tracking
   - Restore purchases özelliği
   - ⚠️ Şu anda `isPremium = true` (TEST MODU)

2. **ProductIDs.swift**
   - Product ID tanımı: `com.lifestyles.premium.monthly`
   - Premium özellikler listesi:
     - ✨ Limitsiz AI Chat
     - 📊 Gelişmiş Analitikler
     - ⭐ Öncelikli Destek
     - 👑 Premium Rozeti

3. **LifeStyles.storekit**
   - StoreKit Configuration dosyası mevcut
   - Subscription group oluşturulmuş
   - ⚠️ Eksik: Tam ürün konfigürasyonu

4. **PremiumPaywallView.swift**
   - Modern premium paywall UI
   - Feature showcase
   - Purchase button
   - Restore purchases
   - Error handling

5. **Premium Entegrasyonları**
   - ✅ SettingsView: Premium badge gösterimi
   - ✅ FriendAIChatView: AI message limit kontrolü
   - ✅ AIUsageManager: Günlük mesaj limitleri
     - Free: 10 mesaj/gün
     - Premium: Limitsiz

---

## ❌ Eksikler ve Yapılması Gerekenler

### 1. StoreKit Configuration Tamamlanması

**Dosya:** `LifeStyles.storekit`

**Mevcut Durum:**
```json
{
  "products": [],  // ← BOŞ!
  "subscriptionGroups": [
    {
      "subscriptions": [
        {
          "productID": "com.lifestyles.premium.monthly",
          "displayPrice": "39.99",
          "recurringSubscriptionPeriod": "P1M"
        }
      ]
    }
  ]
}
```

**Yapılması Gereken:**
- Ürün bilgileri doldurulmalı
- Fiyatlandırma ayarları yapılmalı
- Lokalizasyon eklenmel (TR, EN)

---

### 2. Xcode Ayarları

#### A) Signing & Capabilities
```
Target → LifeStyles → Signing & Capabilities
```

**Eklenecek Capability:**
- ✅ iCloud (Mevcut)
- ✅ Background Modes (Mevcut)
- ➕ **In-App Purchase** (EKLENMELİ!)

**Adımlar:**
1. `+ Capability` tıkla
2. "In-App Purchase" ara ve ekle
3. Otomatik entitlement eklenir

#### B) StoreKit Testing
```
Product → Scheme → Edit Scheme
```

**Configuration:**
1. Run → Options sekmesi
2. StoreKit Configuration → `LifeStyles.storekit` seç
3. Bu ayar ile simulator'da test edebilirsin

---

### 3. App Store Connect Kurulumu

**⚠️ ÖNEMLİ:** Gerçek satın alma için gerekli!

#### Adım 1: App Kaydı
```
App Store Connect → My Apps → + → New App
```
- Platform: iOS
- Name: LifeStyles
- Primary Language: Turkish
- Bundle ID: `com.{yourname}.LifeStyles`
- SKU: Benzersiz ID (örn: LIFESTYLES001)

#### Adım 2: In-App Purchase Oluşturma
```
App Store Connect → Your App → Monetization → In-App Purchases
```

**Yeni Subscription Oluştur:**
- Type: **Auto-Renewable Subscription**
- Reference Name: `Premium Monthly`
- Product ID: `com.lifestyles.premium.monthly`
- Subscription Group: `Premium` (yeni oluştur)

**Fiyatlandırma:**
- Base Price: ₺39.99 (TRY)
- Availability: All countries

**Lokalizasyon (Türkçe):**
- Display Name: `Premium Aylık`
- Description: `Sınırsız AI chat, gelişmiş analitikler ve öncelikli destek`

**Lokalizasyon (İngilizce):**
- Display Name: `Premium Monthly`
- Description: `Unlimited AI chat, advanced analytics, and priority support`

#### Adım 3: Subscription Duration
- Duration: **1 Month**
- Free Trial: (İsteğe bağlı) 7 gün
- Introductory Offer: (İsteğe bağlı) İlk ay %50 indirim

#### Adım 4: Review Information
- Screenshot: Premium ekranın ekran görüntüsü
- Review Notes: Test hesabı bilgileri

---

### 4. Test Hesapları

#### Sandbox Test Kullanıcısı Oluşturma
```
App Store Connect → Users and Access → Sandbox → Testers
```

**Test Kullanıcısı Ekle:**
- Email: test@example.com (gerçek email olmamalı)
- Password: Test123!
- Country: Turkey
- Verify email (gelen linke tıkla)

#### Simulator'da Test
1. Settings → App Store → Sandbox Account
2. Test kullanıcısı ile giriş yap
3. Uygulamayı çalıştır
4. Premium satın al → Test kullanıcısı ile onayla
5. **ÜCRETSİZ** (Sandbox'ta gerçek para ödenmez!)

---

## 🚀 Kullanım Senaryoları

### Senaryo 1: AI Chat Limiti

**Free User:**
```swift
// AIUsageManager.swift
func canSendMessage(isPremium: Bool) -> Bool {
    if isPremium {
        return true  // Limitsiz
    }

    let today = Calendar.current.startOfDay(for: Date())
    let count = dailyUsage[today] ?? 0
    return count < 10  // Günlük 10 mesaj
}
```

**Kullanım:**
```swift
// FriendAIChatView.swift
let canSend = usageManager.canSendMessage(isPremium: purchaseManager.isPremium)

if !canSend {
    // Paywall göster
    showPremiumPaywall = true
}
```

---

### Senaryo 2: Gelişmiş Analitikler

**Eklenebilecek Özellik:**
```swift
// MoodAnalyticsView.swift
if !purchaseManager.isPremium {
    // Basic istatistikler
    BasicStatsView()
} else {
    // Premium: Detaylı trendler, heatmap, correlations
    AdvancedAnalyticsView()
    MoodCorrelationView()
    PredictiveInsightsView()
}
```

---

### Senaryo 3: Premium Badge

**Eklenebilecek Özellik:**
```swift
// SettingsView.swift
HStack {
    Text(user.name)
        .font(.title2)
        .fontWeight(.bold)

    if purchaseManager.isPremium {
        Image(systemName: "crown.fill")
            .foregroundStyle(.yellow)
            .font(.caption)
    }
}
```

---

## 🔒 Premium Feature Gate Örnekleri

### 1. Journal AI Analizi (Eklenebilir)
```swift
// JournalEditorView.swift
Button("AI ile Geliştir") {
    if purchaseManager.isPremium {
        // AI önerileri göster
        analyzeWithAI()
    } else {
        // Paywall göster
        showPremiumPaywall = true
    }
}
```

### 2. Konum Geçmişi Detayları (Eklenebilir)
```swift
// LocationHistoryView.swift
if purchaseManager.isPremium {
    // Son 90 gün
    LocationHistoryDetailView(days: 90)
} else {
    // Son 7 gün + upgrade banner
    VStack {
        LocationHistoryDetailView(days: 7)
        UpgradeToPremiumBanner()
    }
}
```

### 3. Custom Themes (Eklenebilir)
```swift
// SettingsView.swift
if purchaseManager.isPremium {
    ThemePickerView()
} else {
    LockedFeatureCard(feature: "Özel Temalar")
        .onTapGesture {
            showPremiumPaywall = true
        }
}
```

---

## 📱 Test Adımları

### Local Testing (Simulator)

1. **StoreKit Config Etkinleştir**
   ```
   Product → Scheme → Edit Scheme → Run → Options
   StoreKit Configuration: LifeStyles.storekit
   ```

2. **Test Modu Kapat**
   ```swift
   // PurchaseManager.swift - Line 23-25
   var isPremium: Bool {
       // return true  // ← YORUM SAT YAP
       subscriptionStatus == .premium
   }
   ```

3. **Uygulamayı Çalıştır**
   - Settings → Premium'a tıkla
   - "Upgrade to Premium" butonu
   - Satın al → StoreKit popup
   - Onayla → ✅ Premium aktif

4. **Özellikleri Test Et**
   - AI Chat → 10 mesajdan fazla gönder
   - Settings → Premium badge görünür mü?

### Production Testing (TestFlight)

1. **Archive Oluştur**
   ```
   Product → Archive
   ```

2. **TestFlight'a Upload**
   ```
   Organizer → Distribute App → TestFlight
   ```

3. **Sandbox Test Kullanıcısı**
   - iPhone Settings → App Store → Sandbox Account
   - Test kullanıcısı ile giriş

4. **Gerçek Satın Alma Testi**
   - Premium satın al
   - Test kullanıcısı onayı
   - Transaction başarılı mı kontrol et

---

## 🐛 Debugging

### Transaction Logları
```swift
// PurchaseManager.swift
print("✅ Products loaded: \(products.count)")
print("📊 Subscription Status: \(subscriptionStatus.rawValue)")
print("✅ Purchase successful: \(product.id)")
```

### Xcode Console Filtreleri
```
StoreKit
Transaction
Purchase
Subscription
```

### Yaygın Hatalar

**Error 1: "Cannot connect to iTunes Store"**
- Çözüm: StoreKit Config aktif mi kontrol et

**Error 2: "Product not found"**
- Çözüm: Product ID'ler eşleşiyor mu?
  - ProductID.swift: `com.lifestyles.premium.monthly`
  - LifeStyles.storekit: `productID` aynı mı?

**Error 3: "Transaction failed"**
- Çözüm: Sandbox test kullanıcısı ile mi test ediyorsun?

---

## 📋 Checklist: Production'a Hazırlık

### Kod Tarafı
- [ ] `isPremium` test modu kapalı (line 23-25)
- [ ] Product ID'ler doğru
- [ ] Error handling eksiksiz
- [ ] Transaction verification aktif
- [ ] Analytics tracking (optional)

### App Store Connect
- [ ] App kayıtlı
- [ ] In-App Purchase oluşturulmuş
- [ ] Fiyatlandırma ayarlanmış
- [ ] Lokalizasyon tamamlanmış (TR + EN)
- [ ] Review notes ve screenshots hazır

### Xcode
- [ ] In-App Purchase capability eklendi
- [ ] Signing & Team ID doğru
- [ ] Bundle ID App Store Connect ile eşleşiyor
- [ ] StoreKit Config tamamlanmış

### Test
- [ ] Simulator'da satın alma başarılı
- [ ] TestFlight'ta satın alma başarılı
- [ ] Restore purchases çalışıyor
- [ ] Premium özellikler gated
- [ ] Free user limits doğru çalışıyor

---

## 💡 Premium Feature Önerileri

### Yakında Eklenebilecekler

1. **AI Journal Önerileri** 👑
   - Free: 3 öneri/gün
   - Premium: Limitsiz

2. **Mood Tahmin Motoru** 📈
   - Free: Basic trend
   - Premium: ML-based predictions

3. **Custom Journal Templates** 📝
   - Free: 3 varsayılan template
   - Premium: Custom template oluşturma

4. **Data Export** 💾
   - Free: Son 30 gün
   - Premium: Tüm geçmiş + PDF/CSV export

5. **Multi-Device Sync** ☁️
   - Free: Tek cihaz
   - Premium: Sınırsız cihaz sync

6. **Premium Themes** 🎨
   - Free: Light/Dark
   - Premium: 10+ custom theme

---

## 🔗 Faydalı Linkler

- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [Auto-Renewable Subscriptions Guide](https://developer.apple.com/app-store/subscriptions/)
- [Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_in_xcode)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

## 📞 Destek

Sorun yaşarsan:
1. Console logları kontrol et
2. Transaction.updates'i izle
3. Sandbox test kullanıcısı ile tekrar dene
4. App Store Connect status'u kontrol et

---

**Son Güncelleme:** 22 Ekim 2025
**Versiyon:** 1.0
