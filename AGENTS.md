# Eris – Ajan Kuralları (Codex + Claude)

İş planı ve paket listesi: `docs/ROADMAP.md`. Her görev bir paket ID'sine (C-NN = Claude, X-NN = Codex) karşılık gelir.

## Proje
- macOS 14+ / iOS 17+ SwiftUI uygulaması, Swift 5.9, `SWIFT_STRICT_CONCURRENCY: complete`.
- `project.yml` (XcodeGen) → `Eris.xcodeproj`. Hedefler: `ErisMac`, `ErisIOS`.
- Ortak kod: `Packages/ErisCore` (Capabilities, Config, Intelligence, Localization, Models, Storage, Views, Voice). Testler: `Packages/ErisCore/Tests/ErisCoreTests`.
- Harici bağımlılık yok; yeni paket eklemeden önce sor.

## Derleme ve doğrulama
- Ajan ortamlarında Xcode yok: `xcodebuild`/`swift build` çalıştırmaya çalışma.
- Doğrulama `.github/workflows/apple-validation.yml` (macOS 15 / Xcode 16.4; CrimsBerith/Eris#2 ile gelir) ile yapılır: ErisCore testleri + ErisMac/ErisIOS build. PR'ı CI yeşil olana kadar düzelt; "derlendi" deme, CI sonucunu raporla.
- Statik kontroller yapılabilir: `grep` sayımları, `python3 -c "import plistlib"` ile plist/entitlement doğrulama, JSON doğrulama.

## Dallar ve PR'lar
- Codex: paket başına `codex/X-NN-kisa-ad` dalı, `main`'den; paket başına bir PR.
- Claude: `claude/gracious-hypatia-fz7a7a` dalı.
- Yalnızca paketin "Dosyalar" sütunundaki yollara dokun. `project.yml` ve `Package.swift` paylaşımlıdır; yalnızca ⚠ ile işaretli paketler değiştirir.
- Commit: `feat|fix|refactor|test|chore|docs(alan): özet`, commit başına bir mantıksal değişiklik.

## Kod stili
- `.foregroundStyle(...)` kullan, `.foregroundColor(...)` değil.
- `.clipShape(.rect(cornerRadius: x))` kullan, `.cornerRadius(x)` değil.
- Loglama: `os.Logger` (`print` yok, testler hariç).
- Yeni kullanıcı metinleri: String Catalog (`String(localized:)`), kodda sabit metin yok (X-03 sonrası zorunlu).
- UI'ı güncelleyen kod `@MainActor`; yeni `@unchecked Sendable` ekleme.
- Etkileşimli öğelere `accessibilityLabel`; animasyonlarda `accessibilityReduceMotion` kontrolü.
- Saf taşıma/mekanik paketlerde (X-02, X-05, X-06) mantık değiştirme.
- Sırları (API anahtarları) asla commit'leme.
