//
//  ErisHomePantryService.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct PantryItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var category: String // "dairy", "beverage", "pantry_staple", "produce", "cleaning"
    public var isLowOrDepleted: Bool
    public var lastRestockedDate: Date?
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        isLowOrDepleted: Bool = false,
        lastRestockedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isLowOrDepleted = isLowOrDepleted
        self.lastRestockedDate = lastRestockedDate
    }
}

/// Bölüm 11, 12 & 13 ("Ev, Kiler, Yemek & Bakım") gereğince:
/// Evde azalan malzemeleri (kiler), eldeki malzemelerden pratik yemek tariflerini
/// ve ev bakım döngülerini (filtre, kombi, temizlik) takip eden Servis.
public final class ErisHomePantryService: @unchecked Sendable {
    public static let shared = ErisHomePantryService()
    
    private var pantryItems: [PantryItem] = []
    private let lock = NSLock()
    
    private init() {
        loadDefaultPantry()
    }
    
    private func loadDefaultPantry() {
        pantryItems = [
            PantryItem(name: "Espresso Kahve Çekirdeği", category: "beverage", isLowOrDepleted: true),
            PantryItem(name: "Badem Sütü", category: "dairy", isLowOrDepleted: true),
            PantryItem(name: "Sızma Zeytinyağı", category: "pantry_staple", isLowOrDepleted: false),
            PantryItem(name: "Bulaşık Tableti", category: "cleaning", isLowOrDepleted: false)
        ]
    }
    
    public func getDepletedItems() -> [PantryItem] {
        lock.lock()
        defer { lock.unlock() }
        return pantryItems.filter { $0.isLowOrDepleted }
    }
    
    public func markDepleted(name: String) {
        lock.lock()
        if let idx = pantryItems.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            pantryItems[idx].isLowOrDepleted = true
        } else {
            pantryItems.append(PantryItem(name: name, category: "general", isLowOrDepleted: true))
        }
        lock.unlock()
        
        // Açık döngü ve market checklist'ine otomatik bağla
        ErisOpenLoopsEngine.shared.addLoop(OpenLoopItem(
            domain: .homePantry,
            title: "\(name) Tükendi",
            details: "Kilerde azaldı / bitti. Bir sonraki market alışverişine eklendi.",
            detectedSource: "pantry",
            urgency: .medium,
            suggestedAction: "Rota üzerindeki markete uğra."
        ))
    }
    
    public func restock(name: String) {
        lock.lock()
        defer { lock.unlock() }
        if let idx = pantryItems.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            pantryItems[idx].isLowOrDepleted = false
            pantryItems[idx].lastRestockedDate = Date()
        }
    }
    
    /// Eldeki malzemelerden yemek önerisi üretir
    public func suggestMealFromPantry() -> String {
        let available = pantryItems.filter { !$0.isLowOrDepleted }.map { $0.name }
        if available.isEmpty {
            return "Kilerde temel malzemeler azalmış görünüyor, hafif bir sipariş veya taze market alışverişi önerilir."
        }
        return "Eldeki malzemelerle (\(available.joined(separator: ", "))): Taze zeytinyağlı Akdeniz salatası ve hafif bir akşam yemeği 15 dakikada hazırlanabilir."
    }
}
