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
    
    public var pitchMultiplier: Float {
        switch self {
        case .derinBariton: return 0.72
        case .tokErkek: return 0.82
        case .minimalistDirekt: return 0.88
        case .sicakKadin: return 0.96
        case .dinamikPartner: return 1.02
        }
    }
    
    public var rateMultiplier: Float {
        switch self {
        case .derinBariton: return 0.88
        case .tokErkek: return 0.92
        case .minimalistDirekt: return 0.96
        case .sicakKadin: return 0.95
        case .dinamikPartner: return 1.03
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
    
    public var onSpeakingFinished: (@Sendable () -> Void)?
    public var onSpeakingStarted: (@Sendable () -> Void)?
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    public func speak(_ text: String, language: String? = nil) {
        let activeLang = language ?? ErisLanguageManager.shared.currentLanguage.bcp47Locale
        speak(text, tone: selectedTone, language: activeLang)
    }
    
    public func speak(_ text: String, tone: ErisVoiceTone, language: String? = nil) {
        stopSpeaking()
        
        let targetLanguage = language ?? ErisLanguageManager.shared.currentLanguage.bcp47Locale
        let utterance = AVSpeechUtterance(string: text)
        
        let langPrefix = String(targetLanguage.prefix(2)).lowercased()
        let matchingVoices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.lowercased().starts(with: langPrefix)
        }
        
        var candidateVoices = matchingVoices.filter { voice in
            if tone.isFemalePreferred {
                return voice.gender == .female || voice.name.lowercased().contains("female") || voice.name.lowercased().contains("yelda") || voice.name.lowercased().contains("samantha") || voice.name.lowercased().contains("karen")
            } else {
                return voice.gender == .male || voice.name.lowercased().contains("male") || voice.name.lowercased().contains("cem") || voice.name.lowercased().contains("daniel") || voice.name.lowercased().contains("alex")
            }
        }
        
        if candidateVoices.isEmpty {
            candidateVoices = matchingVoices
        }
        
        // Premium / Enhanced kaliteye öncelik ver
        let sortedVoices = candidateVoices.sorted { v1, v2 in
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
        
        // Seçilen tonun karakteristik parametreleri
        utterance.pitchMultiplier = tone.pitchMultiplier
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * tone.rateMultiplier
        utterance.volume = 1.0
        
        onSpeakingStarted?()
        synthesizer.speak(utterance)
    }
    
    public func previewTone(_ tone: ErisVoiceTone) {
        let sample = L10n.voiceToneSampleText(tone)
        speak(sample, tone: tone)
    }
    
    public var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
    
    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onSpeakingFinished?()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onSpeakingFinished?()
    }
}
