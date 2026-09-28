//
//  OpenLoopItem.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public enum LoopUrgency: String, Codable, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    public var displayName: String {
        switch self {
        case .low: return "Düşük"
        case .medium: return "Orta"
        case .high: return "Yüksek"
        case .urgent: return "Kritik Acil"
        }
    }
}

public enum LoopStatus: String, Codable, CaseIterable, Sendable {
    case detected = "detected"           // Tespit edildi, işlem bekliyor
    case scheduled = "scheduled"         // Takvime veya plana bağlandı
    case waitingApproval = "waiting"     // Kullanıcı onayı bekliyor
    case completed = "completed"         // Çözüldü / Kapatıldı
    case dismissed = "dismissed"         // Kullanıcı tarafından reddedildi / göz ardı edildi
    
    public var displayName: String {
        switch self {
        case .detected: return "Açık İş"
        case .scheduled: return "Planlandı"
        case .waitingApproval: return "Onay Bekliyor"
        case .completed: return "Tamamlandı"
        case .dismissed: return "Kapatıldı"
        }
    }
}

/// Kullanıcının hayatındaki zihinsel yükü ve açık döngüleri (Open Loops) temsil eden model.
/// (Örn: Cevapsız e-posta, yaklaşan fatura, yenilenecek abonelik, araç muayenesi, yarım kalan işler)
public struct OpenLoopItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var domain: ErisLifeDomain
    public var title: String
    public var details: String
    public var detectedSource: String // "voice", "calendar", "note", "email", "chat"
    public var urgency: LoopUrgency
    public var status: LoopStatus
    public var suggestedAction: String
    public var dueDate: Date?
    public var requiresUserApproval: Bool
    public var approvalTicketId: UUID?
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        domain: ErisLifeDomain,
        title: String,
        details: String = "",
        detectedSource: String = "chat",
        urgency: LoopUrgency = .medium,
        status: LoopStatus = .detected,
        suggestedAction: String = "",
        dueDate: Date? = nil,
        requiresUserApproval: Bool = false,
        approvalTicketId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.domain = domain
        self.title = title
        self.details = details
        self.detectedSource = detectedSource
        self.urgency = urgency
        self.status = status
        self.suggestedAction = suggestedAction
        self.dueDate = dueDate
        self.requiresUserApproval = requiresUserApproval
        self.approvalTicketId = approvalTicketId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var isResolved: Bool {
        return status == .completed || status == .dismissed
    }
}
