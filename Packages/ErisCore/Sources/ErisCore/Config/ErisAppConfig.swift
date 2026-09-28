//
//  ErisAppConfig.swift
//  ErisCore
//

import Foundation

public struct ErisAppConfig: Sendable {
    /// Geliştirici Tarafından Sağlanan Gemini API Anahtarı
    /// Son kullanıcıdan ASLA API anahtarı istenmez; Eris kutudan çıktığı gibi kullanıma hazırdır.
    /// Kendi Gemini API anahtarınızı buraya tırnaklar arasına yapıştırabilir veya Info.plist içerisine `GEMINI_API_KEY` olarak ekleyebilirsiniz.
    public static var developerApiKey: String = ""
    
    /// Aktif olarak kullanılan API Anahtarı:
    /// Öncelik sırası:
    /// 1. Keychain'e manuel girilmiş özel geliştirici anahtarı (Varsa)
    /// 2. developerApiKey (Doğrudan koddan girilen anahtar)
    /// 3. Info.plist içerisindeki GEMINI_API_KEY değeri
    /// 4. ProcessInfo ortam değişkeni GEMINI_API_KEY
    public static var activeApiKey: String {
        // 1. Manuel Keychain override (Geliştirici testleri için)
        if let customKey = KeychainManager.shared.getCustomOverrideApiKey(),
           !customKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 2. Doğrudan kod içine yazılan geliştirici anahtarı
        let trimmedDevKey = developerApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDevKey.isEmpty {
            return trimmedDevKey
        }
        
        // 3. Info.plist'ten okuma
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
           !plistKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return plistKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 4. Ortam değişkeni (ProcessInfo)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return envKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return ""
    }
    
    /// Sistemin kullanıma hazır olup olmadığını belirtir.
    public static var isConfigured: Bool {
        return !activeApiKey.isEmpty
    }
}
