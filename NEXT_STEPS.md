# 🚀 App Store'a Yüklemeden Önce - SON ADIMLAR

## ✅ Tamamlanan İşler

- [x] API key gitignore'a eklendi
- [x] Privacy Policy oluşturuldu (docs/privacy.html)
- [x] Terms of Service oluşturuldu (docs/terms.html)
- [x] GitHub Pages kurulum rehberi hazırlandı
- [x] Debug logları temizlendi
- [x] Subscription sistemi test edildi
- [x] In-App Purchase entitlements eklendi

## 📋 Şimdi Yapılacaklar

### 1. API KEY GÜVENLİĞİ (ÇOK ÖNEMLİ! ⚠️)

```bash
# SecureAPIKeyManager.swift'in tracked olmadığını doğrula:
git status | grep SecureAPIKeyManager

# Eğer görünüyorsa:
git rm --cached LifeStyles/Services/AI/Core/SecureAPIKeyManager.swift
git commit -m "chore: Remove API key from tracking"
```

### 2. GITHUB PAGES KURULUMU (5 dakika)

```bash
# 1. Değişiklikleri commit et
git add docs/
git add .gitignore
git add GITHUB_PAGES_SETUP.md
git add update_legal_urls.sh
git commit -m "feat: Add legal pages for App Store"
git push origin main

# 2. GitHub'da Pages'i aktif et:
#    Settings → Pages → Source: main branch, /docs folder → Save

# 3. 2-3 dakika bekle, sonra URL'i test et:
#    https://KULLANICI_ADIN.github.io/LifeStyles/privacy.html
```

### 3. URL'LERİ GÜNCELLE

```bash
# Otomatik güncelleme:
./update_legal_urls.sh

# GitHub kullanıcı adını gir
# Değişiklikleri kontrol et:
git diff LifeStyles/Views/Premium/PremiumPaywallView.swift
git diff LifeStyles/Views/Settings/SettingsView.swift

# Commit et:
git add LifeStyles/Views/Premium/PremiumPaywallView.swift
git add LifeStyles/Views/Settings/SettingsView.swift
git commit -m "feat: Update legal URLs to GitHub Pages"
git push
```

### 4. APP STORE CONNECT - SUBSCRIPTION OLUŞTUR

```
1. https://appstoreconnect.apple.com → Giriş yap

2. My Apps → LifeStyles → Features → In-App Purchases

3. "+" → Auto-Renewable Subscriptions

4. Subscription Group oluştur:
   - Name: "Premium"

5. Subscription ekle:
   - Reference Name: Premium Monthly
   - Product ID: com.lifestyles.premium.monthly  ⚠️ AYNI OLMALI
   - Duration: 1 Month

6. Pricing:
   - Türkiye: ₺39,99/ay
   - Diğer ülkeler: Auto-generate

7. Localization (Türkçe):
   - Display Name: Premium Aylık
   - Description: Sınırsız AI chat, gelişmiş analitikler ve öncelikli destek

8. Review Information:
   - Screenshot: Paywall ekranından
   - Review Notes: "Sandbox ile test edin"

9. Submit for Review
```

### 5. APP STORE CONNECT - APP PRIVACY

```
App Information → App Privacy

Data Types:
✅ Contact Info - İsim, telefon (Rehber)
✅ Location - Precise location (Konum takibi)
✅ User Content - Journal, mood entries
✅ Identifiers - User ID (CloudKit)

Her biri için:
- Purpose: App Functionality
- Linked to User: Yes
- Used for Tracking: No
```

### 6. APP STORE CONNECT - APP INFORMATION

```
Privacy Policy URL:
https://KULLANICI_ADIN.github.io/LifeStyles/privacy.html

App Store Metadata:
- Name: LifeStyles - Life Quality Tracker
- Subtitle: Hayat Kaliteni Artır
- Keywords: life,quality,tracker,habits,mood,journal,ai
- Description: (Hazır metin PREMIUM_SETUP_GUIDE.md'de)
```

### 7. TESTFLIGHT YÜKLEME (Şiddetle Tavsiye!)

```bash
# Xcode'da:
1. Product → Archive (Cmd + Shift + B)
2. Organizer → Distribute App
3. TestFlight & App Store → Upload
4. Bekle (5-10 dakika)

# TestFlight'ta test et:
1. App Store Connect → TestFlight → LifeStyles
2. Internal Testing → Add Tester (kendin)
3. TestFlight uygulamasından indir
4. Test et:
   - Subscription satın alma
   - Restore purchases
   - Tüm özellikler
   - 2-3 gün kullan
```

### 8. APP STORE SUBMISSION

```
✅ Kontrol Listesi:

ZORUNLU:
[ ] Privacy Policy URL çalışıyor
[ ] Terms URL çalışıyor
[ ] Subscription App Store Connect'te oluşturuldu
[ ] App Privacy bildirildi
[ ] Screenshots hazır (3+ ekran, 3 boyut)
[ ] Metadata tamamlandı

ÖNERİLEN:
[ ] TestFlight'ta 2-3 gün test edildi
[ ] Sandbox satın alma test edildi
[ ] Farklı cihazlarda test edildi
[ ] Beta tester feedback alındı

OPSIYONEL:
[ ] App Preview video
[ ] Promotional text
[ ] Support URL
```

## 🎯 Hızlı Akış (Minimum)

Eğer hızlı ilerlemek istersen:

```bash
# 1. API key kontrol
git status | grep SecureAPIKeyManager

# 2. GitHub Pages
git add docs/ .gitignore
git commit -m "feat: Add legal pages"
git push
# GitHub Settings → Pages → Enable

# 3. URL güncelle
./update_legal_urls.sh
git add LifeStyles/Views/
git commit -m "feat: Update legal URLs"
git push

# 4. Subscription oluştur (App Store Connect)
# 5. Archive & Upload
# 6. Submit for Review
```

## 📞 İletişim

Sorular için:
- GitHub Issues: https://github.com/KULLANICI_ADIN/LifeStyles/issues
- E-posta: support@lifestyles.app

## 🎉 Başarılar!

Her şey hazır! App Store'da görüşmek üzere 🚀
