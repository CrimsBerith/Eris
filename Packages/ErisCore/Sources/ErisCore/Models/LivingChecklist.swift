//
//  LivingChecklist.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public enum ChecklistType: String, Codable, CaseIterable, Sendable {
    case travelPacking = "travel_packing"       // Seyahat bavul listesi
    case groceryPantry = "grocery_pantry"       // Market & kiler listesi
    case homeChores = "home_chores"             // Ev temizlik & bakım
    case relocationMoving = "relocation_moving" // Taşınma kontrol listesi
    case eventPreparation = "event_prep"        // Etkinlik & misafir hazırlığı
    case vehicleMaintenance = "vehicle_prep"    // Araç uzun yol hazırlığı
    case custom = "custom"                      // Özel liste
    
    public var displayName: String {
        switch self {
        case .travelPacking: return "Seyahat & Bavul"
        case .groceryPantry: return "Market & Kiler"
        case .homeChores: return "Ev & Rutin Bakım"
        case .relocationMoving: return "Taşınma Planı"
        case .eventPreparation: return "Etkinlik & Misafir"
        case .vehicleMaintenance: return "Araç Uzun Yol"
        case .custom: return "Özel Liste"
        }
    }
    
    public var icon: String {
        switch self {
        case .travelPacking: return "suitcase.fill"
        case .groceryPantry: return "cart.fill"
        case .homeChores: return "sparkles"
        case .relocationMoving: return "shippingbox.fill"
        case .eventPreparation: return "wineglass.fill"
        case .vehicleMaintenance: return "car.fill"
        case .custom: return "checklist"
        }
    }
}

public struct ChecklistItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var category: String?
    public var note: String?
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, category: String? = nil, note: String? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.category = category
        self.note = note
    }
}

/// Bölüm 38 gereğince: Yaşayan Checklists — Hayatın Sürekli Değişen Listeleri.
public struct LivingChecklist: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var type: ChecklistType
    public var items: [ChecklistItem]
    public var targetDate: Date?
    public var destinationCity: String?
    public var weatherNote: String?
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        type: ChecklistType,
        items: [ChecklistItem] = [],
        targetDate: Date? = nil,
        destinationCity: String? = nil,
        weatherNote: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.items = items
        self.targetDate = targetDate
        self.destinationCity = destinationCity
        self.weatherNote = weatherNote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    public var progressFraction: Double {
        guard !items.isEmpty else { return 0.0 }
        return Double(completedCount) / Double(items.count)
    }
}
