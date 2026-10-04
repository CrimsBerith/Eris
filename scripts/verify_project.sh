#!/bin/bash
set -euo pipefail

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
echo "2. ErisCore XCTest kontrolleri..."
swift test --package-path Packages/ErisCore
echo "✅ ErisCore testleri BAŞARILI!"

echo ""
echo "3. macOS (ErisMac) Target Derleme Testi..."
xcodebuild -project Eris.xcodeproj -scheme ErisMac -configuration Debug build -quiet CODE_SIGNING_ALLOWED=NO
echo "✅ ErisMac derleme BAŞARILI!"

echo ""
echo "4. iOS (ErisIOS) Target Derleme Testi..."
xcodebuild -project Eris.xcodeproj -scheme ErisIOS -destination "generic/platform=iOS Simulator" -configuration Debug build -quiet CODE_SIGNING_ALLOWED=NO
echo "✅ ErisIOS derleme BAŞARILI!"

echo ""
echo "5. AppIcon Varlık Kontrolleri..."
if [ -f "ErisMac/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json" ] && [ -f "ErisIOS/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    echo "✅ Hem macOS hem iOS AppIcon setleri eksiksiz."
else
    echo "❌ HATA: AppIcon eksik!"
    exit 1
fi

echo ""
echo "6. Gizlilik Manifestosu (PrivacyInfo.xcprivacy) Kontrolleri..."
if [ -f "ErisMac/Resources/PrivacyInfo.xcprivacy" ] && [ -f "ErisIOS/Resources/PrivacyInfo.xcprivacy" ]; then
    echo "✅ Her iki platform için PrivacyInfo.xcprivacy mevcut."
else
    echo "❌ HATA: PrivacyInfo.xcprivacy eksik!"
    exit 1
fi

echo ""
echo "7. Entitlements Dosya Kontrolleri..."
if [ -f "ErisMac/Resources/ErisMac.entitlements" ] && [ -f "ErisIOS/Resources/ErisIOS.entitlements" ]; then
    echo "✅ Yetki dosyaları mevcut; imzalı paketteki yetkiler ayrıca doğrulanmalı."
else
    echo "❌ HATA: Entitlements eksik!"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Test, derleme ve dosya varlığı kontrolleri geçti."
echo "Yayın için imzalama, gerçek cihaz akışları ve gizlilik beyanları ayrıca doğrulanmalı."
echo "=========================================="
