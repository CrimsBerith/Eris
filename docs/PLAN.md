# ERIS — Tam Ürün Planı (macOS + iOS → App Store)
**Versiyon:** 1.0 Yol Haritası  
**Platform:** macOS 14+ & iOS 17+  
**Mimari:** Swift 5, SwiftUI, ErisCore (paylaşılan Swift Package)  
**Bundle ID:** `com.alfagolab.eris` (Mac) / `com.alfagolab.eris.ios` (iPhone)  
**Son Güncelleme:** 2026-09-28  
**Toplam Kaynak:** 22 Swift dosyası, ~5.900 satır kod

---

## 🧭 Temel Prensipler

- **Sıfır-Güven (Zero-Trust):** Hiçbir yan etkili eylem onaysız yürütülmez
- **Sıfır-Kurulum (Zero-Setup):** Son kullanıcı API anahtarı girmez; geliştirici yerleşik anahtarla yayınlar
- **Tok & Doğrudan:** Yapay zekâ klişeleri yok, 2-3 cümle ses kuralı
- **Moda Tasarımcısı Sırdaşı & Sağ Kol:** Drapaj/silüet/kumaş ortağı, kumaş maliyet defteri
- **Yolda Yürüyüş Ajandası:** "Hey Eris, bugünkü planlarımız nedir?" → saat saat brifing
- **Premium His:** Glassmorphism, ses dalgası, cam efektleri
- **Gizlilik Önce:** Yerleşik Keychain, yerel şifreli SQLite, hiçbir veri üçüncü şahıslara gitmez

---

## 📊 Mevcut Durum Özeti

| Bileşen | Durum | Notlar |
|---|---|---|
| ErisCore (Paylaşılan Paket) | ✅ Çalışıyor | 16 modül: Models, Intelligence, Voice, Storage, Config, Capabilities, Views |
| ErisMac (macOS App) | ✅ BUILD SUCCEEDED | Glassmorphism, Widget paneli, Ayarlar, Floating Panel |
| ErisIOS (iPhone App) | ✅ BUILD SUCCEEDED | Sohbet, Widget Dashboard, Push-to-Talk, Ayarlar |
| Onboarding | ✅ Yenilendi | API key istenmez, 3 adım: Karşılama → Ses Tonu → İzinler |
| ErisAppConfig | ✅ Çalışıyor | Geliştirici yerleşik API anahtarı mimarisi |
| App Icon | ⚠️ Sadece 1 boyut | Yalnızca `icon_512x512@2x.png` var, iOS boyutları eksik |
| Code Signing | ❌ Devre dışı | `CODE_SIGNING_ALLOWED: NO` — App Store için değiştirilmeli |
| PrivacyInfo.xcprivacy | ✅ Mevcut | Her iki target için oluşturulmuş |
| TestFlight / App Store | ❌ Henüz yok | Hiç publish hazırlığı yapılmamış |

---

## ✅ FAZ 1 — Çekirdek Altyapı (Sprint A) — TAMAMLANDI

- [x] `Message`, `PendingAction`, `ApprovalToken`, `MemoryItem` modelleri
- [x] `GeminiClient` — Gemini REST API entegrasyonu (Flash + Pro seçimi)
- [x] `GuardrailFilter` — Jailbreak ve prompt sızdırma engeli
- [x] `ErisSystemPrompt` — Persona ve İstanbul saat dilimi enjeksiyonu
- [x] `KeychainManager` — macOS/iOS Keychain ile güvenli API Key saklama
- [x] `CalendarCapability` — EventKit okuma/yazma (onaylı)
- [x] `ErisSpeaker` — AVSpeechSynthesizer tok ses profili
- [x] Xcode projesi `ErisMac` ve `ErisIOS` hedefleri — **BUILD SUCCEEDED**

---

## ✅ FAZ 2 — Tasarım, Ses & Özelleştirme Sistemi (Sprint B) — TAMAMLANDI

