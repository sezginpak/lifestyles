#!/bin/bash
# SwiftData veritabanını sıfırlar (Development only!)

echo "🗑️  SwiftData veritabanı temizleniyor..."

# Simulator Application Support dizinini bul
APP_SUPPORT_DIR=~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Library/Application\ Support

# default.store dosyalarını sil
find ~/Library/Developer/CoreSimulator/Devices/ -name "default.store*" -type f -delete 2>/dev/null

# Derived Data temizle
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeStyles-*

echo "✅ Veritabanı temizlendi!"
echo "📱 Uygulamayı yeniden çalıştırın"
