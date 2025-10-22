# LifeStyles - UI Tasarım Sistemi

## Genel Bakış

LifeStyles, modern ve motivasyonel bir kişisel yaşam koçu iOS uygulamasıdır. Tasarım sistemi, kullanıcıları motive eden, enerji veren ve profesyonel bir görünüm sunmayı hedefler.

## Tasarım Felsefesi

- **Motivasyonel**: Canlı renkler ve enerjik gradientler
- **Modern**: Glassmorphism, soft shadows ve smooth animasyonlar
- **Profesyonel**: Tutarlı spacing, typography ve component yapısı
- **Erişilebilir**: Dark/Light mode desteği, yüksek kontrast oranları

---

## Renk Paleti

### Ana Marka Renkleri

```swift
Color.brandPrimary      // #6366F1 - Indigo (Ana marka rengi)
Color.brandSecondary    // #8B5CF6 - Purple (İkincil renk)
Color.brandAccent       // #F59E0B - Amber (Vurgu rengi)
```

### Gradientler

#### Primary Gradient (Ana Gradient)
- Mavi → Mor → Pembe
- Kullanım: Dashboard header, önemli butonlar
```swift
LinearGradient.primaryGradient
```

#### Motivation Gradient
- Turuncu → Kırmızı
- Kullanım: Motivasyon kartları, CTA butonları
```swift
LinearGradient.motivationGradient
```

#### Success Gradient
- Yeşil tonları
- Kullanım: Tamamlanan hedefler, başarı göstergeleri
```swift
LinearGradient.successGradient
```

#### Energy Gradient
- Turuncu → Sarı
- Kullanım: Aktivite kartları, enerji göstergeleri
```swift
LinearGradient.energyGradient
```

#### Cool Gradient
- Mavi tonları
- Kullanım: İletişim kartları, bilgilendirme elementleri
```swift
LinearGradient.coolGradient
```

### Semantik Renkler

```swift
Color.success   // #10B981 - Yeşil
Color.warning   // #F59E0B - Sarı
Color.error     // #EF4444 - Kırmızı
Color.info      // #3B82F6 - Mavi
```

### Card Renkleri

```swift
Color.cardCommunication // #3B82F6 - İletişim kartları
Color.cardActivity      // #10B981 - Aktivite kartları
Color.cardGoals         // #F59E0B - Hedef kartları
Color.cardHabits        // #EF4444 - Alışkanlık kartları
Color.cardMotivation    // #8B5CF6 - Motivasyon kartları
```

### Background & Text Renkleri

```swift
// Backgrounds
Color.backgroundPrimary     // #F9FAFB (Light) / Auto (Dark)
Color.backgroundSecondary   // #FFFFFF (Light) / Auto (Dark)
Color.backgroundTertiary    // #F3F4F6 (Light) / Auto (Dark)

// Text
Color.textPrimary    // #111827 (Light) / Auto (Dark)
Color.textSecondary  // #6B7280 (Light) / Auto (Dark)
Color.textTertiary   // #9CA3AF (Light) / Auto (Dark)
```

---

## Typography

### Başlıklar

```swift
// Ana Başlık
.titleText()
// Font: System 32pt, Bold, Rounded

// Alt Başlık
.subtitleText()
// Font: System 16pt, Medium, Rounded

// Section Başlık
.font(.title3).fontWeight(.bold)
```

### Body Text

```swift
.font(.headline)         // 17pt, Semibold
.font(.body)            // 17pt, Regular
.font(.subheadline)     // 15pt, Regular
.font(.caption)         // 12pt, Regular
.font(.caption2)        // 11pt, Regular
```

### Gradient Text

```swift
Text("Başlık")
    .gradientText(gradient: .primaryGradient)
```

---

## Spacing System

```swift
AppConstants.Spacing.tiny        // 4pt
AppConstants.Spacing.small       // 8pt
AppConstants.Spacing.medium      // 12pt
AppConstants.Spacing.large       // 16pt
AppConstants.Spacing.extraLarge  // 20pt
AppConstants.Spacing.huge        // 24pt
```

---

## Border Radius

```swift
AppConstants.CornerRadius.small       // 8pt
AppConstants.CornerRadius.medium      // 12pt
AppConstants.CornerRadius.large       // 16pt
AppConstants.CornerRadius.extraLarge  // 20pt
AppConstants.CornerRadius.card        // 16pt
AppConstants.CornerRadius.button      // 14pt
```

---

## Shadows

### Soft Shadow (Hafif)
```swift
.softShadow(radius: 8, opacity: 0.08)
```

### Medium Shadow (Orta)
```swift
.mediumShadow(radius: 12, opacity: 0.12)
```

### Strong Shadow (Güçlü)
```swift
.strongShadow(radius: 20, opacity: 0.18)
```

### Glow Effect
```swift
.glowEffect(color: .brandPrimary, radius: 10)
```

---

## Component'ler

### 1. ModernStatCard

