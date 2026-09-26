# ERIS — Tam Ürün Planı (macOS + iOS)
**Versiyon:** 1.0 Yol Haritası  
**Platform:** macOS 14+ & iOS 17+  
**Mimari:** Swift 6, SwiftUI, ErisCore (paylaşılan Swift Package)  
**Son Güncelleme:** 2026-09-26

---

## Temel Prensipler
- **Sıfır-Güven (Zero-Trust):** Hiçbir yan etkili eylem onaysız yürütülmez
- **Tok & Doğrudan:** Yapay zekâ klişeleri yok, 2-3 cümle ses kuralı
- **Premium His:** Glassmorphism, ses dalgası animasyonu, cam efektleri
- **Gizlilik Önce:** API anahtarı Keychain'de, hafıza yerel şifreli SQLite, hiçbir veri üçüncü şahıslara gitmez

---

## FAZ 1 — Çekirdek Altyapı (Sprint A) ✅ TAMAMLANDI

- [x] `Message`, `PendingAction`, `ApprovalToken`, `MemoryItem` modelleri
- [x] `GeminiClient` — Gemini 1.5 Flash REST API entegrasyonu
- [x] `GuardrailFilter` — Jailbreak ve prompt sızdırma engeli
- [x] `ErisSystemPrompt` — Persona ve İstanbul saat dilimi enjeksiyonu
- [x] `KeychainManager` — macOS/iOS Keychain ile güvenli API Key saklama
- [x] `CalendarCapability` — EventKit okuma/yazma (onaylı)
- [x] `ErisSpeaker` — AVSpeechSynthesizer tok ses profili (perde: 0.88)
- [x] Xcode projesi `ErisMac` ve `ErisIOS` hedefleri — **BUILD SUCCEEDED** ✅

---

## FAZ 2 — Tasarım ve Ses Sistemi (Sprint B) 🔜 SIRADAKI

### 2.1 Premium UI — Glassmorphism
**macOS:**
- [ ] Cam / Blur efekti pencere arka planı (`.ultraThinMaterial`)
- [ ] Grafit `#121316`, bronz vurgu `#A39890`, soğuk beyaz `#E5E5E7`
- [ ] Mesaj baloncukları — blur backdrop, ince bronz kenar ışıması
- [ ] Compact Floating Panel (AlwaysOnTop) — ekranın sağ altından kayan
- [ ] `VoiceWaveView` — canlı ses dalgası animasyonu (dinleme/konuşma)
- [ ] Durum mikro-animasyonları: Dinliyor… → Düşünüyor… → Konuşuyor…
- [ ] MenuBarExtra — bronz nokta animasyonu (aktif konuşma varken)

**iOS:**
- [ ] Tüm ekranlar koyu glassmorphism teması
- [ ] Sohbet baloncukları — blur material, ince kenar glow
- [ ] `VoiceWaveView` inline ses dalgası
- [ ] Bottom sheet navigasyonu (Chat / Hafıza / Ayarlar)

### 2.2 Ses ve Konuşma Sistemi
- [ ] Hem Türkçe erkek hem kadın sesi (ayarlardan seçim)
- [ ] `SFSpeechRecognizer` Türkçe STT entegrasyonu
- [ ] `AVAudioEngine` mikrofon pipeline
- [ ] Barge-in: Kullanıcı konuşunca TTS anında susur
- [ ] Cloud STT açıklamasıyla onboarding rıza akışı

### 2.3 Wake Word — "Hey Eris"
- [ ] `SFSpeechRecognizer` sürekli keyphrase dinlemesi
- [ ] Algılandığında Compact Panel otomatik açılır ve dinleme başlar
- [ ] Pil/CPU optimizasyonu (düşük örnekleme hızı)
- [ ] Ayardan Wake Word açma/kapama toggle

### 2.4 Push-to-Talk Kısayolları
- [ ] macOS: `Cmd+Shift+E` global kısayol (`CGEvent`)
- [ ] iOS: Büyük mikrofon butonuna uzun basma

---

## FAZ 3 — Yetenekler & Entegrasyonlar (Sprint C) ⏳

### 3.1 Takvim — Tamamlama
- [ ] Oturumda takvim bağlam paneline otomatik eklenmesi
- [ ] Etkinlik oluşturma, silme, listeleme (tümü onaylı)
- [ ] Doğal dil tarih çözümleme — *"Yarın öğleden sonra"* → `Date` (İstanbul TZ)

### 3.2 Kişisel Hafıza Motoru (Memory Engine)
- [ ] Yerel şifreli SQLite (GRDB veya FMDB + CryptoKit)
- [ ] Hafıza kategorileri (tümü seçildi):
  - `preference` — Tercihler ve alışkanlıklar
  - `project` — Projeler ve tekrarlayan görevler
  - `person` — Önemli kişiler (iş, aile, arkadaş)
  - `finance` — Piyasa tercihleri (semboller, portföy)
  - `maritime` — Deniz / tekne / seyahat
  - `instruction` — Eris'e verilen kalıcı talimatlar
