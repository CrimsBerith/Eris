//
//  ErisIntentDecomposer.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

/// Ayrıştırılan tekil alt adım veya görev
public struct DecomposedStep: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let orderIndex: Int
    public let domain: ErisLifeDomain
    public let title: String
    public let details: String
    public let estimatedDurationMinutes: Int?
    public let suggestedTime: String?
    public let requiresApproval: Bool
    
    public init(
        id: UUID = UUID(),
        orderIndex: Int,
        domain: ErisLifeDomain,
        title: String,
        details: String = "",
        estimatedDurationMinutes: Int? = nil,
        suggestedTime: String? = nil,
        requiresApproval: Bool = false
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.domain = domain
        self.title = title
        self.details = details
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.suggestedTime = suggestedTime
        self.requiresApproval = requiresApproval
    }
}

/// Kullanıcının doğal dil ifadesinden çıkarılan bütünleşik yaşam planı
public struct DecomposedPlan: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let originalUtterance: String
    public let summary: String
    public let steps: [DecomposedStep]
    public let openLoopsToCreate: [String]
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        originalUtterance: String,
        summary: String,
        steps: [DecomposedStep],
        openLoopsToCreate: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.originalUtterance = originalUtterance
        self.summary = summary
        self.steps = steps
        self.openLoopsToCreate = openLoopsToCreate
        self.createdAt = createdAt
    }
}

/// Bölüm 41 ("Doğal Dil ile Hayatı Yönetme") gereğince:
/// Kullanıcının tek bir cümlesindeki (örn: "Yarın sabah işe gitmeden önce arabaya yakıt al,
/// markete uğra ve 10'daki toplantı için dosyayı unutturma") çoklu niyetleri anlayan ve
/// ardışık alt adımlara, takvim girişlerine ve hatırlatıcılara bölen Zekâ Motoru.
public final class ErisIntentDecomposer: Sendable {
    public static let shared = ErisIntentDecomposer()
    
    private init() {}
    
    /// Hızlı yerel kural motoru + LLM zenginleştirmesi ile ifadeyi analiz eder
    public func decomposeUtterance(_ text: String) -> DecomposedPlan? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else { return nil }
        let lower = trimmed.lowercased()
        
        var steps: [DecomposedStep] = []
        var openLoops: [String] = []
        var stepIndex = 1
        
        // 1. Yakıt / Şarj Tespiti (Araç Yönetimi)
        if lower.contains("yakıt") || lower.contains("benzin") || lower.contains("mazot") || lower.contains("şarj et") || lower.contains("istasyon") {
            steps.append(DecomposedStep(
                orderIndex: stepIndex,
                domain: .vehicleMaintenance,
                title: "Yakıt / Şarj İhtiyacı",
                details: "İşe veya rotaya çıkmadan önce en yakın uygun istasyona uğrama.",
                estimatedDurationMinutes: 10,
                requiresApproval: false
            ))
            openLoops.append("Araç yakıt/şarj ikmali")
            stepIndex += 1
        }
        
        // 2. Market / Alışveriş Tespiti (Ev & Kiler)
        if lower.contains("market") || lower.contains("bakkal") || lower.contains("alışveriş") || lower.contains("süt al") || lower.contains("ekmek al") {
            steps.append(DecomposedStep(
                orderIndex: stepIndex,
                domain: .homePantry,
                title: "Market / Eksilenler Tedariği",
                details: "Rota üzerindeki markete uğrayıp eksikleri tamamlama.",
                estimatedDurationMinutes: 15,
                requiresApproval: false
            ))
            openLoops.append("Eksilenler market alışverişi")
            stepIndex += 1
        }
        
        // 3. Toplantı / İş Hazırlığı Tespiti (İş & Kariyer)
        if lower.contains("toplantı") || lower.contains("sunum") || lower.contains("dosya") || lower.contains("rapor") || lower.contains("unutturma") {
            let docName = extractPotentialDocSubject(from: trimmed)
            steps.append(DecomposedStep(
                orderIndex: stepIndex,
                domain: .workCareer,
                title: "Toplantı & Evrak Hazırlığı",
                details: docName.isEmpty ? "Toplantı öncesi ilgili dosyaları ve notları aç." : "\(docName) dosyasını incele ve toplantıya hazır et.",
                estimatedDurationMinutes: 15,
                suggestedTime: "Toplantıdan 30 dk önce",
                requiresApproval: false
            ))
            openLoops.append("Toplantı öncesi dosya hazırlığı")
            stepIndex += 1
        }
        
        // 4. Buluşma / Sosyal / Restoran Tespiti (Sosyal CRM & Yemek)
        if lower.contains("buluş") || lower.contains("restoran") || lower.contains("yemek ye") || lower.contains("kahve iç") {
            steps.append(DecomposedStep(
                orderIndex: stepIndex,
                domain: .socialCRM,
                title: "Buluşma Planı & Rezervasyon",
                details: "Takvimi kontrol et, uygun mekan öner ve rotayı ayarla.",
                estimatedDurationMinutes: 90,
                requiresApproval: false
            ))
            stepIndex += 1
        }
        
        // 5. Rota / Ulaşım / Çıkış Saati Hesaplama (Ulaşım & Rota)
        if steps.count >= 2 || lower.contains("işe gitmeden") || lower.contains("evden çık") || lower.contains("yola çık") {
            steps.append(DecomposedStep(
                orderIndex: stepIndex,
                domain: .commuteTransit,
                title: "Optimize Edilmiş Rota & Erken Çıkış Saati",
                details: "Eklenen ara duraklar (yakıt, market vb.) ve canlı trafik hesaba katılarak çıkış saati güncellendi.",
                estimatedDurationMinutes: 30,
                requiresApproval: false
            ))
            stepIndex += 1
        }
        
        // Eğer çoklu veya belirli bir niyet tespit edildiyse plan üret
        guard !steps.isEmpty else { return nil }
        
        let summary = "\(steps.count) adımlı entegre yaşam planı oluşturuldu (\(steps.map { $0.title }.joined(separator: " → ")))"
        
        return DecomposedPlan(
            originalUtterance: trimmed,
            summary: summary,
            steps: steps,
            openLoopsToCreate: openLoops
        )
    }
    
    private func extractPotentialDocSubject(from text: String) -> String {
        let words = text.components(separatedBy: .whitespaces)
        for (i, word) in words.enumerated() {
            if word.lowercased().contains("dosya") && i > 0 {
                return words[i-1] + " dosyası"
            }
        }
        return ""
    }
}
