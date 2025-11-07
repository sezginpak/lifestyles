# 🇪🇸 İspanyolca Çeviri Rehberi

## 📊 Durum
- **Toplam Keys**: 1748
- **Dosya**: `LifeStyles/Resources/es.lproj/Localizable.strings`
- **Mevcut Durum**: İngilizce değerler (referans olarak)
- **Hedef**: İspanyolca çeviri

---

## 🎯 Öncelikli Çeviri Kategorileri

### 1️⃣ YÜKSEK ÖNCELİK (Kullanıcı İlk Görür) - ~150 key

#### Tab Titles (Ana Menü)
```
"tab.moodJournal" = "Mood Journal"  → "Diario del Estado de Ánimo"
"tab.memories" = "Memories"  → "Recuerdos"
"tab.activities" = "Activities"  → "Actividades"
"tab.analytics" = "Analytics"  → "Análisis"
"aibrain.tab.title" = "AI Brain"  → "Cerebro IA"
```

#### Onboarding & Welcome
```
"onboarding.*" → Hoş geldin ekranları
"welcome.*" → Karşılama mesajları
"tutorial.*" → Öğretici metinler
```

#### Common Buttons
```
"button.save" = "Save"  → "Guardar"
"button.cancel" = "Cancel"  → "Cancelar"
"button.delete" = "Delete"  → "Eliminar"
"button.edit" = "Edit"  → "Editar"
"button.done" = "Done"  → "Listo"
"button.next" = "Next"  → "Siguiente"
"button.back" = "Back"  → "Atrás"
```

#### Navigation Titles
```
"nav.*" → Sayfa başlıkları
Örnek:
"nav.settings" = "Settings"  → "Configuración"
"nav.profile" = "Profile"  → "Perfil"
```

---

### 2️⃣ ORTA ÖNCELİK (Sık Kullanılan) - ~300 key

#### Labels & Placeholders
```
"label.*" → Form etiketleri
"placeholder.*" → Input placeholder'ları
Örnek:
"placeholder.search" = "Search..."  → "Buscar..."
"label.email" = "Email"  → "Correo electrónico"
```

#### Mood & Journal
```
"mood.*" → Ruh hali ile ilgili
"journal.*" → Günlük ile ilgili
Örnek:
"mood.happy" = "Happy"  → "Feliz"
"mood.sad" = "Sad"  → "Triste"
"journal.entry" = "Entry"  → "Entrada"
```

#### Goals & Habits
```
"goal.*" → Hedefler
"habit.*" → Alışkanlıklar
Örnek:
"goal.title" = "Goal"  → "Objetivo"
"habit.daily" = "Daily"  → "Diario"
```

#### Friends & Contacts
```
"friend.*" → Arkadaşlar
"contact.*" → İletişim
Örnek:
"friend.add" = "Add Friend"  → "Añadir Amigo"
```

---

### 3️⃣ DÜŞÜK ÖNCELİK (Teknik/Detay) - ~1298 key

#### Analytics & Statistics
```
"analytics.*" → Analitik metinler
"stats.*" → İstatistikler
"correlation.*" → Korelasyonlar
```

#### Achievements & Gamification
```
"achievement.*" → Başarımlar
"badge.*" → Rozetler
"level.*" → Seviyeler
```

#### Error Messages
```
"error.*" → Hata mesajları
Örnek:
"error.network" = "Network error"  → "Error de red"
"error.invalid" = "Invalid input"  → "Entrada inválida"
```

#### Activity Details
```
"activity.*" → Aktivite detayları (çok fazla!)
Örnek:
"activity.cafe.read.book.title" = "Read a Book"
```

---

## 🛠️ Manuel Çeviri Süreci

### Adım 1: Xcode'da Dosyayı Aç
```bash
open -a Xcode LifeStyles/Resources/es.lproj/Localizable.strings
```

### Adım 2: Kategorilere Göre Çevir
Yukarıdaki öncelik sırasına göre çeviri yap:
1. Önce YÜKSEK öncelikli (~150 key)
2. Sonra ORTA öncelikli (~300 key)
3. Son olarak DÜŞÜK öncelikli (zaman varsa)