### 2.1 Premium UI — Glassmorphism
**macOS:** Cam/Blur pencere arka planı, grafit-bronz palet, mesaj baloncukları, Compact Floating Panel, VoiceWaveView, MenuBarExtra  
**iOS:** Koyu glassmorphism tema, Bottom Tab navigasyon, ses dalgası, glassmorphic kartlar

### 2.2 Ses ve Konuşma Sistemi
- [x] 5 Özel Yerel Ses Tonu & Karakteri (Tok Erkek, Sıcak Kadın, Derin Bariton, Dinamik Partner, Minimalist)
- [x] `SFSpeechRecognizer` Türkçe STT + `AVAudioEngine` mikrofon pipeline
- [x] Barge-in, Wake Word ("Hey Eris"), Push-to-Talk (⌘⇧E / uzun basma)
- [x] Canlı "Sesi Dinle" önizleme

### 2.3 Özel Ajan & Uzmanlık Modülleri
- [x] `ErisAgentPersonaManager` — Yüksek Moda Direktörü + Denizcilik Zabit Modu + Custom Directives
- [x] Modülleri açma/kapama, düzenleme, yeni modül ekleme, sıfırlama

### 2.4 Özelleştirilebilir Widget Sistemi
- [x] `ErisWidgetManager` — 6 widget modülü, App Group tabanlı
- [x] iPhone: Widget Dashboard + Seçici Modal
- [x] Mac: Sağ panel dinamik widget + Ayarlar sekmesi

### 2.5 Sıfır-Kurulum API Mimarisi
- [x] `ErisAppConfig` — Geliştirici yerleşik API anahtarı (kod, Info.plist, ortam değişkeni)
- [x] Kullanıcıdan API istenmez, Onboarding 3 adıma düşürüldü

---

## ✅ FAZ 3 — Yetenekler & Entegrasyonlar (Sprint C) — TAMAMLANDI

- [x] Takvim: Doğal dil → Date, olay oluşturma/silme/listeleme (onaylı)
- [x] Kişisel Hafıza Motoru: Şifreli SQLite, 6 kategori, pinleme, bağlam ekleme
- [x] Sabah Brifingi: UserNotifications, Takvim + Hava + Piyasa + Notlar, TTS
- [x] Harici Servisler: Web araştırma, hava durumu, döviz/borsa, deniz durumu

---

## 🔧 FAZ 4 — Stabilizasyon & Kod Kalitesi (Sprint D) ✅ TAMAMLANDI

> **Amaç:** App Store review sürecine girmeden önce uygulamayı teknik olarak sağlamlaştırmak.

### 4.1 Kritik Kod Refaktör
- [x] `ErisIOSApp.swift` (1.954 satır) → `IOSChatView.swift`, `IOSWidgetsDashboardView.swift`, `IOSMemoryView.swift`, `IOSSettingsView.swift` olarak parçalandı ✅
- [x] `MainWindowView.swift` (1.392 satır) → `MacSettingsView.swift` olarak parçalandı ✅
- [x] Tüm view hiyerarşisi modüler hale getirildi, derleme süreleri hızlandırıldı

### 4.2 Hata Yönetimi & Dayanıklılık
- [x] `GeminiClient` HTTP 429 kota, 401/403 yetki ve 500 sunucu hataları kullanıcıya dostça Türkçe mesajlara bağlandı ✅
- [x] `ErisVoiceListener` AVAudioEngine tap kaldırma çökme koruması (`isTapInstalled`) eklendi ✅
- [x] Graceful degradation: Harici servisler veya internet erişilemezken uygulamanın çökmesi engellendi

### 4.3 Performans & Pil Optimizasyonu
- [x] Wake Word dinleme: Ses seviyesi eşiği ve sessizlik çerçeve sayacı ile CPU yükü sınırlandırıldı
- [x] iOS: Arka plan ses oturumu yönetimi (`AVAudioSession` kategori & policy)