İstatistik kartı - Gradient background, icon ve animasyon

**Kullanım:**
```swift
ModernStatCard(
    title: "Toplam Kişi",
    value: "42",
    icon: "person.2.fill",
    gradient: .coolGradient,
    showBadge: true,
    badgeText: "Yeni"
)
```

**Özellikler:**
- Gradient background
- Animasyonlu giriş (bounce effect)
- Opsiyonel badge
- Icon container
- Auto height: 160pt

---

### 2. GlassStatCard

Glass morphism istatistik kartı - Yarı saydam, blur efekti

**Kullanım:**
```swift
GlassStatCard(
    title: "Aktif Hedef",
    value: "5",
    icon: "target",
    color: .cardGoals,
    trend: .up,
    trendValue: "+2"
)
```

**Özellikler:**
- Glassmorphism efekti
- Trend göstergesi (up/down/neutral)
- Glow effect
- Height: 140pt

---

### 3. ModernAlertCard

Bildirim/Uyarı kartı

**Kullanım:**
```swift
ModernAlertCard(
    title: "Dışarı Çıkma Zamanı!",
    message: "3 saattir evdesiniz.",
    icon: "sun.max.fill",
    type: .warning,
    action: { /* action */ },
    actionLabel: "Git"
)
```

**Tipler:**
- `.info` - Mavi
- `.success` - Yeşil
- `.warning` - Sarı/Turuncu
- `.error` - Kırmızı

---

### 4. ProgressCard

İlerleme kartı - Hedefler ve alışkanlıklar için

**Kullanım:**
```swift
ProgressCard(
    title: "Kitap Okuma",
    subtitle: "Sayfa 120/300",
    progress: 0.4,
    icon: "book.fill",
    color: .cardGoals,
    showPercentage: true,
    action: { /* action */ }
)
```

**Özellikler:**
- Animated progress bar
- Opsiyonel percentage
- Opsiyonel action button

---

### 5. ModernActionButton

Büyük aksiyon butonu - Icon ve label ile

**Kullanım:**
```swift
ModernActionButton(
    icon: "sparkles",
    title: "Günlük Motivasyon Al",
    subtitle: "Size özel mesaj",
    gradient: .primaryGradient,
    action: { /* action */ }
)
```

**Özellikler:**
- Gradient background
- Icon container
- Subtitle desteği
- Chevron indicator

---

### 6. QuickActionButton

Hızlı aksiyon butonu - Küçük, icon odaklı

**Kullanım:**
```swift
QuickActionButton(
    icon: "phone.fill",
    label: "Kişiler",
    color: .cardCommunication,
    action: { /* action */ }
)
```

**Özellikler:**
- Circular icon background
- Compact design
- Multi-line label support

---

### 7. StreakBadge

Seri (streak) göstergesi

**Kullanım:**
```swift
StreakBadge(days: 7, size: .medium)
```

**Boyutlar:**
- `.small` - 12pt
- `.medium` - 16pt
- `.large` - 20pt

---

### 8. ModernEmptyState

Boş durum görünümü

**Kullanım:**
```swift
ModernEmptyState(
    icon: "target",
    title: "Henüz Hedef Yok",
    message: "Yeni bir hedef ekleyin",
    actionLabel: "Hedef Ekle",
    action: { /* action */ }
)
```

---

### 9. ModernSectionHeader

Section başlığı

**Kullanım:**
```swift
ModernSectionHeader(
    title: "Hızlı Erişim",
    subtitle: "Sık kullanılan özellikler",
    action: { /* action */ },
    actionLabel: "Tümünü Gör"
)
```

---

## Button Styles

### Primary Button
```swift
Button("Devam") { }
    .buttonStyle(PrimaryButtonStyle(gradient: .primaryGradient))
```

### Secondary Button
```swift
Button("İptal") { }
    .buttonStyle(SecondaryButtonStyle(color: .brandPrimary))
```

### Icon Button
```swift
Button { } label: { Image(systemName: "plus") }
    .buttonStyle(IconButtonStyle(
        backgroundColor: .backgroundTertiary,
        foregroundColor: .brandPrimary,
        size: 44
    ))
```

---

## Card Styles

### Standard Card
```swift
VStack { /* content */ }
    .cardStyle(
        backgroundColor: .backgroundSecondary,
        cornerRadius: 16,
        shadowRadius: 8,
        shadowOpacity: 0.08
    )
```

### Glass Card
```swift
VStack { /* content */ }
    .glassCard(
        tintColor: .white,
        opacity: 0.2,
        blurRadius: 10,
        cornerRadius: 20
    )
```

### Gradient Card
```swift
VStack { /* content */ }
    .gradientCard(
        gradient: .primaryGradient,
        cornerRadius: 16
    )
```

---

## Animasyonlar

### Bounce (Giriş Animasyonu)
```swift
ModernStatCard(...)
    .bounce(delay: 0.1)
```

