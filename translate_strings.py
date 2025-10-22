#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LifeStyles String Translator
Türkçe → İngilizce otomatik çeviri
"""

import json

# Çeviri haritası - Manuel olarak kontrol edilmiş çeviriler
translations = {
    # Boş ve format string'leri
    "": "",
    "(%lld)": "(%lld)",
    "/ %lld": "/ %lld",
    "#%lld": "#%lld",
    "%": "%",
    "•": "•",
    "💑": "💑",
    "💕": "💕",
    "📈": "📈",
    "📉": "📉",

    # Versiy ve sistem
    "1.0.0": "1.0.0",

    # Sorular ve uyarılar
    "%@ adlı kişiyi silmek istediğinizden emin misiniz?": "Are you sure you want to delete %@?",
    "%@ hakkında soru sorabilir veya mesaj taslağı isteyebilirsiniz.": "You can ask questions about %@ or request message drafts.",
    "%@ saat evdesiniz": "You've been home for %@ hours",

    # Sayısal formatlar
    "%%%lld": "%%%lld",
    "%lld": "%lld",
    "%lld Aktif": "%lld Active",
    "%lld Gecikmiş": "%lld Overdue",
    "%lld gün": "%lld days",
    "%lld gün gecikti": "%lld days overdue",
    "%lld gün içinde": "in %lld days",
    "%lld gün kaldı": "%lld days left",
    "%lld günlük seri!": "%lld day streak!",
    "%lld lokasyon": "%lld locations",
    "%lld nokta": "%lld points",
    "%lld Puan": "%lld Points",
    "%lld Tamamlandı": "%lld Completed",
    "%lld%%": "%lld%%",
    "%lldh dışarıda": "%lldh outside",

    # Dashboard
    "Hoş Geldiniz!": "Welcome!",
    "Performansınızı takip edin ve hedeflerinize ulaşın": "Track your performance and achieve your goals",
    "Genel Performans": "Overall Performance",
    "SKOR": "SCORE",
    "Alışkanlık Performansı": "Habit Performance",
    "Hedef İstatistikleri": "Goal Statistics",
    "Tamamlanma": "Completion",
    "Aktif Hedefler": "Active Goals",
    "Tamamlanan Hedefler": "Completed Goals",
    "Motivasyon": "Motivation",
    "Bildirim Gönder": "Send Notification",
    "Akıllı Öneriler": "Smart Suggestions",
    "Hızlı Erişim": "Quick Access",
    "Aktiviteler": "Activities",
    "Haftalık Oran": "Weekly Rate",
    "İletişim": "Contact",
    "Mobilite": "Mobility",
    "Bugün": "Today",
    "Bu hafta": "This week",
    "Son 30 Gün": "Last 30 Days",
    "Tümü": "All",
    "puan": "points",
    "gün": "day",
    "gün seri": "day streak",
    "lokasyon": "location",
    "kişi": "person",
    "En Başarılı:": "Top Performer:",
    "Öncelikli Aksiyonlar": "Priority Actions",

    # AI İşlevleri
    "AI": "AI",
    "AI Asistan": "AI Assistant",
    "AI Chat": "AI Chat",
    "AI düşünüyor...": "AI is thinking...",
    "AI Hatası": "AI Error",
    "AI Öneri": "AI Suggestion",
    "AI Önerisi": "AI Suggestion",
    "AI açıklama oluşturuluyor...": "AI is generating description...",
    "Akıllı hedefler oluşturuluyor...": "Generating smart goals...",
    "Bir soru sorun...": "Ask a question...",
    "Hızlı Sorular:": "Quick Questions:",

    # Goals
    "Hedefler": "Goals",
    "Alışkanlıklar": "Habits",
    "Hedef Önerileri": "Goal Suggestions",
    "Hedefe Ekle": "Add to Goal",
    "Henüz Hedef Yok": "No Goals Yet",
    "Henüz Alışkanlık Yok": "No Habits Yet",
    "Henüz Öneri Yok": "No Suggestions Yet",
    "Yeni bir hedef eklemek için + butonuna dokunun": "Tap + to add a new goal",
    "Yeni bir alışkanlık eklemek için + butonuna dokunun": "Tap + to add a new habit",
    "Daha fazla veri toplandıkça size özel hedefler önereceğiz.": "We'll suggest personalized goals as more data is collected.",
    "Henüz öneri yok. Daha fazla veri toplandıkça size özel öneriler gösterilecek.": "No suggestions yet. Personalized suggestions will appear as more data is collected.",
    "Aktivitelerinize göre oluşturulmuş %lld hedef önerisi": "%lld goal suggestions based on your activities",
    "Yeni Öneriler Al": "Get New Suggestions",
    "Yeni Öneriler Oluştur": "Generate New Suggestions",
    "Yeniden Oluştur": "Regenerate",
    "İlgilenmiyorum": "Not Interested",
    "Size Özel Hedefler": "Personalized Goals",
    "Öneriler": "Suggestions",
    "Bugünün Alışkanlıkları": "Today's Habits",
    "Tüm Alışkanlıklar": "All Habits",
    "Tamamlandı": "Completed",
    "Bu hafta": "This week",
    "Alışkanlık İsmi": "Habit Name",
    "Alışkanlığının ismini ve sıklığını belirle": "Set habit name and frequency",
    "Alışkanlığını kontrol et ve hatırlatıcı ayarla": "Check habit and set reminder",
    "Alışkanlık Şablonu": "Habit Template",
    "Açıklama (Opsiyonel)": "Description (Optional)",
    "Açıklama ve hedef tarihini ekle": "Add description and target date",
    "Başlık": "Title",
    "Kategori": "Category",
    "Tarih": "Date",
    "Sonraki Hedef": "Next Goal",

    # Friends/Contacts
    "Arkadaşlar": "Friends",
    "Yeni Arkadaş Ekle": "Add New Friend",
    "Henüz arkadaş eklenmedi": "No friends added yet",
    "Önemli arkadaşlarınızı ekleyin ve düzenli iletişimi takip edin.": "Add important friends and track regular communication.",
    "Arkadaş Ara": "Search Friends",
    "Rehberden Seç": "Select from Contacts",
    "İletişim Gerekiyor": "Contact Needed",
    "İletişim Gerekiyor!": "Contact Needed!",
    "İletişim Tamamlandı": "Contact Complete",
    "Tüm Arkadaşlar": "All Friends",
    "kişi": "person",
    "gecikti": "overdue",
    "kaldı": "remaining",
    "İletişim Sıklığı": "Contact Frequency",
    "Sıklık": "Frequency",
    "Önemli Arkadaş": "Important Friend",
    "Önemli arkadaşlar widget'ta öncelikli gösterilir": "Important friends are prioritized in the widget",
    "Notlar (Opsiyonel)": "Notes (Optional)",
    "Notlar": "Notes",
    "İlişki Tipi": "Relationship Type",
    "Tip": "Type",
    "Kişi Bilgileri": "Contact Information",
    "İsim": "Name",
    "Telefon (Opsiyonel)": "Phone (Optional)",
    "Telefon": "Phone",
    "Avatar Emoji (Opsiyonel)": "Avatar Emoji (Optional)",
    "Avatar Emoji": "Avatar Emoji",
    "İlişki Başlangıcı": "Relationship Start",
    "İlişki Bilgileri": "Relationship Details",
    "Yıldönümü Tarihi": "Anniversary Date",
    "Yıldönümü": "Anniversary",
    "Yıldönümüne %lld gün kaldı": "%lld days until anniversary",
    "Sevgi Dili": "Love Language",
    "Seçilmedi": "Not Selected",
    "Favori Şeyler": "Favorite Things",
    "Favori yemek, film, aktivite vb.": "Favorite food, movies, activities, etc.",
    "Partner Notları": "Partner Notes",
    "Partneriniz hakkında hatırlamak istediğiniz bilgileri buraya yazın.": "Write information you want to remember about your partner here.",
    "Not Ekle": "Add Note",
    "Not": "Not",
    "Henüz not eklenmemiş": "No notes added yet",
    "Bu kategoride not yok": "No notes in this category",
    "Özel Günler": "Special Dates",
    "Özel Gün Ekle": "Add Special Date",
    "Özel Gün Bilgileri": "Special Date Information",
    "Henüz özel gün eklenmemiş": "No special dates added yet",
    "İsteğe bağlı olarak bu özel günle ilgili notlar ekleyebilirsiniz.": "You can optionally add notes about this special date.",
    "Emoji (opsiyonel)": "Emoji (optional)",
    "İletişim Ekle": "Add Contact",
    "Henüz geçmiş kaydı yok": "No contact history yet",
    "Görüşme Nasıl Geçti?": "How Did It Go?",
    "Ruh Hali": "Mood",
    "Ruh Hali Dağılımı": "Mood Distribution",
    "Tarih ve Saat": "Date and Time",
    "İletişim Deseni": "Contact Pattern",
    "İletişim Trendi (Son 3 Ay)": "Contact Trend (Last 3 Months)",
    "Geçmişi Görüntüle": "View History",
    "İlişki Sağlığı": "Relationship Health",
    "Birlikte": "Together",
    "ay": "month",
    "yıl": "year",
    "İlişki Süresi": "Relationship Duration",
    "Sonraki İletişim": "Next Contact",
    "Son: %@": "Last: %@",
    "Sonraki: %@": "Next: %@",
    "En Uygun Gün": "Best Day",
    "Randevu Fikirleri": "Date Ideas",
    "Kişi Ekle": "Add Person",
    "Kişi Ara": "Search Person",
    "Rehber yükleniyor...": "Loading contacts...",
    "Rehber Boş": "Contacts Empty",
    "Rehberinizde kayıtlı kişi bulunamadı.": "No contacts found in your phone book.",
    "Ekle": "Add",
    "Arkadaşı Sil": "Delete Friend",

    # Location
    "Aktivite": "Activity",
    "Konum Geçmişi": "Location History",
    "Harita": "Map",
    "Liste": "List",
    "Görünüm": "View",
    "Rota Açık": "Route On",
    "Rota Kapalı": "Route Off",
    "Toplam Mesafe": "Total Distance",
    "Toplam Kayıt": "Total Records",
    "Son Kayıt": "Last Record",
    "Ev Konumu Ayarlanmadı": "Home Location Not Set",
    "Konum önerileri için ev konumunuzu ayarlayın.": "Set your home location for location suggestions.",
    "Mevcut Konumu Ayarla": "Set Current Location",
    "Ev konumu ayarları": "Home location settings",
    "Evdesiniz": "You're Home",
    "Dışarıdasınız": "You're Outside",
    "Önerilen Aktiviteler": "Suggested Activities",
    "Dışarı Çıkma Zamanı!": "Time to Go Out!",
    "Seçtiğiniz tarihte konum kaydı bulunmuyor.\\nFarklı bir tarih seçmeyi deneyin.": "No location records found for the selected date.\\nTry selecting a different date.",
    "Bu Tarihte Kayıt Yok": "No Records on This Date",
    "Doğruluk": "Accuracy",
    "Ay": "Month",
    "Bugün! 🎉": "Today! 🎉",
    "%lld gün kaldı": "%lld days left",
    "%lld gün içinde": "in %lld days",
    "Rastgele": "Random",
    "Konum geçmişinin arka planda da kaydedilebilmesi için \\"Her Zaman\\" izni vermeniz gerekiyor.\\n\\nAyarlar → LifeStyles → Konum → Her Zaman": "To record location history in the background, you need to grant \\"Always\\" permission.\\n\\nSettings → LifeStyles → Location → Always",
    "Arka Plan Konum İzni Gerekli": "Background Location Permission Required",
    "Konumunuz 15 dakikada bir kaydedilecek. \\"Her Zaman\\" izni gerekiyor.": "Your location will be recorded every 15 minutes. \\"Always\\" permission required.",
    "Her 15 dakikada bir": "Every 15 minutes",

    # Settings
    "Ayarlar": "Settings",
    "İzinler": "Permissions",
    "Versiyon": "Version",
    "Tüm Verileri Sil": "Delete All Data",
    "LifeStyles": "LifeStyles",
    "LifeStyles Kullanıcısı": "LifeStyles User",
    "Kişisel yaşam koçunuz": "Your personal life coach",
    "Başarımlar": "Achievements",
    "Uygulama İpuçları": "App Tips",

    # Onboarding
    "Hoş Geldiniz!": "Welcome!",
    "Başlayalım": "Let's Begin",
    "Atla": "Skip",
    "Daha Sonra": "Later",
    "İletişim": "Contact",
    "Konum": "Location",
    "Bildirimler": "Notifications",
    "Lütfen \\"Her Zaman\\" seçeneğini işaretleyin": "Please select \\"Always\\" option",
    "Ayarlara Git": "Go to Settings",
    "Arka Plan Konum İzni": "Background Location Permission",
    "LifeStyles, hayat kalitenizi artırmak için konumunuzu 15 dakikada bir kaydeder. Bunun arka planda da çalışabilmesi için:\\n\\nAyarlar → LifeStyles → Konum → \\"Her Zaman\\" seçeneğini işaretleyin": "LifeStyles records your location every 15 minutes to improve your quality of life. For this to work in the background:\\n\\nSettings → LifeStyles → Location → Select \\"Always\\" option",

    # UI Components
    "Kaydet": "Save",
    "İptal": "Cancel",
    "Kapat": "Close",
    "Düzenle": "Edit",
    "Sil": "Delete",
    "Ekle": "Add",
    "Sayı": "Count",
    "Tamamlama": "Completion",
    "Geçmiş": "History"
}

def load_json():
    """JSON dosyasını yükle"""
    with open('/Users/sezginpaksoy/Desktop/Claude-Code/LifeStyles/LifeStyles/Resources/Localizable.xcstrings', 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data):
    """JSON dosyasını kaydet"""
    with open('/Users/sezginpaksoy/Desktop/Claude-Code/LifeStyles/LifeStyles/Resources/Localizable.xcstrings', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def add_translations(data, translations):
    """Çevirileri JSON'a ekle"""
    updated_count = 0

    for tr_text, en_text in translations.items():
        if tr_text in data['strings']:
            # Eğer localizations yoksa veya boşsa ekle
            if 'localizations' not in data['strings'][tr_text] or not data['strings'][tr_text].get('localizations'):
                data['strings'][tr_text]['localizations'] = {
                    'en': {
                        'stringUnit': {
                            'state': 'translated',
                            'value': en_text
                        }
                    },
                    'tr': {
                        'stringUnit': {
                            'state': 'translated',
                            'value': tr_text
                        }
                    }
                }
                updated_count += 1
            # Eğer sadece tr varsa en ekle
            elif 'tr' in data['strings'][tr_text]['localizations'] and 'en' not in data['strings'][tr_text]['localizations']:
                data['strings'][tr_text]['localizations']['en'] = {
                    'stringUnit': {
                        'state': 'translated',
                        'value': en_text
                    }
                }
                updated_count += 1

    return data, updated_count

if __name__ == '__main__':
    print("LifeStyles String Translator başlatılıyor...")
    print(f"Toplam {len(translations)} çeviri hazır")

    # JSON'u yükle
    data = load_json()
    print(f"JSON dosyası yüklendi: {len(data['strings'])} string")

    # Çevirileri ekle
    data, updated = add_translations(data, translations)
    print(f"{updated} string güncellendi")

    # JSON'u kaydet
    save_json(data)
    print("JSON dosyası kaydedildi!")
    print("✅ Çeviri tamamlandı!")
