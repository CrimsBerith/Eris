#!/bin/bash
set -e

echo "=========================================="
echo "🖥️  ERIS: macOS Archive & App Store Paketi"
echo "=========================================="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

TEAM_ID="${1:-$DEVELOPMENT_TEAM}"
ARCHIVE_PATH="$PROJECT_DIR/build/ErisMac.xcarchive"

mkdir -p "$PROJECT_DIR/build"

echo "1. xcodegen ile proje yenileniyor..."
xcodegen generate

echo ""
echo "2. macOS Hedefi Arşivleniyor (Any Mac)..."
if [ -n "$TEAM_ID" ]; then
    echo "Apple Team ID: $TEAM_ID kullanılıyor..."
    xcodebuild archive \
        -project Eris.xcodeproj \
        -scheme ErisMac \
        -destination "generic/platform=macOS" \
        -archivePath "$ARCHIVE_PATH" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        CODE_SIGN_STYLE="Automatic" \
        CODE_SIGNING_REQUIRED="YES" \
        CODE_SIGNING_ALLOWED="YES"
else
    echo "⚠️  Team ID belirtilmedi. Arşiv derleme kontrolü yapılıyor..."
    xcodebuild archive \
        -project Eris.xcodeproj \
        -scheme ErisMac \
        -destination "generic/platform=macOS" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED="NO" \
        CODE_SIGNING_ALLOWED="NO"
fi

EXPORT_PATH="$PROJECT_DIR/build/ErisMac_Export"

if [ -n "$TEAM_ID" ] && [ "$2" == "--export" ]; then
    echo ""
    echo "3. .pkg / App Paketi Dışa Aktarılıyor (Mac App Store Dağıtımı)..."
    ACTIVE_PLIST="$PROJECT_DIR/build/ExportOptions-Mac-active.plist"
    cp "$PROJECT_DIR/scripts/ExportOptions-AppStore-Mac.plist" "$ACTIVE_PLIST"
    /usr/libexec/PlistBuddy -c "Set :teamID $TEAM_ID" "$ACTIVE_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :teamID string $TEAM_ID" "$ACTIVE_PLIST"
    
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$ACTIVE_PLIST"
    echo "✅ macOS Paketi Başarıyla Üretildi: $EXPORT_PATH"
fi

echo ""
echo "=========================================="
echo "✅ macOS Archive Başarıyla Oluşturuldu!"
echo "Arşiv Yolu: $ARCHIVE_PATH"
echo "=========================================="
echo ""
echo "Sonraki Adımlar:"
echo "1. Xcode Organizer ile açmak için:"
echo "   open \"$ARCHIVE_PATH\""
echo "2. 'Distribute App' -> 'Mac App Store' butonuna tıklayarak doğrudan App Store Connect'e yükleyebilirsiniz."
echo "=========================================="
