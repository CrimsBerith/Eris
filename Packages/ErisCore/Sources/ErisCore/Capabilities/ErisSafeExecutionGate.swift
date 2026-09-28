//
//  ErisSafeExecutionGate.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation
import Combine

/// Bölüm 48 ("Kullanıcı Onayı Gerektiren İşlemler") gereğince:
/// Güçlü bir AI asistan her şeyi otonom yapmamalıdır.
/// Para harcama, e-posta/mesaj gönderme, randevu iptali, abonelik iptali,
/// hassas veri paylaşımı gibi işlemlerde kullanıcıdan açık onay alan Güvenlik Kapısı.
public final class ErisSafeExecutionGate: ObservableObject, @unchecked Sendable {
    public static let shared = ErisSafeExecutionGate()
    
    @Published public private(set) var pendingTickets: [SafeActionTicket] = []
    
    private let queue = DispatchQueue(label: "com.eris.safegate", qos: .userInitiated)
    
    private init() {}
    
    // MARK: - Bilet Üretimi
    
    @discardableResult
    public func requestApproval(
        kind: SafeActionKind,
        title: String,
        explanation: String,
        payloadJson: String = "{}",
        risk: SafeActionRisk = .medium
    ) -> SafeActionTicket {
        let ticket = SafeActionTicket(
            kind: kind,
            title: title,
            explanation: explanation,
            payloadJson: payloadJson,
            riskLevel: risk
        )
        
        queue.async {
            DispatchQueue.main.async {
                self.pendingTickets.insert(ticket, at: 0)
            }
        }
        
        return ticket
    }
    
    // MARK: - Onaylama ve Reddetme
    
    public func approve(ticketId: UUID) {
        queue.async {
            DispatchQueue.main.async {
                if let idx = self.pendingTickets.firstIndex(where: { $0.id == ticketId }) {
                    self.pendingTickets[idx].isApproved = true
                    self.pendingTickets[idx].isExecuted = true
                    // İşlem gerçekleştikten sonra listeden nazikçe temizle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.pendingTickets.removeAll(where: { $0.id == ticketId })
                    }
                }
            }
        }
    }
    
    public func reject(ticketId: UUID) {
        queue.async {
            DispatchQueue.main.async {
                if let idx = self.pendingTickets.firstIndex(where: { $0.id == ticketId }) {
                    self.pendingTickets[idx].isRejected = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.pendingTickets.removeAll(where: { $0.id == ticketId })
                    }
                }
            }
        }
    }
    
    public var hasPendingApprovals: Bool {
        !pendingTickets.filter { $0.isPending }.isEmpty
    }
}
