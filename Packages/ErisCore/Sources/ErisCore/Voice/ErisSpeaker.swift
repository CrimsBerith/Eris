import Foundation
import AVFoundation

public enum ErisVoiceTone: String, Codable, CaseIterable, Sendable, Identifiable {
    case tokErkek = "tok_erkek"
    case sicakKadin = "sicak_kadin"
    case derinBariton = "derin_bariton"
    case dinamikPartner = "dinamik_partner"
    case minimalistDirekt = "minimalist_direkt"
    
    public var id: String { rawValue }
    
    public var title: String {
        L10n.voiceToneTitle(self)
    }
    
    public var subtitle: String {
        switch self {
        case .tokErkek: return "Cebindeki güvenilir dost, derin ve sakin tını"
        case .sicakKadin: return "İlham veren yaratıcı sağ kol, sıcak ve akıcı"
        case .derinBariton: return "Huzur veren, düşük perdeli koruyucu rehber"
        case .dinamikPartner: return "Hızlı, canlı ve tempolu tasarım ortağı"
        case .minimalistDirekt: return "Net, lafı uzatmayan profesyonel stüdyo tonu"
        }
    }
    
    /// Doğal insan frekansını bozmayan, metalik robot efektini engelleyen perde çarpanı (0.95 - 1.03)
    public var pitchMultiplier: Float {
        switch self {
        case .derinBariton: return 0.95
        case .tokErkek: return 0.98
        case .minimalistDirekt: return 1.00
        case .sicakKadin: return 1.01
        case .dinamikPartner: return 1.03
        }
    }
    
    /// Doğal nefes ve duraklama aralığında konuşma hızı çarpanı
    public var rateMultiplier: Float {
        switch self {
        case .derinBariton: return 0.90
        case .tokErkek: return 0.93
        case .minimalistDirekt: return 0.98
        case .sicakKadin: return 0.95
        case .dinamikPartner: return 1.02
        }
    }
    
    public var isFemalePreferred: Bool {
        return self == .sicakKadin
    }
    
    public var sampleText: String {
        L10n.voiceToneSampleText(self)
    }
}

public enum ErisVoiceGender: String, Codable, CaseIterable, Sendable {
    case male = "male"
    case female = "female"
    
    public var displayName: String {
        switch self {
        case .male: return "Tok Erkek Sesi"
        case .female: return "Sakin Kadın Sesi"
        }
    }
}