### Adım 3: Pattern Kullan
Benzer key'ler için aynı çeviriyi kullan:
```
"button.save" = "Guardar"
"button.cancel" = "Cancelar"
"button.delete" = "Eliminar"
... tüm button.* için aynı pattern
```

### Adım 4: Test Et
Simulator'da İspanyolca test et:
```
Settings → General → Language & Region → Español
```

---

## 💡 Çeviri İpuçları

### İspanyolca Karakterler
```
á é í ó ú ñ ü ¿ ¡
```

### Yaygın Çeviriler
```
EN → ES
Save → Guardar
Cancel → Cancelar
Delete → Eliminar
Edit → Editar
Search → Buscar
Settings → Configuración
Profile → Perfil
Help → Ayuda
Close → Cerrar
Open → Abrir
Yes → Sí
No → No
OK → Aceptar
```

### Context Aware
Bazı kelimeler context'e göre değişir:
```
"Date" (tarih) → "Fecha"
"Date" (randevu) → "Cita"

"Save" (kaydet) → "Guardar"
"Save" (tasarruf et) → "Ahorrar"
```

---

## 📊 Çeviri Progress Takibi

### Manuel Takip
Her kategori tamamlandığında işaretle:
- [ ] Tab Titles (5 key)
- [ ] Common Buttons (20 key)
- [ ] Navigation Titles (30 key)
- [ ] Labels & Placeholders (100 key)
- [ ] Mood & Journal (80 key)
- [ ] Goals & Habits (70 key)
- [ ] Friends & Contacts (50 key)
- [ ] Error Messages (30 key)
- [ ] Analytics (200 key)
- [ ] Achievements (100 key)
- [ ] Activities (1000+ key)

### Otomatik Kontrol
```bash
# Çeviri yapılmış key sayısını kontrol et
grep -v "^/\*" LifeStyles/Resources/es.lproj/Localizable.strings | \
  grep -v "^$" | \
  grep " = \"[^\"]*\"" | \
  wc -l
```

---

## 🚀 Hızlı Başlangıç

### En Önemli 50 Key (İlk Yapılacaklar)

```
# TAB TITLES (5)
"tab.moodJournal"
"tab.memories"
"tab.activities"
"tab.analytics"
"aibrain.tab.title"

# BUTTONS (10)
"button.save"
"button.cancel"
"button.delete"
"button.edit"
"button.done"
"button.next"
"button.back"
"button.close"
"button.add"
"button.remove"

# NAVIGATION (10)
"nav.settings"
"nav.profile"
"nav.home"
"nav.back"
"nav.save"
"nav.daily.insight"
"nav.save.mood"
"nav.emoji.picker"
"nav.add.note"
"nav.tags"

# COMMON LABELS (10)
"label.title"
"label.description"
"label.date"
"label.time"
"label.name"
"label.email"
"label.password"
"label.confirm"
"label.optional"
"label.required"

# PLACEHOLDERS (10)
"placeholder.search"
"placeholder.enter"
"placeholder.select"
"placeholder.title"
"placeholder.mood.note"
"placeholder.emoji.search"
"placeholder.tag.name"
"placeholder.custom.tag"
"placeholder.etiket.ekle"
"placeholder.örn.müzik.spor.seyahat"

# ERROR MESSAGES (5)
"error.network"
"error.invalid"
"error.required"
"error.unknown"
"error.invalid.coordinates"
```

---

## 🎯 Sonraki Adımlar

1. **Xcode'da Aç**: `es.lproj/Localizable.strings`
2. **İlk 50 Key'i Çevir**: Yukarıdaki liste
3. **Test Et**: Simulator'da İspanyolca ayarla
4. **Devam Et**: Kategorilere göre öncelikli çeviri
5. **Commit**: Her 50-100 key'de bir commit at

---

## 📝 Örnek Çeviri Bloğu

```
/* === TAB TITLES === */
"tab.moodJournal" = "Diario del Estado de Ánimo";
"tab.memories" = "Recuerdos";
"tab.activities" = "Actividades";
"tab.analytics" = "Análisis";

/* === COMMON BUTTONS === */
"button.save" = "Guardar";
"button.cancel" = "Cancelar";
"button.delete" = "Eliminar";
"button.edit" = "Editar";
"button.done" = "Listo";
```

---

**İyi çeviriler! 🇪🇸✨**
