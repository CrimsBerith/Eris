# Eris – Claude + Codex İş Bölümü Planı

## Context
Eris, macOS 14+ ve iOS 17+ için yazılmış bir SwiftUI uygulaması. Yaklaşık 19 bin satır, Gemini tabanlı ve Türkçe. Proje XcodeGen ile üretiliyor (`project.yml`) ve ortak kod yerel `Packages/ErisCore` paketinde. Kullanıcı 12 iş başlığının tamamını istiyor. İş Claude ile Codex arasında yaklaşık yarı yarıya bölünecek. Görseller ve toplu, mekanik dönüşümler Codex'e gidiyor. Mimari, güvenlik, eşzamanlılık, zor buglar ve audit Claude'a gidiyor.

**Kısıtlar:**
- Claude da Codex de bulutta, Linux'ta ve Xcode'suz çalışıyor. İkisi de Swift derleyemiyor. `ErisCore` SwiftUI ve EventKit import ettiği için Linux'ta da derlenmiyor.
- Bu yüzden ilk iş, **macOS GitHub Actions CI** kurmak. Her PR'ın derleme ve test doğrulaması CI'da yapılacak.

**Kullanıcı kararları:**
- API anahtarı için **backend proxy ve App Attest** kullanılacak.
- Vault **gerçekten şifrelenecek**: CryptoKit AES-GCM, anahtar Keychain'de.