### 4.4 Gerçek API Entegrasyonu & Test
- [ ] `ErisAppConfig.developerApiKey` alanına kendi Gemini API anahtarını yerleştir (Kullanıcı tarafından)
- [ ] Sabah brifingi gerçek veriyle test (takvim + hava + piyasa)
- [ ] Kumaş fiyat kaydı → hafıza → geri çağırma döngüsü doğrulaması

---

## 🔗 FAZ 5 — iPhone ↔ Mac Senkronizasyonu (Sprint E) ✅ TAMAMLANDI

> **Amaç:** Kullanıcının iPhone'da kaydettiği kumaş notu, Mac'te de görünsün.

- [x] `NSUbiquitousKeyValueStore` (iCloud KVS) ile hafif ve anlık senkronizasyon ✅
- [x] `ErisSyncService` — Hafıza öğelerini şifreli/JSON formatında push/pull senkronize eder ✅
- [x] Senkronize edilen veriler:
  - Sabitlenmiş hafıza öğeleri (kumaş fiyatları, tasarım notları, atölye bilgileri) ✅
  - Ses tonu ve tercih verileri ✅
- [x] Bağımsız çalışma modu: iCloud bağlı değilse yerel SQLite şifreli olarak kesintisiz çalışır ✅
- [x] Çakışma ve döngü çözümü: `saveMemoryInternal` ile senkronizasyon döngüsü engellendi ✅
- [x] Her iki platformda `onSyncUpdated` dinleyicisi ile anında UI yenileme ✅

---

## 🎨 FAZ 6 — App Store Hazırlığı: Görsel & Marka (Sprint F) ✅ TAMAMLANDI

> **Amaç:** App Store'da profesyonel ve çekici bir sunum oluşturmak.

### 6.1 Uygulama İkonu ✅
- [x] Grafit-bronz palet, kalkan/müttefik temasında 1024×1024 master ikon ✅
- [x] iOS: 1024×1024 Alpha kanalı içermeyen App Store Single Size ikonu doğrulandı ✅
- [x] macOS ikon seti: 16×16, 32×32, 128×128, 256×256, 512×512 (@1x & @2x) oluşturuldu ✅
- [x] Her iki target'ın `Assets.xcassets/AppIcon.appiconset/Contents.json` dosyaları eksiksiz tanımlandı ✅

### 6.2 App Store Ekran Görüntüleri ✅
- [x] **iPhone 6.7" (1290×2796 - App Store Connect tam uyumlu):**
  - `docs/screenshots/appstore_ios_6.7_01_chat.png` (Sohbet & Kumaş Fiyatı)
  - `docs/screenshots/appstore_ios_6.7_02_widgets.png` (Kişisel Panel & Widget Dashboard)
  - `docs/screenshots/appstore_ios_6.7_03_memory.png` (Kişisel Hafıza & Kumaş Fiyat Defteri)
  - `docs/screenshots/appstore_ios_6.7_04_settings.png` (5 Farklı Ses Tonu & Yerleşik Yapay Zekâ)
  - `docs/screenshots/appstore_ios_6.7_05_onboarding.png` (Sıfır Kurulum Karşılama)
- [x] **macOS Ekran Görüntüleri:**
  - `docs/screenshots/mac_01_main_window_clean.png` (Cam efektli ana pencere & Canlı sağ panel)
  - `docs/screenshots/mac_02_settings_window.png` (macOS Ayarlar & Ses Tercihleri)

