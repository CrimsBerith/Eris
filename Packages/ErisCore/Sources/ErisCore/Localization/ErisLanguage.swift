//
//  ErisLanguage.swift
//  ErisCore
//

import Foundation

public enum ErisLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"       // 🇺🇸 İngilizce — en güçlü
    case turkish = "tr"       // 🇹🇷 Türkçe — oldukça iyi
    case spanish = "es"       // 🇪🇸 İspanyolca
    case french = "fr"        // 🇫🇷 Fransızca
    case german = "de"        // 🇩🇪 Almanca
    case italian = "it"       // 🇮🇹 İtalyanca
    case portuguese = "pt"    // 🇵🇹 Portekizce
    case japanese = "ja"      // 🇯🇵 Japonca
    case chinese = "zh"       // 🇨🇳 Çince (Mandarin)
    case korean = "ko"        // 🇰🇷 Korece
    case russian = "ru"       // 🇷🇺 Rusça
    case dutch = "nl"         // 🇳🇱 Hollandaca
    
    public var id: String { rawValue }
    
    public var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .turkish: return "🇹🇷"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇵🇹"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        case .korean: return "🇰🇷"
        case .russian: return "🇷🇺"
        case .dutch: return "🇳🇱"
        }
    }
    
    public var nativeName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .japanese: return "日本語"
        case .chinese: return "中文 (简体)"
        case .korean: return "한국어"
        case .russian: return "Русский"
        case .dutch: return "Nederlands"
        }
    }
    
    public var englishName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Turkish"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .japanese: return "Japanese"
        case .chinese: return "Chinese (Mandarin)"
        case .korean: return "Korean"
        case .russian: return "Russian"
        case .dutch: return "Dutch"
        }
    }
    
    public var displayName: String {
        "\(flag) \(nativeName)"
    }
    
    public var bcp47Locale: String {
        switch self {
        case .english: return "en-US"
        case .turkish: return "tr-TR"
        case .spanish: return "es-ES"
        case .french: return "fr-FR"
        case .german: return "de-DE"
        case .italian: return "it-IT"
        case .portuguese: return "pt-PT"
        case .japanese: return "ja-JP"
        case .chinese: return "zh-CN"
        case .korean: return "ko-KR"
        case .russian: return "ru-RU"
        case .dutch: return "nl-NL"
        }
    }
    
    public var speechLocale: Locale {
        Locale(identifier: bcp47Locale)
    }
    
    /// Dilin genel ses ve yapay zeka güç sıralaması etiketi
    public var strengthBadge: String? {
        switch self {
        case .english: return "Global Core"
        case .turkish: return "Native"
        default: return nil
        }
    }
}
