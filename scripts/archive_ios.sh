#!/bin/bash
set -e

echo "=========================================="
echo "📱 ERIS: iOS Archive & App Store Paketi"
echo "=========================================="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

TEAM_ID="${1:-$DEVELOPMENT_TEAM}"
ARCHIVE_PATH="$PROJECT_DIR/build/ErisIOS.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/ErisIOS_Export"

mkdir -p "$PROJECT_DIR/build"

echo "1. xcodegen ile proje yenileniyor..."
xcodegen generate

echo ""
echo "2. iOS Hedefi Arşivleniyor (Generic iOS Device)..."
if [ -n "$TEAM_ID" ]; then
    echo "Apple Team ID: $TEAM_ID kullanılıyor..."
    xcodebuild archive \
        -project Eris.xcodeproj \
        -scheme ErisIOS \
        -destination "generic/platform=iOS" \
        -archivePath "$ARCHIVE_PATH" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        CODE_SIGN_STYLE="Automatic" \
        CODE_SIGNING_REQUIRED="YES" \
        CODE_SIGNING_ALLOWED="YES"
else
    echo "⚠️  Team ID belirtilmedi. Arşiv derleme kontrolü yapılıyor..."
    xcodebuild archive \
        -project Eris.xcodeproj \
        -scheme ErisIOS \
        -destination "generic/platform=iOS" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED="NO" \
        CODE_SIGNING_ALLOWED="NO"
fi

if [ -n "$TEAM_ID" ] && [ "$2" == "--export" ]; then
    echo ""
    echo "3. .ipa Dosyası Dışa Aktarılıyor (App Store Dağıtımı)..."
    mkdir -p "$EXPORT_PATH"
    sed "s/<\/dict>/    <key>teamID<\/key>\n    <string>$TEAM_ID<\/string>\n<\/dict>/" "$PROJECT_DIR/scripts/ExportOptions-AppStore-iOS.plist" > "$PROJECT_DIR/build/ExportOptions-iOS-active.plist"
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$PROJECT_DIR/build/ExportOptions-iOS-active.plist"
    echo "✅ IPA Paketi Başarıyla Üretildi: $EXPORT_PATH"
fi

echo ""
echo "=========================================="
echo "✅ iOS Archive Başarıyla Oluşturuldu!"
echo "Arşiv Yolu: $ARCHIVE_PATH"
echo "=========================================="
echo ""
echo "Sonraki Adımlar:"
echo "1. Xcode Organizer ile açmak için:"
echo "   open \"$ARCHIVE_PATH\""
echo "2. 'Distribute App' -> 'TestFlight & App Store' butonuna tıklayarak doğrudan App Store Connect'e yükleyebilirsiniz."
echo "=========================================="