- [ ] "Bunu hatırla" komutu → `pin_memory` (onay gerektirir)
- [ ] Hafıza öğeleri her sohbet bağlamına otomatik eklenir
- [ ] Hafıza yönetim ekranı (listeleme, düzenleme, silme)

### 3.3 Sabah Brifingi (Morning Briefing)
- [ ] Kullanıcının seçtiği saatte `UserNotifications` tetikler
- [ ] İçerik: Takvim + Hava + Piyasa + Önemli notlar
- [ ] macOS: TTS ile sesli brifing okuma seçeneği
- [ ] iOS: Bildirim → açıldığında brifing ekranı

### 3.4 Harici Servisler (tümü seçildi)
- [ ] **Web araştırması:** DuckDuckGo Instant Answer API veya Serper.dev
- [ ] **Hava durumu:** Apple WeatherKit (ekstra lisans ücreti yok, Apple dev hesabıyla)
- [ ] **Döviz & Borsa:** ExchangeRate API + Alpha Vantage (kullanıcı sembol listesi)
- [ ] **Deniz durumu:** Stormglass API veya OpenMarine
- [ ] **Kullanıcı tanımlı servisler:** Ayarlardan ek API endpoint ekleme (ileriki)

> Tüm harici çıktılar `untrusted` — model özetler, doğrudan aksiyona dönüştürmez

---

## FAZ 4 — iPhone ↔ Mac Senkronizasyonu (Sprint D) ⏳

- [ ] `CloudKit` ile iCloud senkronizasyonu (konuşma geçmişi + hafıza + tercihler)
- [ ] Bağımsız çalışma modu: iCloud yoksa yerel çalışmaya devam
- [ ] Çakışma çözümü: Last-write-wins
- [ ] Senkronize edilecekler:
  - Son N konuşma mesajı
  - Sabitlenmiş hafıza öğeleri (öncelikli)
  - Ses profili ve kullanıcı tercihleri

---

## FAZ 5 — Onboarding & Güvenlik (Sprint E) ⏳

### 5.1 Onboarding (7 Adım)
1. Karşılama — Eris'in karakteri ve güvencesi
2. Gemini API Key girişi → Keychain kayıt
3. Mikrofon + Konuşma Tanıma izni (Cloud STT açıklaması)
4. Takvim erişim izni (onay kapısı açıklanır)
5. Ses profili seçimi (erkek/kadın)
6. Wake Word açma/kapama
7. Sabah Brifingi saati (isteğe bağlı)

### 5.2 Güvenlik Sıkılaştırma
- [ ] `GuardrailFilter` genişletilmiş pattern listesi
- [ ] `ApprovalToken` TTL ve tek kullanım doğrulaması sıkılaştırma
- [ ] Keychain politikası: `whenUnlockedThisDeviceOnly` seçeneği

---

## FAZ 6 — App Store Hazırlığı (Sprint F) ⏳

- [ ] Tüm izin metinleri Türkçe + İngilizce
- [ ] App Store ikon seti — grafit-bronz palet, kalkan/gözlemci teması
- [ ] App Store ekran görüntüleri (macOS 13" + iOS 6.7")
- [ ] `PrivacyInfo.xcprivacy` (Apple gizlilik manifestosu)
- [ ] TestFlight beta dağıtımı — v1.0 Build 1
- [ ] Crash raporlama (Sentry.io)

---

## Öncelik Tablosu

| Faz | Konu | Durum |
|---|---|---|
| Faz 1 | Çekirdek altyapı, Keychain, EventKit | ✅ Tamamlandı |
| Faz 2 | Glassmorphism UI, Wake Word, Ses | 🔜 Sıradaki |
| Faz 3 | Hafıza, Brifing, Harici Servisler | ⏳ Bekliyor |
| Faz 4 | iCloud Senkronizasyonu | ⏳ Bekliyor |
| Faz 5 | Onboarding, Güvenlik | ⏳ Bekliyor |
| Faz 6 | App Store, TestFlight | ⏳ Bekliyor |

---

## Açık Kararlar (Yanıt Bekleniyor)

> **S1. Gemini Modeli:** Varsayılan `gemini-1.5-flash` (hız) mı, `gemini-1.5-pro` (derinlik) mi?  
> (Öneri: Flash varsayılan, ayarlardan Pro'ya geçiş yapılabilsin)

> **S2. Piyasa Sembolleri:** BIST100, USDTRY, EURTRY, XAUUSD, BTC hazır liste mi gelsin, yoksa kullanıcı kendi listesini oluştursun mu?

> **S3. Deniz Konumu:** Sabit bir liman mı girilsin (örn. Kalamış/İstanbul), yoksa dinamik GPS ile mi sorulsun?