public final class ErisSpeaker: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    public static let shared = ErisSpeaker()
    private let synthesizer = AVSpeechSynthesizer()
    
    public var selectedTone: ErisVoiceTone {
        get {
            if let saved = UserDefaults.standard.string(forKey: "eris_selected_voice_tone"),
               let tone = ErisVoiceTone(rawValue: saved) {
                return tone
            }
            return .tokErkek
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "eris_selected_voice_tone")
        }
    }
    
    public var selectedGender: ErisVoiceGender {
        get { selectedTone.isFemalePreferred ? .female : .male }
        set { selectedTone = newValue == .female ? .sicakKadin : .tokErkek }
    }
    
    /// Nöral ses (OpenAI TTS) kullanılabilir olduğunda aktif olsun mu?
    public var useNeuralVoiceIfAvailable: Bool {
        get { UserDefaults.standard.object(forKey: "eris_use_neural_voice") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "eris_use_neural_voice") }
    }
    
    public var onSpeakingFinished: (@Sendable () -> Void)?
    public var onSpeakingStarted: (@Sendable () -> Void)?
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        
        // Nöral ses motoru olaylarını ErisSpeaker delegasyonuna bağla
        ErisNeuralSpeaker.shared.onSpeakingStarted = { [weak self] in
            self?.onSpeakingStarted?()
        }
        ErisNeuralSpeaker.shared.onSpeakingFinished = { [weak self] in
            self?.onSpeakingFinished?()
        }
    }
    
    // MARK: - Metin Temizliği (Markdown, Kod, Emoji & Teknik Simgeleri Ayıklama)
    
    /// Konuşma motorunun takılmadan, doğal bir insan gibi akıcı okuması için metni arındırır.
    public static func cleanTextForSpeech(_ text: String) -> String {
        var clean = text
        
        // 1. Kod bloklarını temizle (```...``` ve `...`)
        clean = clean.replacingOccurrences(of: #"(?s)```.*?```"#, with: " ", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"`.*?`"#, with: " ", options: .regularExpression)
        
        // 2. URL'leri temizle (http:// / https://)
        clean = clean.replacingOccurrences(of: #"https?://\S+"#, with: " ", options: .regularExpression)
        
        // 3. Markdown başlık işaretlerini kaldır (### Başlık)
        clean = clean.replacingOccurrences(of: #"(?m)^#{1,6}\s*"#, with: " ", options: .regularExpression)
        
        // 4. Markdown kalın ve italik işaretlerini kaldır (**metin**, *metin*)
        clean = clean.replacingOccurrences(of: #"\*{1,3}(.*?)\*{1,3}"#, with: "$1", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"_{1,3}(.*?)_{1,3}"#, with: "$1", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"~{2}(.*?)~{2}"#, with: "$1", options: .regularExpression)
        
        // 5. Madde ve numaralandırma sembollerini kaldır (•, -, *, 1.)
        clean = clean.replacingOccurrences(of: #"(?m)^\s*[\•\-\*]\s+"#, with: " ", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"(?m)^\s*\d+[\.\)]\s+"#, with: " ", options: .regularExpression)
        
        // 6. Sistem etiketlerini ve parantez içi teknik meta verileri kaldır
        clean = clean.replacingOccurrences(of: #"\[.*?\]"#, with: " ", options: .regularExpression)
        
        // 7. Emojileri temizle (TTS'in garip kelimeler söylemesini engeller)
        clean = clean.unicodeScalars.filter { scalar in
            if scalar.properties.isEmoji { return false }
            if scalar.value == 0xFE0F || scalar.value == 0xFE0E { return false }
            if (scalar.value >= 0x1F300 && scalar.value <= 0x1FAFF) || (scalar.value >= 0x2600 && scalar.value <= 0x27BF) {
                return false
            }
            return true
        }.reduce("") { $0 + String($1) }
        
        // 8. Fazla boşlukları ve noktalama yığılmalarını düzelt
        clean = clean.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"\.{2,}"#, with: ".", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"\?{2,}"#, with: "?", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"\!{2,}"#, with: "!", options: .regularExpression)
        
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? text : clean
    }
    
    // MARK: - Seslendirme Giriş Noktaları
    
    public func speak(_ text: String, language: String? = nil) {
        let activeLang = language ?? ErisLanguageManager.shared.currentLanguage.bcp47Locale
        speak(text, tone: selectedTone, language: activeLang)
    }
    
    public func speak(_ text: String, tone: ErisVoiceTone, language: String? = nil) {
        stopSpeaking()
        
        let cleanedText = Self.cleanTextForSpeech(text)
        guard !cleanedText.isEmpty else { return }
        
        // MARK: 1. Nöral AI Ses (OpenAI TTS) Kontrolü — Varsa stüdyo kalitesinde çal
        if useNeuralVoiceIfAvailable && ErisAppConfig.isNeuralVoiceAvailable {
            Task { [weak self] in
                guard let self = self else { return }
                let played = await ErisNeuralSpeaker.shared.speak(text: cleanedText, tone: tone)
                if !played {
                    // Nöral ses ağ hatası verirse, yerel Apple TTS ile devam et (fallback)
                    await MainActor.run {
                        self.speakNative(cleanedText, tone: tone, language: language)
                    }
                }
            }
            return
        }
        
        // MARK: 2. Optimize Edilmiş Apple Yerel Motoru
        speakNative(cleanedText, tone: tone, language: language)
    }
    
    // MARK: - Apple Yerel TTS (Doğal İnsan Perdesi & Gelişmiş Ses Seçimi)
    
    private func speakNative(_ text: String, tone: ErisVoiceTone, language: String? = nil) {
        let targetLanguage = language ?? ErisLanguageManager.shared.currentLanguage.bcp47Locale
        let utterance = AVSpeechUtterance(string: text)
        
        let langPrefix = String(targetLanguage.prefix(2)).lowercased()
        let matchingVoices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.lowercased().starts(with: langPrefix)
        }
        
        // Cinsiyet ve karakter eşleşmesi
        var candidateVoices = matchingVoices.filter { voice in
            let nameLower = voice.name.lowercased()
            if tone.isFemalePreferred {
                return voice.gender == .female || nameLower.contains("female") || nameLower.contains("yelda") || nameLower.contains("siri")
            } else {
                return voice.gender == .male || nameLower.contains("male") || nameLower.contains("cem") || nameLower.contains("daniel") || nameLower.contains("siri")
            }
        }
        
        if candidateVoices.isEmpty {
            candidateVoices = matchingVoices
        }
        
        // Siri > Premium > Enhanced > Default sıralaması
        let sortedVoices = candidateVoices.sorted { v1, v2 in
            let v1IsSiri = v1.name.lowercased().contains("siri") ? 1 : 0
            let v2IsSiri = v2.name.lowercased().contains("siri") ? 1 : 0
            if v1IsSiri != v2IsSiri {
                return v1IsSiri > v2IsSiri
            }
            if #available(macOS 13.0, iOS 16.0, *) {
                return v1.quality.rawValue > v2.quality.rawValue
            }
            return false
        }
        
        if let bestVoice = sortedVoices.first {
            utterance.voice = bestVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: targetLanguage)
        }
        
        // Doğal insan konuşması parametreleri
        utterance.pitchMultiplier = tone.pitchMultiplier
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * tone.rateMultiplier
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.04
        utterance.postUtteranceDelay = 0.08
        
        onSpeakingStarted?()
        synthesizer.speak(utterance)
    }
    
    public func previewTone(_ tone: ErisVoiceTone) {
        let sample = L10n.voiceToneSampleText(tone)
        speak(sample, tone: tone)
    }
    
    public var isSpeaking: Bool {
        synthesizer.isSpeaking || ErisNeuralSpeaker.shared.isSpeaking
    }
    
    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        ErisNeuralSpeaker.shared.stop()
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onSpeakingFinished?()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onSpeakingFinished?()
    }
}
