//
//  SafeActionTicket.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public enum SafeActionKind: String, Codable, CaseIterable, Sendable {
    case spendingMoney = "spending_money"             // Para harcama / Satın alma
    case reservationBooking = "reservation_booking"   // Rezervasyon / Biletleme
    case sendEmail = "send_email"                     // E-posta gönderimi
    case sendMessage = "send_message"                 // Mesaj / SMS gönderimi
    case cancelAppointment = "cancel_appointment"     // Randevu iptali
    case cancelSubscription = "cancel_subscription"   // Abonelik iptali
    case shareSensitiveData = "share_sensitive_data"  // Belge gönderme / Hassas veri paylaşımı
    case deleteResource = "delete_resource"           // Kayıt veya dosya silme
    
    public var displayName: String {
        switch self {
        case .spendingMoney: return "Finansal Harcama"
        case .reservationBooking: return "Rezervasyon & Bilet"
        case .sendEmail: return "E-Posta Gönderimi"
        case .sendMessage: return "Mesaj Gönderimi"
        case .cancelAppointment: return "Randevu İptali"
        case .cancelSubscription: return "Abonelik İptali"
        case .shareSensitiveData: return "Belge / Veri Paylaşımı"
        case .deleteResource: return "Kayıt Silme"
        }
    }
    
    public var icon: String {
        switch self {
        case .spendingMoney: return "creditcard.and.123"
        case .reservationBooking: return "ticket.fill"
        case .sendEmail: return "paperplane.fill"
        case .sendMessage: return "bubble.left.and.bubble.right.fill"
        case .cancelAppointment: return "calendar.badge.minus"
        case .cancelSubscription: return "xmark.seal.fill"
        case .shareSensitiveData: return "shield.lefthalf.filled"
        case .deleteResource: return "trash.fill"
        }
    }
}

public enum SafeActionRisk: String, Codable, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low: return "Düşük Risk"
        case .medium: return "Orta Risk"
        case .high: return "Yüksek Risk"
        case .critical: return "Kritik Risk"
        }
    }
}

/// Bölüm 48 gereğince riskli işlemler için kullanıcı onay kapısı (Human-in-the-loop bileti).
public struct SafeActionTicket: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var kind: SafeActionKind
    public var title: String
    public var explanation: String
    public var payloadJson: String
    public var riskLevel: SafeActionRisk
    public var isApproved: Bool
    public var isRejected: Bool
    public var isExecuted: Bool
    public let createdAt: Date
    public let expiresAt: Date
    
    public init(
        id: UUID = UUID(),
        kind: SafeActionKind,
        title: String,
        explanation: String,
        payloadJson: String = "{}",
        riskLevel: SafeActionRisk = .medium,
        isApproved: Bool = false,
        isRejected: Bool = false,
        isExecuted: Bool = false,
        createdAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(300) // 5 dakika geçerli
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.explanation = explanation
        self.payloadJson = payloadJson
        self.riskLevel = riskLevel
        self.isApproved = isApproved
        self.isRejected = isRejected
        self.isExecuted = isExecuted
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    public var isPending: Bool {
        return !isApproved && !isRejected && !isExecuted && Date() <= expiresAt
    }
}
