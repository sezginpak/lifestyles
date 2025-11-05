# 📱 Friends Widget - Kurulum Rehberi

## 📦 Oluşturulan Dosyalar

### ✅ Shared Dosyalar (Ana App + Widget Extension)
```
LifeStyles/Shared/
├── FriendWidgetData.swift          ✅ Widget veri modeli
└── WidgetDataService.swift         ✅ SwiftData → Widget converter
```

### ✅ Widget Extension Dosyaları
```
FriendsWidget/
├── FriendsWidgetBundle.swift       ✅ Widget bundle (main entry)
├── FriendsTimelineProvider.swift   ✅ Timeline provider
├── MediumFriendsWidget.swift       ✅ Medium widget UI
├── LockScreenWidgets.swift         ✅ Lock screen widgets
├── FriendsWidgetIntents.swift      ✅ App Intent'ler
└── Info.plist                      ✅ Widget metadata
```

### ✅ Ana Uygulama Güncellemeleri
```
✅ DeepLinkRouter.swift              - Widget URL handler eklendi
✅ LifeStylesApp.swift               - Deep link handler güncellendi
```

---

## 🛠️ Xcode'da Widget Extension Target'ı Ekleme

### Adım 1: Widget Extension Target'ı Oluştur

1. **Xcode'u Aç**
   ```
   open LifeStyles.xcodeproj
   ```

2. **Yeni Target Ekle**
   - Project Navigator'da **LifeStyles** projesine tıkla
   - **TARGETS** bölümünün altında **+** butonuna tıkla
   - **Widget Extension** seç
   - **Next** butonuna tıkla

3. **Target Ayarları**
   ```
   Product Name: FriendsWidget
   Team: (Senin Apple Developer Team'in)
   Organization Identifier: com.sezginpaksoy (veya kendi identifier'ın)
   Include Configuration Intent: ❌ İşaretleme (Static widget)
   ```

