# LifeStyles Kurulum Rehberi

## ⚠️ Önemli: İzinleri Xcode'da Ayarlayın

Info.plist kaldırıldı çünkü iOS 17+ otomatik oluşturuyor. İzinleri manuel ekleyin:

## 📋 Adım Adım Kurulum

### 1. Xcode'da Projeyi Açın
```bash
open LifeStyles.xcodeproj
```

### 2. Target Seçin
- Sol panelde **LifeStyles** projesine tıklayın
- **TARGETS** altında **LifeStyles**'ı seçin

### 3. Info Tab'ına Gidin
- Üstteki tablardan **Info** sekmesine tıklayın

### 4. İzin Açıklamalarını Ekleyin

**Custom iOS Target Properties** bölümünde **+** butonuna tıklayarak ekleyin:

#### Privacy - Contacts Usage Description
```
LifeStyles, arkadaşlarınızla iletişim geçmişinizi takip etmek ve size hatırlatmalar göndermek için rehber erişimine ihtiyaç duyar.
```

#### Privacy - Location When In Use Usage Description
```
LifeStyles, size konum bazlı aktivite önerileri sunmak için konumunuza ihtiyaç duyar.
```

#### Privacy - Location Always Usage Description
```
LifeStyles, evde geçirdiğiniz süreyi takip edip size uygun zamanlarda dışarı çıkma önerileri sunmak için konumunuza ihtiyaç duyar.
```

#### Privacy - Location Always and When In Use Usage Description
```
LifeStyles, hayat kalitenizi artırmak için konum bazlı öneriler ve hatırlatmalar göndermek amacıyla konumunuzu takip eder.
```

### 5. Signing & Capabilities Ayarları

#### a) Team Seçin
- **Signing & Capabilities** sekmesine gidin
- **Team**: Kendi Apple Developer hesabınızı seçin
- **Bundle Identifier**: `com.sizinisim.LifeStyles` olarak değiştirin

#### b) iCloud Capability Ekleyin
- **+ Capability** butonuna tıklayın
- **iCloud** seçin
- ✅ **CloudKit** checkbox'ını işaretleyin
- Container otomatik oluşacak: `iCloud.com.sizinisim.LifeStyles`

#### c) Background Modes Ekleyin
- **+ Capability** → **Background Modes**
- ✅ **Location updates** işaretleyin
- ✅ **Background fetch** işaretleyin
- ✅ **Background processing** işaretleyin

### 6. Build Settings (Opsiyonel)
- **Build Settings** sekmesine gidin
- **Generate Info.plist File**: **YES** (otomatik açık olmalı)

### 7. Build & Run
```
Product → Run (Cmd + R)
```

---

## 🔧 Sorun Giderme

### "Multiple commands produce Info.plist" Hatası
✅ **ÇÖZÜLDÜ** - Manuel Info.plist silindi.

### "No such module 'SwiftData'" Hatası
- Deployment Target'ı kontrol edin: **iOS 17.0+** olmalı
- General → Deployment Info → iOS 17.0

### CloudKit Container Bulunamıyor
1. Signing & Capabilities → iCloud
2. Container'ı manuel seçin veya yeniden oluşturun
3. Bundle ID'nin doğru olduğundan emin olun

### Simulator'da Konum Çalışmıyor
1. Simulator → Features → Location
2. Custom Location seçin veya Apple kullanın

### İzinler Çıkmıyor
1. Simulator'ı temizleyin: Device → Erase All Content and Settings
2. Tekrar build edin

---

## ✅ Test Checklist

Build ettikten sonra test edin:

- [ ] Uygulama açılıyor
- [ ] Tab bar görünüyor (5 sekme)
- [ ] Dashboard istatistikleri gösteriliyor
- [ ] İletişim sekmesi açılıyor
- [ ] Konum izni isteniyor
- [ ] Bildirim izni isteniyor
- [ ] Rehber izni isteniyor

---

## 📱 TestFlight'a Yükleme

1. **Archive Oluştur**
   ```
   Product → Archive (Cmd + Shift + B)
   ```

2. **Distribute**
   - Window → Organizer
   - Archives sekmesi
   - **Distribute App**
   - TestFlight & App Store seçin
   - Upload

3. **TestFlight'tan İndir**
   - iPhone'da TestFlight uygulamasını açın
   - 5-10 dakika içinde görünecek

---

## 🎯 İlk Kullanım

1. **İzinleri Verin**
   - Rehber ✅
   - Konum (Her Zaman) ✅
   - Bildirimler ✅

2. **Ev Konumu Ayarlayın**
   - Aktivite sekmesi
   - "Mevcut Konumu Ev Olarak Ayarla"

3. **Rehber Senkronize Olsun**
   - İletişim sekmesine girin
   - Otomatik senkronize olacak

4. **İlk Hedef Ekleyin**
   - Hedefler sekmesi
   - + butonuna dokunun

---

Başarılar! 🚀