### Pulse (Nabız Animasyonu)
```swift
Image(systemName: "bell")
    .pulse(duration: 1.0, minScale: 0.95)
```

### Shimmer (Loading Efekti)
```swift
Rectangle()
    .shimmer(duration: 1.5)
```

---

## Haptic Feedback

```swift
HapticFeedback.light()      // Hafif dokunma
HapticFeedback.medium()     // Orta dokunma
HapticFeedback.heavy()      // Güçlü dokunma
HapticFeedback.success()    // Başarı
HapticFeedback.warning()    // Uyarı
HapticFeedback.error()      // Hata
HapticFeedback.selection()  // Seçim değişimi
```

---

## Tema Yönetimi

### Theme Manager Kullanımı

```swift
@Environment(\.themeManager) private var themeManager

// Tema değiştir
themeManager.setTheme(.dark)
themeManager.setTheme(.light)
themeManager.setTheme(.system)

// Tema geçişi
themeManager.toggleTheme()

// Mevcut tema kontrolü
if themeManager.isDarkMode {
    // Dark mode aktif
}
```

### Temalar

- **Light**: Açık tema
- **Dark**: Koyu tema
- **System**: Sistem temasını takip eder

---

## Custom Tab Bar

Modern, glassmorphism tarzında custom tab bar.

**Özellikler:**
- Glassmorphism background
- Animated selection indicator
- Color-coded tabs
- Haptic feedback
- Floating design

**Kullanım:**
ContentView içinde otomatik olarak uygulanır.

---

## Ekran Yapıları

### Dashboard
- Gradient background
- Grid layout (2 columns)
- ModernStatCard kullanımı
- Quick action buttons
- Bounce animations

### Contacts
- List view
- Modern contact row
- Gradient avatars
- Badge indicators
- Swipe actions

### Goals
- Segmented control
- Progress indicators
- Circular progress rings
- Streak badges
- Checkbox animations

### Settings
- Grouped sections
- Theme selector
- Toggle rows
- Card-based layout
- Profile section

---

## Best Practices

### 1. Spacing
- Tutarlı spacing kullan (AppConstants.Spacing)
- Container padding: 16pt
- Item spacing: 12pt
- Section spacing: 20pt

### 2. Colors
- Semantik renkleri kullan
- Gradient'leri dikkatli kullan (fazla olmayın)
- Dark mode'da kontrast oranlarını kontrol et
- Text renkleri için `.primary`, `.secondary`, `.tertiary` kullan

### 3. Typography
- San Francisco (System) font kullan
- Rounded design tercih et
- Bold weights başlıklar için
- Regular/Medium weights body text için

### 4. Animations
- Subtle ve smooth olsun
- Spring animations tercih et
- Duration: 0.3-0.6 saniye
- Cascade animations için delay kullan

### 5. Components
- Reusable component'leri tercih et
- Custom modifiers kullan
- ViewBuilder pattern'i kullan
- Preview'lar ekle

---

## Dosya Yapısı

```
LifeStyles/
├── Utilities/
│   ├── Extensions/
│   │   ├── AppColors.swift       # Renk paleti
│   │   ├── AppStyles.swift       # Custom modifiers
│   │   └── AppComponents.swift   # Reusable components
│   └── ThemeManager.swift        # Tema yönetimi
├── Views/
│   ├── Dashboard/
│   ├── Contacts/
│   ├── Location/
│   ├── Goals/
│   └── Settings/
└── ContentView.swift             # Custom tab bar
```

---

## Gelecek Güncellemeler

- [ ] Animasyonlu chart'lar (hedef ilerleme grafiği)
- [ ] Swipeable card'lar
- [ ] Drag & drop desteği
- [ ] Widget tasarımı
- [ ] Apple Watch companion app tasarımı
- [ ] iPad optimize tasarım
- [ ] Accessibility improvements
- [ ] Localization desteği

---

## Tasarım İlkeleri

1. **Kullanıcı Odaklı**: Her tasarım kararı kullanıcı deneyimini iyileştirmelidir
2. **Tutarlılık**: Component'ler ve stiller tutarlı olmalıdır
3. **Performans**: Animasyonlar 60 FPS'de çalışmalıdır
4. **Erişilebilirlik**: WCAG 2.1 AA standartlarına uygun olmalıdır
5. **Ölçeklenebilirlik**: Yeni özellikler kolayca eklenebilmelidir

---

## Renk Kontrastı

Tüm text/background kombinasyonları WCAG 2.1 AA standartlarını karşılar:
- Normal text: 4.5:1 minimum
- Büyük text: 3:1 minimum
- UI components: 3:1 minimum

---

## İletişim & Feedback

Tasarım sistemi hakkında önerileriniz için:
- GitHub Issues
- Design review meetings
- User testing feedback

---

**Son Güncelleme**: 15 Ekim 2025
**Versiyon**: 1.0.0
**Tasarım Ekibi**: Claude Code
