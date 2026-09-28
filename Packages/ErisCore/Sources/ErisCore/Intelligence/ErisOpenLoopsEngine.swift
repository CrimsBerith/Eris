//
//  ErisOpenLoopsEngine.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation
import Combine

/// Bölüm 42 ("Hayatındaki Açık İşleri Otomatik Bulma") gereğince:
/// Kullanıcının açıkça görev yazmasına gerek kalmadan konuşmalardan, takvimden,
/// kasanın içindeki notlardan ve belgelerden "Açık Döngüleri" (Open Loops)
/// tespit eden ve kapatılmasını takip eden Zekâ Motoru.
public final class ErisOpenLoopsEngine: ObservableObject, @unchecked Sendable {
    public static let shared = ErisOpenLoopsEngine()
    
    @Published public private(set) var activeLoops: [OpenLoopItem] = []
    
    private let queue = DispatchQueue(label: "com.eris.openloops", qos: .userInitiated)
    
    private init() {
        loadDefaultSampleLoops()
    }
    
    /// Varsayılan yaşam döngüsü örnekleriyle başlat (Kullanıcı ilk açtığında hazır yapı)
    private func loadDefaultSampleLoops() {
        self.activeLoops = [
            OpenLoopItem(
                domain: .billsSubscriptions,
                title: "İnternet / Servis Faturası",
                details: "Ay sonu yaklaşan fatura ödeme vadesi.",
                detectedSource: "calendar",
                urgency: .high,
                status: .detected,
                suggestedAction: "Ödeme yap veya otomatik talimatı teyit et.",
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
            ),
            OpenLoopItem(
                domain: .vehicleMaintenance,
                title: "Araç Periyodik Bakım & Muayene",
                details: "Araç muayene ve bakım süresine 15 gün kaldı.",
                detectedSource: "note",
                urgency: .medium,
                status: .detected,
                suggestedAction: "Servisten randevu saatini takvime ayarla.",
                dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())
            ),
            OpenLoopItem(
                domain: .warrantyReturns,
                title: "Online Sipariş İade Süresi",
                details: "Geçen hafta alınan ürünün son iade günü yaklaşıyor.",
                detectedSource: "chat",
                urgency: .medium,
                status: .detected,
                suggestedAction: "Kargoya verilecekse rota içine kargo şubesi eklensin.",
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
            )
        ]
    }
    
    // MARK: - Açık Döngü Ekleme & Yönetim
    
    public func addLoop(_ item: OpenLoopItem) {
        queue.async {
            DispatchQueue.main.async {
                self.activeLoops.insert(item, at: 0)
            }
        }
    }
    
    public func completeLoop(id: UUID) {
        queue.async {
            DispatchQueue.main.async {
                if let idx = self.activeLoops.firstIndex(where: { $0.id == id }) {
                    self.activeLoops[idx].status = .completed
                    self.activeLoops[idx].updatedAt = Date()
                }
            }
        }
    }
    
    public func dismissLoop(id: UUID) {
        queue.async {
            DispatchQueue.main.async {
                self.activeLoops.removeAll(where: { $0.id == id })
            }
        }
    }
    
    /// Bir metni analiz edip potansiyel yeni bir açık döngü var mı diye bakar
    public func scanTextForOpenLoops(_ text: String, source: String = "chat") -> OpenLoopItem? {
        let lower = text.lowercased()
        
        // Fatura / Ödeme tespiti
        if lower.contains("fatura") || lower.contains("ödeme") || lower.contains("aidat") || lower.contains("kira") {
            return OpenLoopItem(
                domain: .billsSubscriptions,
                title: "Ödeme / Fatura Yükümlülüğü",
                details: text,
                detectedSource: source,
                urgency: .high,
                suggestedAction: "Ödeme vadesini takvime ekle ve hatırlatıcı kur."
            )
        }
        
        // Randevu / Arama takibi
        if lower.contains("arayamadım") || lower.contains("döneceğim") || lower.contains("cevap vermem lazım") || lower.contains("ulaşmam gerek") {
            return OpenLoopItem(
                domain: .socialCRM,
                title: "Geri Dönüş / Arama Takibi",
                details: text,
                detectedSource: source,
                urgency: .medium,
                suggestedAction: "Günün uygun saatinde arama hatırlatıcısı oluştur."
            )
        }
        
        // İade / Garanti
        if lower.contains("iade") || lower.contains("garanti") || lower.contains("tamir") || lower.contains("servis") {
            return OpenLoopItem(
                domain: .warrantyReturns,
                title: "İade / Servis / Garanti İşlemi",
                details: text,
                detectedSource: source,
                urgency: .medium,
                suggestedAction: "Kargo veya servis süresi geçmeden takvime planla."
            )
        }
        
        return nil
    }
    
    public var pendingCount: Int {
        activeLoops.filter { $0.status == .detected || $0.status == .waitingApproval }.count
    }
}
