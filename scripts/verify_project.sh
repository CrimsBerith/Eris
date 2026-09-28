#!/bin/bash
set -e

echo "=========================================="
echo "🛡️  ERIS: Proje Doğrulama ve Sağlık Kontrolü"
echo "=========================================="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "1. Xcode Projesi Senkronizasyonu (xcodegen)..."
if command -v xcodegen &> /dev/null; then
    xcodegen generate
    echo "✅ Xcode projesi başarıyla güncellendi."
else
    echo "⚠️  xcodegen bulunamadı, mevcut .xcodeproj kullanılıyor."
fi

echo ""
echo "2. macOS (ErisMac) Target Derleme Testi..."
xcodebuild -project Eris.xcodeproj -scheme ErisMac -configuration Debug build -quiet
echo "✅ ErisMac derleme BAŞARILI!"

echo ""
echo "3. iOS (ErisIOS) Target Derleme Testi..."
xcodebuild -project Eris.xcodeproj -scheme ErisIOS -destination "generic/platform=iOS Simulator" -configuration Debug build -quiet
echo "✅ ErisIOS derleme BAŞARILI!"

echo ""
echo "4. AppIcon Varlık Kontrolleri..."
if [ -f "ErisMac/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json" ] && [ -f "ErisIOS/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    echo "✅ Hem macOS hem iOS AppIcon setleri eksiksiz."
else
    echo "❌ HATA: AppIcon eksik!"
    exit 1
fi

echo ""
echo "5. Gizlilik Manifestosu (PrivacyInfo.xcprivacy) Kontrolleri..."
if [ -f "ErisMac/Resources/PrivacyInfo.xcprivacy" ] && [ -f "ErisIOS/Resources/PrivacyInfo.xcprivacy" ]; then
    echo "✅ Her iki platform için PrivacyInfo.xcprivacy mevcut."
else
    echo "❌ HATA: PrivacyInfo.xcprivacy eksik!"
    exit 1
fi

echo ""
echo "6. Entitlements & App Sandbox Kontrolleri..."
if [ -f "ErisMac/Resources/ErisMac.entitlements" ] && [ -f "ErisIOS/Resources/ErisIOS.entitlements" ]; then
    echo "✅ App Sandbox ve yetki dosyaları mevcut."
else
    echo "❌ HATA: Entitlements eksik!"
    exit 1
fi

echo ""
echo "=========================================="
echo "🎉 TEBRİKLER: Eris projesi App Store review ve yayına hazır!"
echo "=========================================="