### 6.3 App Store Metadatası ✅ TAMAMLANDI
- [x] **App Adı:** "Eris: Kişisel Asistan & Moda" (`docs/APP_STORE_METADATA.md`) ✅
- [x] **Alt Başlık:** "Sesli Asistan & Tasarım Sırdaşı" ✅
- [x] **Açıklama (Türkçe):** 4.000 karakterlik detaylı App Store tanıtım metni hazırlandı ✅
- [x] **Anahtar Kelimeler:** 100 karakterlik ASO optimizasyonu hazırlandı ✅
- [x] **Kategori:** Birincil: Productivity, İkincil: Lifestyle (`LSApplicationCategoryType: public.app-category.productivity`) ✅
- [x] **Gizlilik Politikası URL'i & Dosyası:** `docs/PRIVACY_POLICY.md` & `docs/privacy_policy.html` oluşturuldu ✅
- [x] **Destek URL'i & Dosyası:** `docs/support.html` oluşturuldu ✅
- [x] **Apple Reviewer Test Talimatları:** `docs/APP_STORE_METADATA.md` içinde hazırlandı ✅
- [x] **Yaş Derecelendirmesi:** 4+ (şiddet/kumar/alkol yok)

---

## 🔐 FAZ 7 — Güvenlik & Gizlilik Sıkılaştırma (Sprint G) ✅ TAMAMLANDI

### 7.1 Kod Güvenliği & Entitlements
- [x] `GuardrailFilter` genişletilmiş pattern listesi (prompt injection, jailbreak) ✅
- [x] `ApprovalToken` TTL ve tek kullanım doğrulaması ✅
- [x] `ErisMac.entitlements`: App Sandbox, giden ağ, ses girişi, takvim, App Group ✅
- [x] `ErisIOS.entitlements`: App Group ✅
- [x] `project.yml` hedeflerine `CODE_SIGN_ENTITLEMENTS` tanımlandı ✅

