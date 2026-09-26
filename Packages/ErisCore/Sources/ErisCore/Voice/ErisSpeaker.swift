import Foundation
import AVFoundation

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
    
    public var selectedGender: ErisVoiceGender = .male
    public var onSpeakingFinished: (@Sendable () -> Void)?
    public var onSpeakingStarted: (@Sendable () -> Void)?
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    public func speak(_ text: String, language: String = "tr-TR") {
        stopSpeaking()
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Türkçe sesler arasından cinsiyete en uygun olanı bul
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.starts(with: "tr") }
        if let matchedVoice = voices.first(where: { voice in
            if selectedGender == .female {
                return voice.gender == .female || voice.name.lowercased().contains("yelda") || voice.name.lowercased().contains("female")
            } else {
                return voice.gender == .male || voice.name.lowercased().contains("cem") || voice.name.lowercased().contains("male")
            }
        }) {
            utterance.voice = matchedVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }
        
        // Karakteristik Eris parametreleri: Tok, sakin, net
        if selectedGender == .male {
            utterance.pitchMultiplier = 0.84 // Derin, tok erkek
        } else {
            utterance.pitchMultiplier = 0.95 // Soğukkanlı, net kadın
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.94
        utterance.volume = 1.0
        
        onSpeakingStarted?()
        synthesizer.speak(utterance)
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