**Zaten yapılanlar** ([CrimsBerith/Eris#1](https://github.com/CrimsBerith/Eris/pull/1)):
- Gemini anahtarı header'a taşındı.
- SQLite yazma hataları loglanıyor.
- `Package.swift` içindeki olmayan Resources tanımı kaldırıldı.
- iCloud KVS entitlement eklendi.
- Privacy manifest'lere kullanıcı içeriği beyanı eklendi.

---

## Ortak çalışma kuralları

1. **Dallar**
   - Claude yalnızca `claude/gracious-hypatia-fz7a7a` dalında çalışır. Her dalga sonunda PR merge edilir. Sonraki dalga için dal `main`'den yeniden başlatılır ve yeni PR açılır.
   - Codex her paket için ayrı bir dal açar: `codex/X-NN-kisa-ad`. Her paketin kendi PR'ı olur.
2. **Dosya sahipliği.** Her paket, dokunabileceği yolları listeler. Aynı dalgada iki ajan aynı dosyaya dokunmaz. Paylaşılan dosyalara (`project.yml`, `Package.swift`) yalnızca paketin sahibi dokunur, ve bu paket tabloda "⚠ paylaşımlı" olarak işaretlidir.
3. **Doğrulama.** CI yeşil olmadan merge yok. Hiçbir ajan "derlendi" demez. CI sonucunu raporlar.
4. **Çapraz review.** Claude her Codex PR'ını `/code-review` ile inceler. Codex, Claude'un PR'larını inceleyebilir; bu isteğe bağlı.
5. **Kurallar dosyaları.** `AGENTS.md` (Codex için) ve `CLAUDE.md` (Claude için) aynı kuralları içerir. Bu kurallar dal adı, dosya sahipliği, stil ve "derleyemezsin, CI'a güven" bilgisidir.
6. **Commit biçimi.** Commit başına bir mantıksal değişiklik. Mesaj `feat|fix|refactor|test|chore(alan): ...` biçiminde olur.

---

## Main'e zaten girenler (plan sonrası)
- `018f4f0` hardening: paylaşımlı iCloud KVS, ses önbelleği için CryptoKit, mikrofon ve konum izinleri, SQLite WAL, Hardened Runtime. Bu commit C-06, C-07 ve C-10'un bir kısmını karşılıyor. Paketler başlarken önce bu commit okunur.
- [CrimsBerith/Eris#2](https://github.com/CrimsBerith/Eris/pull/2) (Codex, açık): takvim onayı düzeltmesi, temiz kurulum akışı, Apple CI, 9 regresyon testi, `docs/DEVELOPMENT_BACKLOG.md`. C-06 ve X-07 bu PR merge edildikten sonra başlar.

## Adım 0 – Planı repo'ya koy
Bu plan `docs/ROADMAP.md` olarak commit'lenip [CrimsBerith/Eris#1](https://github.com/CrimsBerith/Eris/pull/1)'e push'lanır. `AGENTS.md` ve Codex görev şablonu bu dosyaya referans verir. Paketler bittikçe tablolarda durum sütunu güncellenir.

## Dalga 0 – Altyapı (paralel)

| ID | Sahip | İş | Dosyalar | Kabul kriteri |
|---|---|---|---|---|
| **C-01** | Codex ✅ | macOS CI: [CrimsBerith/Eris#2](https://github.com/CrimsBerith/Eris/pull/2) içindeki `.github/workflows/apple-validation.yml` (ErisCore XCTest + unsigned ErisMac/ErisIOS build). Ayrı bir CI eklenmez; yeni hedefler (ErisWidgets, UI testleri) bu iş akışına eklenir. | `.github/workflows/apple-validation.yml` | #2 merge edilince tamamlanır. |
| **C-02** | Claude | `AGENTS.md` ve `CLAUDE.md` yazılır. İçerik: mimari özeti, dosya sahipliği tablosu, stil kuralları (`foregroundStyle`, `clipShape`, `os.Logger`, String Catalog), "xcodebuild çalıştırma, CI'a bak" notu. | `AGENTS.md`, `CLAUDE.md` | Codex'in ilk görevi bu dosyaya göre doğru dalı ve dosyaları kullanır. |
| **X-01** | Codex | **Görsel varlıklar 1:** iOS ve Mac AppIcon yenilemesi (iOS 18 için dark ve tinted varyantlar dahil). Asset catalog'a `AccentColor` ve tema renkleri eklenir (`ErisTheme.swift` renkleriyle aynı değerler). Onboarding'in 3 adımı için illüstrasyonlar hazırlanır. | `ErisIOS/Resources/Assets.xcassets`, `ErisMac/Resources/Assets.xcassets`, `docs/design/` | `scripts/verify_project.sh` içindeki AppIcon kontrolü geçer ve Contents.json geçerlidir. Kod değişikliği yoktur. |

---

## Dalga 1 – Ağ katmanı, DB ve mekanik UI temizliği

| ID | Sahip | İş | Dosyalar | Kabul kriteri |
|---|---|---|---|---|
| **C-03** | Claude | **API ve networking:**<br>• `ErisHTTPClient` protokolü ve `URLSession` uygulaması, enjekte edilebilir şekilde.<br>• `ErisError` enum'u, `NSError` ve magic code'ların yerine.<br>• Gemini istek ve yanıt için `Codable` modeller.<br>• `GeminiClient` sorumluluklarına göre bölünür: guardrail, prompt builder, transport.<br>• Open-loop yan etkisi yalnızca başarılı yanıttan sonra çalışır.<br>• Konuşma geçmişi token bütçesine göre kırpılır.<br>• Retry ve rate-limit sayımı düzeltilir.<br>• `ErisNeuralSpeaker` ve `ExternalDataService` yeni client'a geçer.<br>• `URLProtocol` stub'ı ile `GeminiClient` testleri yazılır (başarı, 429 retry, 5xx, decode hatası, kırpma). | `Intelligence/GeminiClient.swift`, yeni `Networking/`, `Voice/ErisNeuralSpeaker.swift`, `Capabilities/ExternalDataService.swift`, yeni `Tests/.../Networking*` | Testler CI'da yeşil. Davranış aynı kalır, hatalar artık tiplidir. |
| **C-06** | Claude | **DB sağlamlığı (bug fix):**<br>• `ErisMemoryDatabase` erişimi tek bir seri kuyrukta veya actor'da yapılır.<br>• Yazma metodları hata fırlatır (`throws`).<br>• Şema sürümü `PRAGMA user_version` ile yönetilir. Sessiz `ALTER TABLE`'lar migration'a dönüşür.<br>• `sqlite3_open` hatasında fallback olur ve kullanıcıya hata gösterilir.<br>• In-memory DB testleri yazılır. | `Storage/ErisMemoryDatabase.swift`, çağıran servisler, yeni test dosyası | Migration ve CRUD testleri yeşil. Hata yolları test edilir. |
| **X-02** | Codex | **SwiftUI ekranları, deprecated API taraması:**<br>• `.foregroundColor(` → `.foregroundStyle(`<br>• `.cornerRadius(x)` → `.clipShape(.rect(cornerRadius: x))`<br>• Kapsam: yaklaşık 600 kullanım. Yoğun dosyalar `IOSWidgetsDashboardView`, `MainWindowView`, `MacVaultSheetView`, `IOSSettingsView`, `IOSMemoryView`.<br>• Yalnızca görsel API değişir, mantık değişmez. | `ErisIOS/Views/*`, `ErisMac/**/*.swift`, `ErisCore/Views/*` (Intelligence/Storage hariç) | `grep` sayımı 0. CI yeşil. Görsel fark yok. |

---

## Dalga 2 – Güvenlik, eşzamanlılık, dosya bölme ve testler

| ID | Sahip | İş | Dosyalar | Kabul kriteri |
|---|---|---|---|---|
| **C-05** | Claude | **Vault şifreleme:**<br>• `ErisVaultCrypto` yazılır: CryptoKit AES-GCM, 256-bit anahtar, `KeychainManager` içinde `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` ile saklanır.<br>• Vault, not ve memory içerikleri şifrelenir. `is_encrypted` sütunu kullanılır.<br>• Mevcut düz metin kayıtlar tek seferlik migration ile şifrelenir.<br>• iCloud sync payload'ı da şifreli gider.<br>• Testler: round-trip, migration, yanlış anahtar. | `Storage/*`, `Capabilities/ErisVaultDocumentService.swift`, `Storage/ErisSyncService.swift` | Diskte düz metin kalmaz (testle doğrulanır). |
| **C-07** | Claude | **Zincirleme buglar ve eşzamanlılık:**<br>• 28 `@unchecked Sendable` / `nonisolated(unsafe)` kullanımı denetlenir. Uygun olanlar `actor` veya `@MainActor` olur.<br>• UI'ı besleyen yayınlar main actor'a taşınır.<br>• `DispatchQueue` ile `Task` karışımı temizlenir.<br>• `ErisVoiceListener`: çift `installTap` koruması, `AVAudioSession` interruption ve route change işleme, `asyncAfter` restart'ı yerine yapılandırılmış yeniden başlatma.<br>• Tek slotlu callback'ler (`onLanguageChanged`, `onSyncUpdated`) çok aboneli `AsyncStream` veya NotificationCenter yapısına geçer. | `Voice/*`, `Localization/ErisLanguageManager.swift` (yalnızca callback kısmı), `Storage/ErisSyncService.swift`, `Capabilities/*` (singleton kilitleri) | Strict concurrency'de uyarı sayısı düşer. CI yeşil. Listener testleri yazılır. |
| **X-05** | Codex | **Büyük dosya bölme (saf taşıma):**<br>• `IOSMemoryView` (1145 satır, 15'ten fazla tip) dosya başına bir tipe bölünür.<br>• `IOSWidgetsDashboardView` kartları ayrı dosyalara ayrılır.<br>• `MainWindowView`, `MacVaultSheetView`, `MacSettingsView`, `IOSSettingsView`, `IOSChatView` alt view'lara bölünür.<br>• `ErisIOSApp.swift` içinden `IOSTab` ve `ErisIOSState` ayrı dosyalara alınır.<br>• **Mantık değişikliği yasak.** | `ErisIOS/**`, `ErisMac/**` | Hiçbir dosya 400 satırı geçmez. CI yeşil. Diff'te yalnızca taşıma olur. |
| **X-07** | Codex | **Unit testler (ağ ve DB dışındakiler):**<br>• Kapsam: `ErisRateLimiter`, `GuardrailFilter`, `ErisAgentPersonaManager`, `ErisIntentDecomposer`, `ErisOpenLoopsEngine`, `ErisLivingChecklistEngine`, `ErisFinanceSubscriptionEngine`, `ErisHabitsGoalsService`, `ExternalDataService` JSON parse (fixture dosyalarıyla), `ErisAppConfig` anahtar çözümleme.<br>• Mevcut `asyncAfter(0.1)` testleri `XCTestExpectation` veya async'e çevrilir. | `Packages/ErisCore/Tests/**`, `Tests/Fixtures/` | Yaklaşık 29 testten 120'den fazla teste çıkılır. Flaky zamanlama kalmaz. |

---

## Dalga 3 – Mimari, backend ve yeni hedefler

| ID | Sahip | İş | Dosyalar | Kabul kriteri |
|---|---|---|---|---|
| **C-08** | Claude | **Mimari ve büyük refactor:**<br>• Servislere protokol yazılır (`MemoryStore`, `LLMClient`, `CalendarProviding`, …).<br>• Bağımlılıkları taşıyan bir `ErisEnvironment` yazılır. Singleton'lar yalnızca varsayılan olarak kalır.<br>• `ErisIOSState` ile `ErisMacState` ortak `@Observable` view-model'lere bölünür: `ChatViewModel`, `VaultViewModel`, `ChecklistsViewModel`, `SettingsViewModel`, `WidgetsViewModel`. Bu view-model'ler ErisCore'da durur.<br>• iOS ve Mac view'ları aynı view-model'leri kullanır, böylece tekrar kalkar.<br>• `ObservableObject` → `@Observable` geçişi yapılır.<br>• View-model testleri mock'larla yazılır. | `ErisCore/ViewModels/` (yeni), `ErisIOS/**` ve `ErisMac/**` içinde state bağlama noktaları | iOS ve Mac'te vault, checklist ve settings mantığı tek kaynaktan gelir. CI yeşil. |
| **C-04** | Claude | **Backend proxy:**<br>• `backend/proxy/` altında bir Cloudflare Worker (TypeScript) yazılır.<br>• `/v1/generate`, Gemini'ye iletir. `/v1/tts`, OpenAI'ye iletir.<br>• Anahtarlar Worker secret'larında durur.<br>• App Attest assertion doğrulaması yapılır.<br>• Cihaz başına KV tabanlı rate limit uygulanır.<br>• İstemci tarafında `ErisAppConfig` içindeki `developerApiKey` yolu kaldırılır ve `DCAppAttestService` entegrasyonu eklenir.<br>• Kullanıcı Ayarlar'dan kendi anahtarını girerse doğrudan çağrı yapılır, bu yol korunur.<br>• Worker için vitest testleri ve CI job'ı eklenir. | `backend/**`, `Config/ErisAppConfig.swift`, `Config/ErisRateLimiter.swift`, `Networking/*`, `.github/workflows/backend.yml` | Binary'de anahtar kalmaz. Worker testleri yeşil. Deploy talimatı `backend/README.md` içinde. |
| **X-08** | Codex | **Feature geliştirme:**<br>• Gerçek **WidgetKit extension** (`ErisWidgets` hedefi). App Group üzerinden takvim, open loops ve checklist widget'ları sunar; small, medium ve lock screen boyutlarında.<br>• Hava durumu konumu ayarlanabilir olur: şehir seçimi veya CoreLocation "When In Use", plist metni dahil.<br>• Piyasa verisinde sahte seed fiyatlar kaldırılır. Veri yoksa "Veri yok / son güncelleme" durumu gösterilir. BIST ve altın için gerçek kaynak eklenir veya kart gizlenir. | `ErisWidgets/**` (yeni), `project.yml` ⚠ paylaşımlı, `Capabilities/ExternalDataService.swift` (C-03 merge edildikten sonra), ilgili widget view'ları | Widget hedefi CI'da derlenir. Fake fiyat kalmaz. |

---

## Dalga 4 – Yerelleştirme, erişilebilirlik, polish ve uyum

| ID | Sahip | İş | Dosyalar | Kabul kriteri |
|---|---|---|---|---|
| **X-03** | Codex | **Yerelleştirme:**<br>• `ErisLanguageManager`'daki 949 satırlık sözlük, bir script ile `Localizable.xcstrings`'e (TR ve EN) dönüştürülür.<br>• View'lardaki sabit metinler `String(localized:)` veya `Text("key")` kullanır.<br>• İzin metinleri için `InfoPlist.xcstrings` (TR ve EN) eklenir.<br>• `ErisLanguageManager` ince bir sarmalayıcıya iner. Uygulama içi dil seçimi korunur. | `ErisCore/Resources/` (yeni; `Package.swift` resources ⚠ paylaşımlı), tüm view'lar, plist'ler | Kodda sabit kullanıcı metni kalmaz (grep kontrolüyle). CI yeşil. |
| **X-04** | Codex | **UI polish, animasyon ve erişilebilirlik:**<br>• `ErisAnimations` ve waveform'da `accessibilityReduceMotion` kontrolü yapılır.<br>• Dynamic Type için `@ScaledMetric` ve semantik fontlar kullanılır.<br>• Etkileşimli tüm öğelere `accessibilityLabel`, `accessibilityHint` ve trait'ler eklenir.<br>• Glass stilinde kontrast düzeltilir.<br>• İsteğe bağlı açık tema desteği eklenir.<br>• iPad için `NavigationSplitView` ile uyarlanabilir düzen kurulur ve `UIRequiresFullScreen` kaldırılır.<br>• Haptik ve geçiş animasyonları gözden geçirilir. | `ErisCore/Views/*`, `ErisIOS/**`, `ErisMac/**`, iOS `Info.plist` | Accessibility Inspector denetiminden geçer (kullanıcı Mac'te kontrol eder). CI yeşil. |
| **X-06** | Codex | **Küçük refactor:**<br>• `print` → `os.Logger` (`ErisLog` kategorileri).<br>• `String.trimmed` extension'ı eklenir.<br>• Legacy `IOSTab` isim migration'ı sadeleştirilir.<br>• `sampleDataForScreenshots` yalnızca `#if DEBUG` altında kalır.<br>• Gemini ve OpenAI anahtar çözümlemesindeki tekrar kaldırılır. | Tüm kod, sahipli dosyalar dışında, satır bazlı | `print(` sayısı 0 (testler hariç). CI yeşil. |
| **C-09** | Claude | **Gizlilik, onay ve politika:**<br>• Web araması için onay anahtarı eklenir. Varsayılan kapalı olur. "nedir" ve "haber" tetikleyicileri onaysız çalışmaz.<br>• Onboarding'e "verileriniz Google ve OpenAI'ye gider" ve takvim paylaşımı onay adımları eklenir.<br>• AI içerik bildirimi ve yanıt "bildir/raporla" aksiyonu eklenir (guideline 1.2).<br>• Sağlık ve finans uyarı metinleri eklenir.<br>• `UIBackgroundModes` ve wake word davranışı netleştirilir. | `Intelligence/*`, `Views/OnboardingView.swift`, Settings view-model'leri | Onaysız hiçbir veri dışarı gitmez (testle doğrulanır). |

---

## Dalga 5 – Final

| ID | Sahip | İş | Dosyalar | Kabul kriteri |
|---|---|---|---|---|
| **X-09** | Codex | **Görsel varlıklar 2 ve dokümanlar:**<br>• UI test hedefi `ErisIOSUITests` kurulur. Smoke akışları (onboarding, sohbet, vault, checklist) ve otomatik ekran görüntüsü üretimi eklenir.<br>• Bu görüntülerden App Store ekran görüntüleri ve pazarlama çerçeveleri hazırlanır: iPhone 6.9"/6.5", iPad 13", Mac.<br>• `PRIVACY_POLICY.md`, `privacy_policy.html`, `support.html` ve `APP_STORE_METADATA.md` güncellenir: proxy, şifreleme, üçüncü taraflar ve onaylar. | `ErisIOSUITests/**`, `project.yml` ⚠, `docs/**` | Ekran görüntüleri yeni UI'ı gösterir. Dokümanlar kodla tutarlıdır. |
| **C-10** | Claude | **App Store final audit ve büyük codebase analizi:**<br>• İmzalama: `project.yml` geliştirme için imzasız kalır. Arşiv script'leri (`scripts/archive_*.sh`) için Release'de imza ve `ENABLE_HARDENED_RUNTIME: YES` ayarlanır.<br>• Entitlement, plist ve privacy manifest ile App Store gizlilik etiketlerinin çapraz kontrolü yapılır.<br>• Deprecated API, konsol logu ve TODO taraması yapılır.<br>• Tüm paketlerin son review'u yapılır.<br>• `docs/AUDIT.md` yazılır: kontrol listesi ve kalan riskler. | `project.yml`, `scripts/*`, `docs/AUDIT.md` | Audit listesi yeşil. Kullanıcı Mac'te TestFlight arşivi alabilir. |

**Sürekli (her dalga):** Claude, Codex PR'larını review eder (C-11). CI kırmızıysa sahibi düzeltir.

---

## İş dağılımı özeti
- **Claude (9 paket):** C-02 kurallar, C-03 networking, C-04 backend, C-05 şifreleme, C-06 DB, C-07 eşzamanlılık ve zincirleme buglar, C-08 mimari, C-09 gizlilik ve onay, C-10 audit. Buna ek olarak review.
- **Codex (10 paket):** C-01 CI (#2), X-01 ve X-09 görseller, ekran görüntüleri ve dokümanlar, X-02 deprecated API taraması, X-03 yerelleştirme, X-04 polish ve erişilebilirlik, X-05 dosya bölme, X-06 küçük refactor, X-07 unit testler, X-08 feature'lar ve WidgetKit.
- **12 başlığın karşılığı:**

| Başlık | Paketler |
|---|---|
| SwiftUI ekranları | X-02, X-05 |
| UI polish | X-04 |
| Feature | X-08 |
| Bug fix | C-06 |
| Testler | X-07, X-09 ve her C paketindeki testler |
| API | C-03, C-04 |
| Küçük refactor | X-06 |
| Büyük refactor | X-05, C-08 |
| Mimari | C-08 |
| Zincirleme bug | C-07 |
| App Store audit | C-09, C-10 |
| Codebase analizi | C-10 |

## Codex görev şablonu (her X paketi için yapıştırılacak)
```
Repo: CrimsBerith/Eris. Önce AGENTS.md'yi oku.
Görev: <X-NN başlığı ve tablo satırındaki iş>.
Dal: codex/X-NN-<ad>, main'den. Bitince PR aç.
Yalnızca şu yollara dokun: <dosyalar>. Bunlar dışında değişiklik yapma.
Xcode yok; derlemeyi CI (.github/workflows/apple-validation.yml) doğrular. CI yeşil olana kadar düzelt.
Mantık değişikliği yasak (X-02/X-05/X-06 için).
Kabul kriteri: <satırdaki kriter>.
```

## Doğrulama
- **Her PR:** CI'da macOS build (ErisMac, ErisIOS, sonradan ErisWidgets) ve `swift test`. Backend için vitest.
- **Statik kontroller:** deprecated API sayımı, `print(` sayımı, sabit metin grep'i, plist doğrulaması (`plistlib`).
- **Kullanıcı, her dalga sonunda Mac'te:** `scripts/verify_project.sh`, simülatörde görsel kontrol ve Accessibility Inspector. Dalga 5 sonrasında `scripts/archive_ios.sh` ve `archive_mac.sh` ile TestFlight.