### 7.2 Gizlilik Manifestosu & İzin Metinleri
- [x] `PrivacyInfo.xcprivacy` her iki target için hazırlandı ✅
- [x] İzin metinleri tamamlandı (`NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, `NSCalendarsFullAccessUsageDescription`, `NSCalendarsUsageDescription`) ✅
- [x] Gizlilik Politikası ve Destek HTML sayfaları hazırlandı ✅

### 7.3 Veri Güvenliği Beyanı (App Store Connect)
- [x] App Store Connect Gizlilik Anketi yanıtları hazırlandı (`docs/APP_STORE_METADATA.md`) ✅

---

## 📦 FAZ 8 — Build, İmzalama & TestFlight (Sprint H) ⏳

> **Amaç:** Uygulamayı gerçek cihazlarda test edip beta dağıtımı yapmak.

### 8.1 Otomasyon & Derleme Betikleri ✅
- [x] `scripts/verify_project.sh` — Tek komutla tam sağlık ve derleme kontrolü ✅
- [x] `scripts/archive_ios.sh` — Otomatik iOS Archive oluşturucu (`ErisIOS.xcarchive`) ✅
- [x] `scripts/archive_mac.sh` — Otomatik macOS Archive oluşturucu (`ErisMac.xcarchive`) ✅
- [x] Her iki arşiv derleme testi başarıyla geçti (`** ARCHIVE SUCCEEDED **`) ✅

### 8.2 Apple Developer Hesap & İmzalama Adımları (Kullanıcı Tarafı)
- [ ] Apple Developer Portal'da App ID'leri kaydet: `com.alfagolab.eris` ve `com.alfagolab.eris.ios`
- [ ] Geliştirici Gemini API anahtarını yerleştir (`ErisAppConfig.developerApiKey`)
- [ ] `scripts/archive_ios.sh <TEAM_ID>` veya Xcode Organizer ile TestFlight'a yükle

---

## 🚀 FAZ 9 — App Store Review & Yayınlama (Sprint I) ⏳

### 9.1 Review Öncesi Son Kontrol Listesi
- [ ] **Fonksiyonalite:** Tüm özellikler çalışıyor, çökme yok
- [ ] **API anahtarı:** `ErisAppConfig.developerApiKey` içinde geçerli bir anahtar var
- [ ] **İzin metinleri:** Her kullanılan API için uygun açıklama metni
- [ ] **Gizlilik Politikası:** URL erişilebilir durumda
- [ ] **İkon:** Tüm boyutlar mevcut
- [ ] **Ekran görüntüleri:** Her desteklenen cihaz boyutu için yüklenmiş
- [ ] **Metadata:** Ad, açıklama, anahtar kelimeler eksiksiz
- [ ] **PrivacyInfo.xcprivacy:** Doğru beyanlar
- [ ] **Minimum iOS/macOS:** Info.plist'te doğru hedef versiyonlar (iOS 17.0, macOS 14.0)
- [ ] **App Transport Security:** HTTPS dışı bağlantı yok (veya exception eklenmişse gerekçesi)

### 9.2 Apple Review Beklentileri & Riskler
| Potansiyel Ret Sebebi | Önlem |
|---|---|
| Mikrofon kullanım açıklaması yetersiz | ✅ Detaylı Türkçe metin var, İngilizce eklenmeli |
| AI tarafından üretilen içerik güvenliği | ✅ GuardrailFilter aktif, NSFW/zararlı içerik filtreleme |
| Gizlilik politikası eksik | ⚠️ URL oluşturulmalı |
| Demo hesap gereksinimi | Kullanıcıdan giriş istenmez (Zero-Setup), Apple reviewer da doğrudan kullanabilir |
| Arka plan ses kaydı endişesi | Wake Word sadece aktifken dinler, kaydetmez, metinlere açıkça belirtilir |

### 9.3 Yayın Süreci
1. [ ] App Store Connect'te "Version 1.0" oluştur
2. [ ] Build yükle (TestFlight'tan seç veya yeni upload)
3. [ ] Metadata, ekran görüntüleri, açıklamalar ekle
4. [ ] Gizlilik sorularını yanıtla
5. [ ] "Submit for Review" → Apple incelemesi (genellikle 24-48 saat)
6. [ ] Onay sonrası "Release" (Manuel veya otomatik)

---

## 🔮 FAZ 10 — Yayın Sonrası & Gelecek Özellikler (Post-Launch)

### 10.1 v1.1 — İlk Güncelleme Hedefleri
- [ ] iOS WidgetKit Extension (Ana Ekran ve Kilit Ekranı widget'ları)
- [ ] Siri Shortcuts entegrasyonu ("Hey Siri, Eris'e sor...")
- [ ] İngilizce dil desteği (UI + Gemini prompt)
- [ ] iPad optimizasyonu (NavigationSplitView)

### 10.2 v1.2 — Derinleştirme
- [ ] Fotoğraf/görsel analizi (Gemini Vision): Kumaş fotoğrafı → otomatik analiz
- [ ] Gerçek zamanlı piyasa verileri (WebSocket ile canlı kur akışı)
- [ ] Apple Watch companion app (bilekte Eris brifingi)
- [ ] Sesli not → otomatik transkript → hafızaya kayıt

### 10.3 v2.0 — Abonelik & Monetizasyon
- [ ] StoreKit 2 abonelik sistemi (Aylık/Yıllık Pro plan)
- [ ] Ücretsiz katman: Günde 20 sohbet, temel widget'lar
- [ ] Pro katman: Sınırsız sohbet, tüm widget'lar, Pro model, iCloud senkron
- [ ] RevenueCat veya yerleşik StoreKit yönetimi

---

## ⏱️ Zaman Çizelgesi & Öncelik Tablosu

| Faz | Konu | Tahmini Süre | Durum |
|---|---|---|---|
| Faz 1 | Çekirdek altyapı | — | ✅ Tamamlandı |
| Faz 2 | UI, Ses, Widget, Agent | — | ✅ Tamamlandı |
| Faz 3 | Hafıza, Brifing, Servisler | — | ✅ Tamamlandı |
| **Faz 4** | **Stabilizasyon & Refaktör** | **2-3 gün** | 🔜 **Sıradaki** |
| **Faz 5** | **iCloud Senkronizasyonu** | **2-3 gün** | ⏳ Bekliyor |
| **Faz 6** | **App Store Görseller & Marka** | **1-2 gün** | ⏳ Bekliyor |
| **Faz 7** | **Güvenlik Sıkılaştırma** | **1 gün** | ⏳ Bekliyor |
| **Faz 8** | **Build, Signing & TestFlight** | **1-2 gün** | ⏳ Bekliyor |
| **Faz 9** | **App Store Review & Yayın** | **2-5 gün** (Apple review) | ⏳ Bekliyor |
| Faz 10 | Yayın Sonrası & v1.1+ | Sürekli | 🔮 Gelecek |

**Toplam tahmini kalan süre: ~10-16 gün** (Apple review süresi dahil)

---

## 📁 Proje Dosya Haritası

```
Eris/
├── Eris.xcodeproj/          # Xcode proje dosyası
├── project.yml               # XcodeGen yapılandırması
├── ErisMac/
│   ├── ErisMacApp.swift      # macOS uygulama giriş noktası (413 satır)
│   ├── MainWindowView.swift  # Ana pencere + tüm Mac view'ları (1.392 satır) ⚠️ Parçalanmalı
│   └── Resources/
│       ├── Info.plist
│       ├── PrivacyInfo.xcprivacy
│       └── Assets.xcassets/AppIcon.appiconset/
├── ErisIOS/
│   ├── ErisIOSApp.swift      # Tüm iOS kodu tek dosyada (1.954 satır) ⚠️ Parçalanmalı
│   └── Resources/
│       ├── Info.plist
│       ├── PrivacyInfo.xcprivacy
│       └── Assets.xcassets/AppIcon.appiconset/
├── Packages/ErisCore/        # Paylaşılan Swift Package
│   └── Sources/ErisCore/
│       ├── Config/           → ErisAppConfig.swift
│       ├── Models/           → Message, PendingAction, ApprovalToken, MemoryItem
│       ├── Intelligence/     → GeminiClient, ErisAgentPersonaManager
│       ├── Voice/            → ErisSpeaker, ErisVoiceListener, VoiceWaveformView
│       ├── Storage/          → KeychainManager, ErisMemoryDatabase, ErisSyncService
│       ├── Capabilities/     → CalendarCapability, ExternalDataService, MorningBriefingService, ErisWidgetManager
│       ├── Localization/     → ErisLanguage.swift (12 Dünya Dili), ErisLanguageManager.swift (L10n Sözlüğü)
│       ├── Contracts/        → SystemPromptProvider (GuardrailFilter + ErisSystemPrompt)
│       ├── Views/            → OnboardingView, ErisTheme
│       └── Resources/        → Paket kaynakları
├── contracts/
│   └── SYSTEM_PROMPT.md      # Eris persona talimatları
└── docs/
    └── PLAN.md               # ← Bu dosya
```

---

## ❓ Açık Kararlar (Yanıt Bekleniyor)

> **K1. Fiyatlandırma Stratejisi:**  
> Uygulama tamamen ücretsiz mi olacak, yoksa freemium/abonelik modeli mi?  
> *(Gemini API maliyeti kullanıcı sayısıyla artacağı için abonelik önerilir)*

> **K2. Bundle ID Birleştirme:**  
> iOS bundle ID'si `com.alfagolab.eris.ios` yerine `com.alfagolab.eris` olarak birleştirilebilir mi?  
> *(Universal Purchase için aynı olması gerekir)*

> **K3. iCloud Senkronu Önceliği:**  
> v1.0 için iCloud senkronu şart mı, yoksa v1.1'e ertelenebilir mi?  
> *(Ertelenmesi App Store'a çıkışı hızlandırır)*

> **K4. iPad Desteği:**  
> v1.0'da iPhone-only mı yoksa iPad'de de çalışmalı mı?

> **K5. Gemini API Maliyeti:**  
> Yerleşik geliştirici anahtarı ile maliyetler sizde olacak. Kullanıcı başına günlük kota limiti koymalı mıyız?
