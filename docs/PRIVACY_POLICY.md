# ERIS — Gizlilik Politikası (Privacy Policy)
**Son Güncelleme:** 28 Eylül 2026  
**Uygulama Adı:** Eris (macOS & iOS)  
**Geliştirici:** AlfaGo Lab  
**İletişim:** support@alfagolab.com

---

## 1. Giriş
AlfaGo Lab ("biz", "bizim"), kullanıcılarımızın gizliliğine en yüksek derecede saygı duyar. Eris uygulaması, **Gizlilik Önce (Privacy-First)** ve **Sıfır-Güven (Zero-Trust)** mimarisiyle tasarlanmıştır. Bu Gizlilik Politikası, uygulamayı kullandığınızda verilerinizin nasıl işlendiğini, korunduğunu ve haklarınızı açıklar.

## 2. Toplanan ve İşlenen Veriler

### a. Ses Verileri ve Konuşma Tanıma
- **Kullanım Amacı:** Sesli komutlarınızı çözümlemek ("Hey Eris", push-to-talk) ve Eris ile doğal sesli diyalog kurabilmeniz içindir.
- **İşleme Biçimi:** Ses tanıma işlemi Apple'ın yerel Speech Framework (`SFSpeechRecognizer`) ve ses altyapısı (`AVAudioEngine`) üzerinden gerçekleştirilir. Ses kayıtlarınız sunucularımızda ASLA depolanmaz veya saklanmaz.

### b. Takvim Verileri (EventKit)
- **Kullanım Amacı:** Günün ajandasını sesli brifing olarak okumak ve yalnızca sizin açık onayınızla yeni etkinlik kaydetmek.
- **İşleme Biçimi:** Takvim verileri tamamen cihazınızda (on-device) okunur. Hiçbir takvim içeriği üçüncü şahıslara veya reklam ağlarına iletilmez.

### c. Kişisel Hafıza ve Notlar (SQLite)
- **Kullanım Amacı:** Kumaş fiyatları, tedarikçi bilgileri, tasarım ve drape fikirleri ile kişisel tercihlerinizi saklamak.
- **İşleme Biçimi:** Hafıza verileriniz cihazınızda yerel şifreli SQLite veritabanında tutulur. Cihazlar arası eşitleme için yalnızca Apple'ın kendi güvenli iCloud Key-Value altyapısı (`NSUbiquitousKeyValueStore`) kullanılır.

### d. Yapay Zekâ İşleme (Google Gemini API)
- **Kullanım Amacı:** Moda tasarımı analizi, kumaş maliyet-fayda değerlendirmesi, seyir rehberliği ve sohbet yanıtları üretmek.
- **İşleme Biçimi:** Sorularınız ve ilgili bağlam, güvenli HTTPS bağlantısı üzerinden Google Gemini API'sine anlık (ephemeral) olarak iletilir ve yanıt alındıktan sonra işleme tamamlanır. Bu veriler model eğitimi amacıyla kullanılmaz.

## 3. Takip (Tracking) ve Çerezler
- Eris **hiçbir kullanıcı takip teknolojisi (IDFA, üçüncü taraf reklam izleyicileri) KULLANMAZ**.
- Apple Privacy Manifest (`PrivacyInfo.xcprivacy`) dosyamızda `NSPrivacyTracking: false` olarak tescil edilmiştir.

## 4. Kullanıcı Hesabı & Sıfır-Kurulum (Zero-Setup)
- Eris'i kullanmak için bir hesap açmanız, e-posta veya parola girmeniz gerekmez.
- Yapay zekâ erişimi doğrudan yerleşik geliştirici altyapısıyla sağlanır.

## 5. Veri Güvenliği
- Tüm dış iletişim şifreli HTTPS/TLS protokolüyle sağlanır.
- API anahtarları ve hassas veriler işletim sisteminin güvenli kasası olan **Apple Keychain** üzerinde saklanır.

## 6. Çocukların Gizliliği
Eris 4+ yaş derecelendirmesine uygundur ve çocuklardan bilerek herhangi bir kişisel veri toplamaz.

## 7. İletişim & Haklarınız
Verileriniz cihazınızda saklandığı için dilediğiniz an Ayarlar > Hafıza sekmesinden tüm kayıtları tek tek veya topluca silebilirsiniz. Her türlü soru için:  
📧 **E-posta:** support@alfagolab.com  
🌐 **Web:** https://alfagolab.com
