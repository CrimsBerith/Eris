//
//  ContextualTrigger.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public enum TriggerType: String, Codable, CaseIterable, Sendable {
    case time = "time"               // Belirli tarih ve saat
    case location = "location"       // Coğrafi çit (Geofence): Varış veya ayrılış
    case person = "person"           // Belirli kişiyle iletişim veya buluşma anı
    case condition = "condition"     // Hava (yağmur, kar), batarya, fiyat değişimi
    case preparation = "preparation" // Bir etkinlikten X dakika / saat önce
    
    public var displayName: String {
        switch self {
        case .time: return "Zaman Tabanlı"
        case .location: return "Konum Tabanlı (Geofence)"
        case .person: return "Kişi Bağlamlı"
        case .condition: return "Koşul / Hava Durumu"
        case .preparation: return "Hazırlık & Ön Süre"
        }
    }
}

public struct ContextualTrigger: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var type: TriggerType
    public var title: String
    public var promptText: String
    public var isFired: Bool
    public var isActive: Bool
    
    // Parametreler
    public var scheduledDate: Date?
    public var locationName: String?
    public var latitude: Double?
    public var longitude: Double?
    public var radiusMeters: Double?
    public var notifyOnEntry: Bool
    
    public var targetPersonName: String?
    public var weatherConditionRequired: String? // "rain", "snow", "extreme_heat"
    public var minutesBeforeEvent: Int?
    public var associatedEventId: String?
    
    public init(
        id: UUID = UUID(),
        type: TriggerType,
        title: String,
        promptText: String,
        isFired: Bool = false,
        isActive: Bool = true,
        scheduledDate: Date? = nil,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radiusMeters: Double? = 200,
        notifyOnEntry: Bool = true,
        targetPersonName: String? = nil,
        weatherConditionRequired: String? = nil,
        minutesBeforeEvent: Int? = nil,
        associatedEventId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.promptText = promptText
        self.isFired = isFired
        self.isActive = isActive
        self.scheduledDate = scheduledDate
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.notifyOnEntry = notifyOnEntry
        self.targetPersonName = targetPersonName
        self.weatherConditionRequired = weatherConditionRequired
        self.minutesBeforeEvent = minutesBeforeEvent
        self.associatedEventId = associatedEventId
    }
}
