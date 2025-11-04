#!/bin/bash
# Legal URL Güncelleme Scripti
# GitHub Pages URL'lerini uygulamaya ekler

echo "🔗 Legal URL Güncelleme Scripti"
echo "================================"
echo ""

# Kullanıcıdan GitHub username al
read -p "GitHub kullanıcı adın nedir? " GITHUB_USER

if [ -z "$GITHUB_USER" ]; then
    echo "❌ Kullanıcı adı boş olamaz!"
    exit 1
fi

# URL'leri oluştur
PRIVACY_URL="https://${GITHUB_USER}.github.io/LifeStyles/privacy.html"
TERMS_URL="https://${GITHUB_USER}.github.io/LifeStyles/terms.html"

echo ""
echo "📋 Güncellenecek URL'ler:"
echo "Privacy: $PRIVACY_URL"
echo "Terms: $TERMS_URL"
echo ""

read -p "Devam edilsin mi? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ İptal edildi."
    exit 1
fi

# Backup oluştur
echo "📦 Backup oluşturuluyor..."
cp LifeStyles/Views/Premium/PremiumPaywallView.swift LifeStyles/Views/Premium/PremiumPaywallView.swift.backup
cp LifeStyles/Views/Settings/SettingsView.swift LifeStyles/Views/Settings/SettingsView.swift.backup

# PremiumPaywallView.swift güncelle
echo "🔧 PremiumPaywallView.swift güncelleniyor..."
sed -i '' "s|https://lifestyles.app/privacy|$PRIVACY_URL|g" LifeStyles/Views/Premium/PremiumPaywallView.swift
sed -i '' "s|https://lifestyles.app/terms|$TERMS_URL|g" LifeStyles/Views/Premium/PremiumPaywallView.swift

# SettingsView.swift güncelle
echo "🔧 SettingsView.swift güncelleniyor..."
sed -i '' "s|https://example.com/privacy|$PRIVACY_URL|g" LifeStyles/Views/Settings/SettingsView.swift
sed -i '' "s|https://example.com/terms|$TERMS_URL|g" LifeStyles/Views/Settings/SettingsView.swift

echo ""
echo "✅ URL'ler güncellendi!"
echo ""
echo "📄 Değişen dosyalar:"
echo "  - LifeStyles/Views/Premium/PremiumPaywallView.swift"
echo "  - LifeStyles/Views/Settings/SettingsView.swift"
echo ""
echo "📦 Backup dosyaları:"
echo "  - LifeStyles/Views/Premium/PremiumPaywallView.swift.backup"
echo "  - LifeStyles/Views/Settings/SettingsView.swift.backup"
echo ""
echo "🔍 Değişiklikleri kontrol et:"
echo "  git diff LifeStyles/Views/Premium/PremiumPaywallView.swift"
echo "  git diff LifeStyles/Views/Settings/SettingsView.swift"
echo ""
