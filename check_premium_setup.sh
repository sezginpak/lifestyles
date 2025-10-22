#!/bin/bash
# Premium Abonelik Kurulum Kontrol Scripti
# LifeStyles - StoreKit & IAP Doğrulama

echo "🔍 LifeStyles Premium Kurulum Kontrolü"
echo "========================================"
echo ""

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Sayaçlar
PASSED=0
FAILED=0
WARNINGS=0

# 1. PurchaseManager.swift kontrolü
echo "📁 1. PurchaseManager.swift kontrolü..."
if [ -f "LifeStyles/Services/Purchase/PurchaseManager.swift" ]; then
    # Test modu kontrolü
    if grep -q "return true" "LifeStyles/Services/Purchase/PurchaseManager.swift"; then
        echo -e "${YELLOW}   ⚠️  TEST MODU AKTİF (isPremium = true)${NC}"
        echo "      Production için bunu kapatmalısın!"
        ((WARNINGS++))
    else
        echo -e "${GREEN}   ✅ PurchaseManager bulundu ve production ready${NC}"
        ((PASSED++))
    fi
else
    echo -e "${RED}   ❌ PurchaseManager.swift bulunamadı!${NC}"
    ((FAILED++))
fi
echo ""

# 2. ProductIDs.swift kontrolü
echo "📁 2. ProductIDs.swift kontrolü..."
if [ -f "LifeStyles/Services/Purchase/ProductIDs.swift" ]; then
    if grep -q "com.lifestyles.premium.monthly" "LifeStyles/Services/Purchase/ProductIDs.swift"; then
        echo -e "${GREEN}   ✅ Product ID tanımlı${NC}"
        ((PASSED++))
    else
        echo -e "${RED}   ❌ Product ID eksik!${NC}"
        ((FAILED++))
    fi
else
    echo -e "${RED}   ❌ ProductIDs.swift bulunamadı!${NC}"
    ((FAILED++))
fi
echo ""

# 3. StoreKit Configuration kontrolü
echo "📁 3. StoreKit Configuration kontrolü..."
if [ -f "LifeStyles.storekit" ]; then
    # Subscription kontrolü
    if grep -q '"productID" : "com.lifestyles.premium.monthly"' "LifeStyles.storekit"; then
        echo -e "${GREEN}   ✅ StoreKit config bulundu${NC}"
        ((PASSED++))

        # Fiyat kontrolü
        if grep -q '"displayPrice" : "39.99"' "LifeStyles.storekit"; then
            echo -e "${GREEN}   ✅ Fiyat ayarlanmış (₺39.99)${NC}"
            ((PASSED++))
        else
            echo -e "${YELLOW}   ⚠️  Fiyat ayarı kontrol edilmeli${NC}"
            ((WARNINGS++))
        fi
    else
        echo -e "${RED}   ❌ Product yapılandırması eksik!${NC}"
        ((FAILED++))
    fi
else
    echo -e "${RED}   ❌ LifeStyles.storekit bulunamadı!${NC}"
    ((FAILED++))
fi
echo ""

# 4. PremiumPaywallView kontrolü
echo "📁 4. PremiumPaywallView kontrolü..."
if [ -f "LifeStyles/Views/Premium/PremiumPaywallView.swift" ]; then
    echo -e "${GREEN}   ✅ Paywall view bulundu${NC}"
    ((PASSED++))
else
    echo -e "${RED}   ❌ PremiumPaywallView.swift bulunamadı!${NC}"
    ((FAILED++))
fi
echo ""

# 5. Entitlement dosyası kontrolü
echo "📁 5. Entitlement dosyası kontrolü..."
if [ -f "LifeStyles/LifeStyles.entitlements" ]; then
    echo -e "${GREEN}   ✅ Entitlements bulundu${NC}"
    ((PASSED++))

    # In-App Purchase capability kontrolü
    if grep -q "com.apple.developer.in-app-payments" "LifeStyles/LifeStyles.entitlements"; then
        echo -e "${GREEN}   ✅ In-App Purchase capability eklendi${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}   ⚠️  In-App Purchase capability EKSİK!${NC}"
        echo "      Xcode → Target → Signing & Capabilities → + In-App Purchase"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}   ⚠️  Entitlements dosyası bulunamadı${NC}"
    ((WARNINGS++))
fi
echo ""

# 6. AIUsageManager kontrolü
echo "📁 6. AIUsageManager kontrolü..."
if [ -f "LifeStyles/Services/Usage/AIUsageManager.swift" ]; then
    if grep -q "isPremium" "LifeStyles/Services/Usage/AIUsageManager.swift"; then
        echo -e "${GREEN}   ✅ Premium limit kontrolü bulundu${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}   ⚠️  Premium kontrolü eksik olabilir${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}   ⚠️  AIUsageManager bulunamadı${NC}"
    ((WARNINGS++))
fi
echo ""

# Özet
echo "========================================"
echo "📊 ÖZET"
echo "========================================"
echo -e "${GREEN}✅ Başarılı: $PASSED${NC}"
echo -e "${YELLOW}⚠️  Uyarı: $WARNINGS${NC}"
echo -e "${RED}❌ Hatalı: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 Premium kurulumu tamamlanmış!${NC}"
    echo ""
    echo "Sonraki adımlar:"
    echo "1. Xcode'da StoreKit Configuration'ı aktif et"
    echo "2. Simulator'da test et"
    echo "3. TestFlight'ta test et"
    echo "4. App Store Connect'te product oluştur"
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Bazı uyarılar var, kontrol et!${NC}"
    echo ""
    echo "Detaylar için: PREMIUM_SETUP_GUIDE.md"
else
    echo -e "${RED}❌ Kritik hatalar var, düzeltilmeli!${NC}"
    echo ""
    echo "Detaylar için: PREMIUM_SETUP_GUIDE.md"
fi

echo ""
echo "📖 Tam kurulum rehberi: PREMIUM_SETUP_GUIDE.md"
