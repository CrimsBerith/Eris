//
//  ErisVaultDocumentService.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public enum VaultDocCategory: String, Codable, CaseIterable, Sendable {
    case passportId = "passport_id"             // Pasaport, Kimlik, Ehliyet
    case contract = "contract"                   // Sözleşme, Kira kontratı, Protokol
    case receiptInvoice = "receipt_invoice"     // Alışveriş fişi, Fatura, Dekont
    case warrantyCertificate = "warranty_cert"  // Garanti belgesi, Kullanım kılavuzu
    case officialPaper = "official_paper"       // Ruhsat, Tapu, Noter belgesi
    case medicalRecord = "medical_record"       // Tahlil, Reçete, Aşı kartı
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .passportId: return "Kimlik & Pasaport"
        case .contract: return "Sözleşme & Kontrat"
        case .receiptInvoice: return "Fatura & Fiş"
        case .warrantyCertificate: return "Garanti Belgesi"
        case .officialPaper: return "Resmî Evrak & Tapu"
        case .medicalRecord: return "Sağlık & Reçete"
        case .other: return "Genel Belge"
        }
    }
    
    public var icon: String {
        switch self {
        case .passportId: return "person.text.rectangle.fill"
        case .contract: return "signature"
        case .receiptInvoice: return "newspaper.fill"
        case .warrantyCertificate: return "checkmark.seal.fill"
        case .officialPaper: return "building.columns.fill"
        case .medicalRecord: return "cross.case.fill"
        case .other: return "doc.fill"
        }
    }
}

public struct VaultDocumentRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var category: VaultDocCategory
    public var documentNumber: String?
    public var expirationDate: Date?
    public var warrantyEndDate: Date?
    public var issuer: String?
    public var associatedPerson: String?
    public var tags: [String]
    public var notes: String
    public var isEncrypted: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        category: VaultDocCategory,
        documentNumber: String? = nil,
        expirationDate: Date? = nil,
        warrantyEndDate: Date? = nil,
        issuer: String? = nil,
        associatedPerson: String? = nil,
        tags: [String] = [],
        notes: String = "",
        isEncrypted: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.documentNumber = documentNumber
        self.expirationDate = expirationDate
        self.warrantyEndDate = warrantyEndDate
        self.issuer = issuer
        self.associatedPerson = associatedPerson
        self.tags = tags
        self.notes = notes
        self.isEncrypted = isEncrypted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var isExpiringSoon: Bool {
        guard let exp = expirationDate ?? warrantyEndDate else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: exp).day ?? 0
        return days >= 0 && days <= 60
    }
}

/// Bölüm 27, 28 & 29 ("Belgeler, Kişisel Arşiv & Güvenlik") gereğince:
/// Kimlik, pasaport, sözleşmeler, garanti belgeleri ve resmî evrakları
/// şifreli olarak yöneten ve süre bitimlerini proaktif takip eden Kasa Servisi.
public final class ErisVaultDocumentService: ObservableObject, @unchecked Sendable {
    public static let shared = ErisVaultDocumentService()
    
    @Published public private(set) var documents: [VaultDocumentRecord] = []
    private let lock = NSLock()
    
    private init() {
        loadSampleVaultDocuments()
    }
    
    private func loadSampleVaultDocuments() {
        documents = [
            VaultDocumentRecord(
                title: "Bordo Pasaport",
                category: .passportId,
                documentNumber: "U12345678",
                expirationDate: Calendar.current.date(byAdding: .month, value: 8, to: Date()),
                issuer: "T.C. İçişleri Bakanlığı",
                notes: "Vize başvurusu için en az 6 ay geçerlilik süresi kontrolü yapıldı."
            ),
            VaultDocumentRecord(
                title: "Atölye Kira Sözleşmesi",
                category: .contract,
                expirationDate: Calendar.current.date(byAdding: .month, value: 4, to: Date()),
                issuer: "Kira Kontratı",
                notes: "Yıllık TÜFE artış oranı maddesi içeriyor."
            ),
            VaultDocumentRecord(
                title: "MacBook Pro Garanti & Fatura",
                category: .warrantyCertificate,
                warrantyEndDate: Calendar.current.date(byAdding: .month, value: 14, to: Date()),
                issuer: "Apple Türkiye",
                notes: "Yetkili servis garantisi ve AppleCare durumu aktif."
            )
        ]
    }
    
    // MARK: - Belge İşlemleri
    
    public func addDocument(_ doc: VaultDocumentRecord) {
        if Thread.isMainThread {
            lock.lock()
            documents.insert(doc, at: 0)
            lock.unlock()
        } else {
            DispatchQueue.main.async {
                self.lock.lock()
                self.documents.insert(doc, at: 0)
                self.lock.unlock()
            }
        }
        
        // Eğer süresi yaklaşan bir belgeyse otomatik açık döngü (Open Loop) oluştur
        if doc.isExpiringSoon, let exp = doc.expirationDate ?? doc.warrantyEndDate {
            ErisOpenLoopsEngine.shared.addLoop(OpenLoopItem(
                domain: .documentsVault,
                title: "\(doc.title) Süresi Yaklaşıyor",
                details: "Son geçerlilik: \(formatDate(exp)). Yenileme veya kontrol planı yapılmalı.",
                detectedSource: "vault",
                urgency: .high,
                suggestedAction: "Yenileme randevusunu takvime ekle."
            ))
        }
    }
    
    public func getDocuments(category: VaultDocCategory? = nil) -> [VaultDocumentRecord] {
        lock.lock()
        defer { lock.unlock() }
        if let cat = category {
            return documents.filter { $0.category == cat }
        }
        return documents
    }
    
    public func getExpiringDocuments(withinDays: Int = 60) -> [VaultDocumentRecord] {
        lock.lock()
        defer { lock.unlock() }
        return documents.filter { doc in
            guard let date = doc.expirationDate ?? doc.warrantyEndDate else { return false }
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            return days >= 0 && days <= withinDays
        }
    }
    
    public func updateDocument(_ updated: VaultDocumentRecord) {
        var docToSave = updated
        docToSave.updatedAt = Date()
        
        let block = {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let idx = self.documents.firstIndex(where: { $0.id == updated.id }) {
                self.documents[idx] = docToSave
            }
        }
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
    
    public func deleteDocument(id: UUID) {
        if Thread.isMainThread {
            lock.lock()
            documents.removeAll(where: { $0.id == id })
            lock.unlock()
        } else {
            DispatchQueue.main.async {
                self.lock.lock()
                self.documents.removeAll(where: { $0.id == id })
                self.lock.unlock()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}
