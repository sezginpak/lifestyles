# GitHub Pages Kurulum Rehberi

Privacy Policy ve Terms of Service sayfalarını GitHub Pages üzerinden yayınlamak için adım adım rehber.

## 🚀 Hızlı Kurulum (5 Dakika)

### 1. GitHub'a Push

```bash
# ⚠️ ÖNEMLİ: Önce SecureAPIKeyManager.swift dosyasını commit'leMe!
# .gitignore zaten eklendi, ama emin olmak için:

git status

# Eğer SecureAPIKeyManager.swift göründüyse:
git restore --staged LifeStyles/Services/AI/Core/SecureAPIKeyManager.swift

# Şimdi docs klasörünü commit et
git add docs/
git add .gitignore
git commit -m "feat: Add privacy policy and terms of service pages"
git push origin main
```

### 2. GitHub Pages'i Aktif Et

1. GitHub reposuna git: `https://github.com/KULLANICI_ADIN/LifeStyles`
2. **Settings** sekmesine tıkla
3. Sol menüden **Pages** seç
4. **Source** altında:
   - Branch: `main`
   - Folder: `/docs`
   - **Save** butonuna tıkla

### 3. URL'leri Kontrol Et (2-3 dakika sonra)

Sayfalar şu URL'lerde yayına girecek:

```
https://KULLANICI_ADIN.github.io/LifeStyles/
https://KULLANICI_ADIN.github.io/LifeStyles/privacy.html
https://KULLANICI_ADIN.github.io/LifeStyles/terms.html
```

### 4. URL'leri Uygulamada Güncelle

#### A. PremiumPaywallView.swift

```swift
// Dosya: LifeStyles/Views/Premium/PremiumPaywallView.swift
// Satır: 112-114

// Eski:
Link("Gizlilik Politikası", destination: URL(string: "https://lifestyles.app/privacy")!)
Link("Kullanım Koşulları", destination: URL(string: "https://lifestyles.app/terms")!)

// Yeni (KULLANICI_ADIN değiştir):
Link("Gizlilik Politikası", destination: URL(string: "https://KULLANICI_ADIN.github.io/LifeStyles/privacy.html")!)
Link("Kullanım Koşulları", destination: URL(string: "https://KULLANICI_ADIN.github.io/LifeStyles/terms.html")!)
```

#### B. SettingsView.swift

```swift
// Dosya: LifeStyles/Views/Settings/SettingsView.swift
// Satır: 296, 304

// Eski:
Link(destination: URL(string: "https://example.com/privacy")!) {
Link(destination: URL(string: "https://example.com/terms")!) {

// Yeni (KULLANICI_ADIN değiştir):
Link(destination: URL(string: "https://KULLANICI_ADIN.github.io/LifeStyles/privacy.html")!) {
Link(destination: URL(string: "https://KULLANICI_ADIN.github.io/LifeStyles/terms.html")!) {
```

### 5. Test Et

```bash
# Tarayıcıda aç:
open https://KULLANICI_ADIN.github.io/LifeStyles/privacy.html
open https://KULLANICI_ADIN.github.io/LifeStyles/terms.html

# Mobilde test et:
# Uygulamada Settings → Privacy Policy / Terms tıkla
# Sayfaların açıldığını doğrula
```

## 📋 Güvenlik Kontrol Listesi

### ⚠️ Push Öncesi Zorunlu Kontroller

```bash
# 1. SecureAPIKeyManager.swift tracked değil mi kontrol et:
git status | grep SecureAPIKeyManager

# Eğer görünüyorsa:
git rm --cached LifeStyles/Services/AI/Core/SecureAPIKeyManager.swift

# 2. .gitignore doğru mu kontrol et:
cat .gitignore | grep SecureAPIKeyManager

# 3. Son commit'te API key yok mu kontrol et:
git diff HEAD -- LifeStyles/Services/AI/Core/SecureAPIKeyManager.swift

# Çıktı boş olmalı! Eğer değilse, commit'leme!
```

### 🔒 Eğer Yanlışlıkla API Key Push Ettiysen

```bash
# ❌ ASLA bunu yapma (geçmişte kalır):
# git revert <commit>

# ✅ Bunun yerine:

# 1. API Key'i HEMEN değiştir (Anthropic Console)
# 2. Git history'yi temizle:
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch LifeStyles/Services/AI/Core/SecureAPIKeyManager.swift" \
  --prune-empty --tag-name-filter cat -- --all

# 3. Force push (dikkatli):
git push origin --force --all
```

## 📝 E-posta Adresi Güncelleme

Privacy ve Terms sayfalarında placeholder e-postalar var:

```
privacy@lifestyles.app
support@lifestyles.app
```

Bunları kendi e-postanla değiştir:

```bash
# docs/privacy.html
sed -i '' 's/privacy@lifestyles.app/SENIN_EMAILIN@gmail.com/g' docs/privacy.html

# docs/terms.html
sed -i '' 's/support@lifestyles.app/SENIN_EMAILIN@gmail.com/g' docs/terms.html
```

## 🎨 Özelleştirme (İsteğe Bağlı)

### Renkleri Değiştir

```html
<!-- privacy.html - Satır 13 -->
<style>
    body {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        /* İstediğin renkleri kullan */
    }
</style>
```

### Logo Ekle

```html
<!-- index.html - Satır 71'den önce -->
<img src="logo.png" alt="LifeStyles" style="width: 100px; margin-bottom: 20px;">
```

## 🌐 Özel Domain (İsteğe Bağlı)

Eğer kendi domain'in varsa (`lifestyles.app`):

1. `docs/` klasörüne `CNAME` dosyası ekle:
   ```
   lifestyles.app
   ```

2. DNS ayarlarında:
   ```
   Type: CNAME
   Name: @
   Value: KULLANICI_ADIN.github.io
   ```

3. GitHub Pages'te custom domain'i aktif et

## ✅ Son Kontrol

```bash
# 1. URL'ler çalışıyor mu?
curl -I https://KULLANICI_ADIN.github.io/LifeStyles/privacy.html

# 200 OK dönmeli

# 2. Mobilde test
# Settings → Privacy Policy tıkla
# Sayfa açılıyor mu?

# 3. App Store Connect'e gir
# App Information → Privacy Policy URL
# URL'i ekle ve test et
```

## 🚨 Sorun Giderme

### "404 Not Found"
- GitHub Pages'in aktif olduğundan emin ol
- 2-3 dakika bekle (ilk deployment)
- Branch ve folder doğru mu kontrol et

### "URL açılmıyor"
- HTTPS kullan (HTTP değil)
- Tam URL'i kullan (trailing slash olmadan)
- Tarayıcı cache'ini temizle

### "API Key görünüyor"
- **HEMEN** Anthropic Console'dan key'i revoke et
- Yeni key oluştur
- Git history'yi temizle (yukarıdaki komutlar)

## 📱 App Store Connect

Privacy ve Terms URL'lerini ekle:

```
App Store Connect → My Apps → LifeStyles → App Information

Privacy Policy URL:
https://KULLANICI_ADIN.github.io/LifeStyles/privacy.html

Support URL:
https://KULLANICI_ADIN.github.io/LifeStyles/

Marketing URL (opsiyonel):
https://KULLANICI_ADIN.github.io/LifeStyles/
```

## 🎉 Tamamdır!

Artık App Store'a yükleyebilirsin!

---

**Sorular?**
- GitHub Pages Docs: https://docs.github.com/en/pages
- LifeStyles Support: support@lifestyles.app
