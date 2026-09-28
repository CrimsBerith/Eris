//
//  ErisKnowledgeResearchService.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct ReadingListItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var author: String
    public var category: String // "design", "tech", "philosophy", "business"
    public var status: String // "to_read", "reading", "completed"
    public var keyTakeaway: String
    public var rating: Int? // 1 - 5
    
    public init(
        id: UUID = UUID(),
        title: String,
        author: String,
        category: String,
        status: String = "reading",
        keyTakeaway: String = "",
        rating: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.category = category
        self.status = status
        self.keyTakeaway = keyTakeaway
        self.rating = rating
    }
}

public struct ResearchDossier: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var topic: String
    public var summary: String
    public var keyFindings: [String]
    public var sourceUrls: [String]
    public var tags: [String]
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        topic: String,
        summary: String,
        keyFindings: [String] = [],
        sourceUrls: [String] = [],
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.topic = topic
        self.summary = summary
        self.keyFindings = keyFindings
        self.sourceUrls = sourceUrls
        self.tags = tags
        self.createdAt = createdAt
    }
}

/// Bölüm 24, 25 & 26 ("Öğrenme, Kitap, Medya & Araştırma") gereğince:
/// Kitap okuma listesini, web'den derlenen araştırma dosyalarını ve
/// öğrenme hedeflerini organize eden Bilgi Servisi.
public final class ErisKnowledgeResearchService: @unchecked Sendable {
    public static let shared = ErisKnowledgeResearchService()
    
    private var readingList: [ReadingListItem] = []
    private var dossiers: [ResearchDossier] = []
    private let lock = NSLock()
    
    private init() {
        loadDefaultSampleKnowledge()
    }
    
    private func loadDefaultSampleKnowledge() {
        readingList = [
            ReadingListItem(
                title: "The Design of Everyday Things",
                author: "Don Norman",
                category: "design",
                status: "reading",
                keyTakeaway: "Kullanıcı hataları aslında kötü tasarımın birer sonucudur; arayüzler geri bildirim ve görünürlük sağlamalıdır."
            ),
            ReadingListItem(
                title: "Atomic Habits",
                author: "James Clear",
                category: "philosophy",
                status: "completed",
                keyTakeaway: "%1'lik küçük iyileştirmelerin bileşik etkisi uzun vadede radikal sonuçlar doğurur.",
                rating: 5
            )
        ]
        
        dossiers = [
            ResearchDossier(
                topic: "2026 Kumaş Trendleri & Sürdürülebilir İpek",
                summary: "Akdeniz iklimi için nefes alabilir keten-ipek karışımları ve doğal boyama teknikleri.",
                keyFindings: [
                    "Organik bambu ipeği maliyet açısından %20 avantajlı",
                    "Doğal toprak tonları ve bronz aksanlar yükselişte"
                ],
                tags: ["moda", "tedarik", "kumaş"]
            )
        ]
    }
    
    public func getReadingList() -> [ReadingListItem] {
        lock.lock()
        defer { lock.unlock() }
        return readingList
    }
    
    public func getDossiers() -> [ResearchDossier] {
        lock.lock()
        defer { lock.unlock() }
        return dossiers
    }
}
