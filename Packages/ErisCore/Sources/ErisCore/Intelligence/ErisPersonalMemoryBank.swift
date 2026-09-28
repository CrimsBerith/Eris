//
//  ErisPersonalMemoryBank.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct UserPreferenceItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var category: String // "routine", "food", "travel", "work", "budget", "social", "clothing"
    public var key: String
    public var value: String
    public var confidence: Double // 0.0 - 1.0
    public var source: String // "explicit", "inferred"
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        category: String,
        key: String,
        value: String,
        confidence: Double = 1.0,
        source: String = "explicit",
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.key = key
        self.value = value
        self.confidence = confidence
        self.source = source
        self.updatedAt = updatedAt
    }
}

/// Bölüm 44 ("Kişisel Hafıza") gereğince:
/// Kullanıcının tekrar tekrar aynı bilgileri vermesini önleyen; tercihlerini,
/// rutinlerini, sevip sevmediği şeyleri, bütçe sınırlarını, çalışma saatlerini
/// ve kişi ilişkilerini organize eden derin kişisel hafıza katmanı.
public final class ErisPersonalMemoryBank: @unchecked Sendable {
    public static let shared = ErisPersonalMemoryBank()
    
    private var preferences: [String: UserPreferenceItem] = [:]
    private let lock = NSLock()
    
    private init() {
        loadDefaultCorePreferences()
    }
    
    private func loadDefaultCorePreferences() {
        let defaults: [UserPreferenceItem] = [
            UserPreferenceItem(category: "work", key: "working_hours", value: "09:00 - 18:30 (Hafta içi)"),
            UserPreferenceItem(category: "routine", key: "morning_routine", value: "08:00 uyanış, espresso, günün planı brifingi"),
            UserPreferenceItem(category: "commute", key: "commute_route", value: "Ev: Kadıköy/Kalamış → Ofis/Atölye: Levent"),
            UserPreferenceItem(category: "travel", key: "flight_seat", value: "Pencere kenarı, kabin boy valiz"),
            UserPreferenceItem(category: "food", key: "coffee_preference", value: "Şekersiz duble espresso veya Americano"),
            UserPreferenceItem(category: "food", key: "dietary", value: "Akdeniz mutfağı ve taze deniz ürünleri tercihi"),
            UserPreferenceItem(category: "budget", key: "shopping_policy", value: "Kaliteli ve uzun ömürlü ürün tercihi, fiyat/performans karşılaştırması")
        ]
        for item in defaults {
            preferences[item.key] = item
        }
    }
    
    // MARK: - Tercih Yönetimi
    
    public func setPreference(category: String, key: String, value: String, source: String = "explicit") {
        lock.lock()
        defer { lock.unlock() }
        let item = UserPreferenceItem(
            category: category,
            key: key,
            value: value,
            source: source,
            updatedAt: Date()
        )
        preferences[key] = item
    }
    
    public func getPreference(key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return preferences[key]?.value
    }
    
    public func allPreferences() -> [UserPreferenceItem] {
        lock.lock()
        defer { lock.unlock() }
        return Array(preferences.values).sorted(by: { $0.category < $1.category })
    }
    
    public func removePreference(key: String) {
        lock.lock()
        defer { lock.unlock() }
        preferences.removeValue(forKey: key)
    }
    
    /// LLM (Gemini) promptlarına enjekte edilecek kişisel bağlam metnini üretir
    public func generatePromptContext() -> String {
        lock.lock()
        defer { lock.unlock() }
        guard !preferences.isEmpty else { return "" }
        
        let lines = preferences.values.map { "- \($0.category.uppercased()): \($0.key) = \($0.value)" }
        return """
        [KULLANICI KİŞİSEL HAFIZASI & TERCİHLERİ]
        \(lines.joined(separator: "\n"))
        (Not: Yanıtlarını ve planlarını kullanıcının bu açık tercihlerine göre kişiselleştir.)
        """
    }
}