4. **Activate Scheme**
   - "Activate FriendsWidget scheme?" sorusuna **Cancel** de
   - (LifeStyles scheme'i ile çalışmaya devam edeceğiz)

### Adım 2: Xcode'un Oluşturduğu Dosyaları Sil

Xcode otomatik olarak bazı şablon dosyalar oluşturur. Bunları **DELETE** et:

```
FriendsWidget/
├── FriendsWidget.swift              ❌ SİL
├── FriendsWidgetBundle.swift        ❌ SİL (Bizim yazdığımız var)
├── FriendsWidgetLiveActivity.swift  ❌ SİL (Kullanmıyoruz)
└── AppIntent.swift                  ❌ SİL (Bizim yazdığımız var)
```

**SİLME NASIL YAPILIR:**
- Dosyaya sağ tıkla
- **Delete** seç
- **Move to Trash** seç

### Adım 3: Bizim Oluşturduğumuz Dosyaları Ekle

#### 3.1 FriendsWidget Klasörüne Dosyaları Taşı

Terminal'de şu komutları çalıştır:

```bash
cd /Users/sezginpaksoy/Desktop/Claude-Code/LifeStyles

# FriendsWidget klasörü zaten var, dosyalar içinde
ls -la FriendsWidget/
```

Göreceğin dosyalar:
- ✅ FriendsWidgetBundle.swift
- ✅ FriendsTimelineProvider.swift
- ✅ MediumFriendsWidget.swift
- ✅ LockScreenWidgets.swift
- ✅ FriendsWidgetIntents.swift
- ✅ Info.plist

#### 3.2 Xcode'da Dosyaları Target'a Ekle

1. **FriendsWidget klasörüne sağ tıkla**
2. **Add Files to "LifeStyles"...** seç
3. **FriendsWidget** klasörünü seç
4. **Options** kısmında:
   - ☑️ **Copy items if needed** (işaretle)
   - ☑️ **Create folder references** (seçili olsun)
   - **Add to targets:** sadece **FriendsWidget** seç (LifeStyles'ı KALDIR)
5. **Add** butonuna tıkla

#### 3.3 Shared Dosyaları Ekle

1. **LifeStyles/Shared** klasörüne sağ tıkla
2. **Show in Finder** seç
3. İki dosyayı gör:
   - FriendWidgetData.swift
   - WidgetDataService.swift

4. Her dosya için:
   - Xcode'da dosyaya tıkla
   - **File Inspector** (sağ panel) aç
   - **Target Membership** bölümünde:
     - ☑️ **LifeStyles** (ana app)
     - ☑️ **FriendsWidget** (widget extension)
   - İkisini de işaretle!

### Adım 4: Bundle Identifier ve Signing

1. **FriendsWidget Target'ına tıkla**
2. **Signing & Capabilities** sekmesine git
3. **Bundle Identifier** değiştir:
   ```
   com.sezginpaksoy.LifeStyles.FriendsWidget
   ```
4. **Team** seç (Apple Developer hesabın)
5. **Automatically manage signing** ✅ işaretle

### Adım 5: Build Settings

1. **FriendsWidget Target** → **Build Settings**
2. **Deployment Info** bölümünde:
   ```
   iOS Deployment Target: 17.0
   Supports Mac Catalyst: No
   ```

3. **Linked Frameworks** kontrol et:
   - WidgetKit
   - SwiftUI
   - SwiftData

### Adım 6: Friend Model'i Ekle

Widget'ın SwiftData modeline erişebilmesi için:

1. **LifeStyles/Models/Friend.swift** dosyasına tıkla
2. **File Inspector** (sağ panel)
3. **Target Membership**:
   - ☑️ **LifeStyles**
   - ☑️ **FriendsWidget**

Aynı işlemi şu modeller için de yap:
- ✅ ContactHistory.swift
- ✅ SpecialDate.swift
- ✅ Transaction.swift
- ✅ ContactFrequency.swift
- ✅ RelationshipType.swift

### Adım 7: App Group (CloudKit Paylaşımı)

Widget'ın ana app ile veri paylaşması için App Group gerekli:

1. **LifeStyles Target** → **Signing & Capabilities**
2. **+ Capability** → **App Groups** ekle
3. **App Groups** oluştur:
   ```
   group.com.sezginpaksoy.LifeStyles
   ```

4. **FriendsWidget Target** → **Signing & Capabilities**
5. **+ Capability** → **App Groups** ekle
6. **Aynı App Group'u seç:**
   ```
   group.com.sezginpaksoy.LifeStyles
   ```

### Adım 8: Build ve Test

1. **Scheme Seç:** LifeStyles (Ana uygulama)
2. **Build:** ⌘ + B
3. **Run:** ⌘ + R

Hatalar varsa:
- Import eksiklikleri → File'ları target'a ekle
- SwiftData hataları → Model dosyalarını FriendsWidget target'ına ekle

---

## 🎯 Widget'ı Test Etme

### Simulator'da Widget Ekleme

1. Uygulamayı çalıştır (⌘ + R)
2. **Home Screen'e** git
3. Boş alana **uzun bas**
4. **+** butonuna tıkla
5. **LifeStyles** ara
6. İki widget göreceksin:
   - **Arkadaşlarım** (Medium - Home Screen)
   - **Arkadaş Sayacı** (Lock Screen)

### Home Screen Widget (Medium)

1. **Arkadaşlarım** widget'ını seç
2. **Add Widget** tıkla
3. Widget'ta arkadaşların listelenir
4. Widget'a **tıkla** → Friend Detail'a gider

### Lock Screen Widget

1. **Lock Screen'e** git (⌘ + Shift + H → Kilit ekranı simüle et)
2. Lock Screen'e **uzun bas**
3. **Customize** tıkla
4. **Lock Screen** → **Add Widgets**
5. **LifeStyles** → **Arkadaş Sayacı** ekle
6. Üç boyut var:
   - **Circular:** Sayı + ikon
   - **Rectangular:** 2 arkadaş listesi
   - **Inline:** "3 arkadaş bekliyor 📞"

---

## 🔗 Deep Linking Test

Widget'tan ana uygulamaya geçişi test et:

### Test 1: Friend Detail'a Gitme
```swift
// Widget'ta arkadaş kartına tıkla
Link(destination: URL(string: "lifestyles://friend-detail/{friendId}")!) {
    // Kart UI
}
```

**Beklenen:** Contacts tab açılır, friend detail sayfası gösterilir

### Test 2: İletişim Tamamlama
```swift
// App Intent kullanarak
CompleteContactIntent(friendId: "xxx")
```

**Beklenen:** İletişim geçmişi eklenir, lastContactDate güncellenir

### Test 3: Telefon Açma
```swift
CallFriendIntent(friendId: "xxx", phoneNumber: "+90 555 123 4567")
```

**Beklenen:** Telefon uygulaması açılır

---

## 📊 Widget Timeline Güncelleme

Widget otomatik olarak **15 dakikada bir** güncellenir.

Manuel güncelleme için ana uygulamada:

```swift
import WidgetKit

// Widget'ı yenile
WidgetCenter.shared.reloadAllTimelines()
```

**Güncelleme Zamanları:**
- ✅ İletişim tamamlandığında
- ✅ Yeni arkadaş eklendiğinde
- ✅ Friend bilgileri güncellendiğinde

---

## 🐛 Sorun Giderme

### Problem: Widget görünmüyor

**Çözüm:**
1. Build başarılı mı kontrol et
2. FriendsWidget scheme'i de build et: `⌘ + B` (FriendsWidget seçili)
3. Simulator'ı yeniden başlat

### Problem: "Failed to fetch friends" hatası

**Çözüm:**
1. SwiftData model dosyaları FriendsWidget target'ına eklendi mi kontrol et
2. App Group doğru mu kontrol et
3. Console'da hata mesajlarını oku

### Problem: Deep link çalışmıyor

**Çözüm:**
1. URL Scheme ekli mi: `lifestyles://`
2. Info.plist → URL Types kontrol et
3. DeepLinkRouter'da handler ekli mi kontrol et

### Problem: Widget boş gösteriyor

**Çözüm:**
1. Ana uygulamada arkadaş var mı kontrol et
2. Arkadaşlardan en az biri `isImportant=true` veya `needsContact=true` olmalı
3. Widget timeline provider'daki filter'ı kontrol et

---

## ✨ Özellikler

### Medium Widget (Home Screen)
- ✅ 3-4 arkadaş listesi
- ✅ Emoji avatar
- ✅ "X gün geçti" / "X gün kaldı" badge
- ✅ Önem yıldızı
- ✅ Glassmorphism tasarım
- ✅ Tıklanabilir kartlar

### Lock Screen Widget
- ✅ **Circular:** Sayı + durum ikonu
- ✅ **Rectangular:** 2 arkadaş + durum
- ✅ **Inline:** "X arkadaş bekliyor"

### App Intent'ler
- ✅ Arkadaşı ara (telefon)
- ✅ Mesaj gönder
- ✅ İletişim tamamla
- ✅ Friend detail aç

### Deep Linking
- ✅ Widget → Friend Detail
- ✅ Widget → İletişim tamamlama
- ✅ Widget → Telefon açma

---

## 🚀 Sonraki Adımlar

1. **Build et:** `⌘ + B`
2. **Run et:** `⌘ + R`
3. **Widget ekle:** Home Screen + Lock Screen
4. **Test et:** Tıklamalar, deep link'ler
5. **CloudKit sync:** Cihazlar arası test

**Başarılar! 🎉**
