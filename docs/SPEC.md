# ERIS — macOS & iOS İstemcisi Ürün ve Mimari Spesifikasyonu (SPEC.md)

**Versiyon:** Faz 1 (Apple Ekosistemi: macOS 14.0+ & iOS 17.0+)  
**Diller & Çatılar:** Swift 6, SwiftUI, SwiftData / SQLite, EventKit, Speech, AVFoundation  
**Sözleşme & Güvenlik:** `contracts/` kural ve şemalarıyla %100 uyumlu sıfır-güven (Zero-Trust) mimarisi

---

## 1. Ürün Kimliği ve Deneyimi
- **Eris Kimliği:** Tok, net, yapay zekâ klişelerinden uzak ("Yapay zekayım" demez), kullanıcının çıkarlarını koruyan müttefik.
- **Dil & Zaman Dilimi:** Varsayılan Türkçe (İstanbul `Europe/Istanbul`). İtalyanca ve İngilizceye dinamik geçiş.
- **macOS Deneyimi:**
  - Menü çubuğu (MenuBar Extra / Status Item).
  - Global Kısayol (`Cmd+Shift+E`) veya Menubar hızlı paneli.
  - Canlı konuşma paneli (Audio Waveform, Barge-in, 2-3 cümle kuralı).
  - Bildirimler ve EventKit onay kartları.
- **iOS Deneyimi:**
  - Modern, zarif iOS 17 widget ve Dynamic Island uyumlu Canlı Ses arayüzü.
  - Push-to-Talk ve sesli onay ("Evet, onayla").
  - Koyu Grafit & Soğuk Bronz paleti.

---

## 2. Modüler Mimari (Swift Package + Xcode Targets)

```
Eris/
├── contracts/                  # Ortak kurallar (SYSTEM_PROMPT.md, tools, memory, approval)
├── Packages/
│   └── ErisCore/               # Paylaşılan saf Swift / SwiftData / Network katmanı
│       ├── Sources/ErisCore/
│       │   ├── Models/         # Conversation, MemoryItem, PendingAction, ApprovalToken
│       │   ├── Contracts/      # ToolDefinitions, SystemPromptProvider
│       │   ├── Intelligence/   # GeminiClient, GuardrailFilter, ToolBroker
│       │   ├── Capabilities/   # CalendarManager (EventKit), MemoryStore, WebSearch, MarketStub
│       │   └── Voice/          # SpeechRecognizer (SFSpeechRecognizer), SpeechSynthesizer (AVSpeech)
├── ErisMac/                    # macOS SwiftUI Hedefi (MenuBar + Floating Panel + Settings)
│   ├── App/
│   ├── Views/
│   └── Resources/
├── ErisIOS/                    # iOS SwiftUI Hedefi (Main Chat, Voice Sheet, Approval Sheet)
│   ├── App/
│   ├── Views/
│   └── Resources/
├── project.yml                 # XcodeGen spesifikasyonu (macOS + iOS hedefleri)
└── Eris.xcodeproj              # Otomatik derlenen Xcode projesi
```

---

## 3. Onay Kapısı ve Güvenlik Protokolü
- `propose_action` çağrıldığında sistem `ApprovalToken` üretir.
- Kullanıcı onaylamadan (UI butonu veya sesli "Evet, onayla") `execute_approved_action` çağrılamaz.
- API Key macOS Keychain / iOS Keychain içinde saklanır; asla loglanmaz veya dışa aktarılmaz.
