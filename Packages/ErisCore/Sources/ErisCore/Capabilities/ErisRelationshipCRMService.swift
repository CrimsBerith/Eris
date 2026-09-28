//
//  ErisRelationshipCRMService.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct ContactDossier: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var fullName: String
    public var relationshipRole: String // "family", "close_friend", "client", "supplier", "colleague"
    public var birthday: Date?
    public var anniversary: Date?
    public var preferencesOrInterests: [String]
    public var giftIdeas: [String]
    public var lastInteractionDate: Date?
    public var followUpIntervalDays: Int // Örn: 30 günde bir hal hatır sor
    public var pendingTopics: [String]
    
    public init(
        id: UUID = UUID(),
        fullName: String,
        relationshipRole: String,
        birthday: Date? = nil,
        anniversary: Date? = nil,
        preferencesOrInterests: [String] = [],
        giftIdeas: [String] = [],
        lastInteractionDate: Date? = nil,
        followUpIntervalDays: Int = 30,
        pendingTopics: [String] = []
    ) {
        self.id = id
        self.fullName = fullName
        self.relationshipRole = relationshipRole
        self.birthday = birthday
        self.anniversary = anniversary
        self.preferencesOrInterests = preferencesOrInterests
        self.giftIdeas = giftIdeas
        self.lastInteractionDate = lastInteractionDate
        self.followUpIntervalDays = followUpIntervalDays
        self.pendingTopics = pendingTopics
    }
    
    public var isFollowUpOverdue: Bool {
        guard let last = lastInteractionDate else { return true }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return days >= followUpIntervalDays
    }
    
    public var isBirthdayApproaching: Bool {
        guard let bday = birthday else { return false }
        let calendar = Calendar.current
        let today = Date()
        let thisYearBday = calendar.date(bySetting: .year, value: calendar.component(.year, from: today), of: bday) ?? bday
        let days = calendar.dateComponents([.day], from: today, to: thisYearBday).day ?? 0
        return days >= 0 && days <= 14
    }
}

/// Bölüm 16, 30 & 36 ("İletişim, İlişki Yönetimi & Özel Günler") gereğince:
/// Sosyal bağları, takip bekleyen görüşmeleri, yaklaşan doğum günlerini
/// ve kişisel ilgi alanlarını yöneten Kişisel CRM Servisi.
public final class ErisRelationshipCRMService: @unchecked Sendable {
    public static let shared = ErisRelationshipCRMService()
    
    private var contacts: [ContactDossier] = []
    private let lock = NSLock()
    
    private init() {
        loadSampleContacts()
    }
    
    private func loadSampleContacts() {
        contacts = [
            ContactDossier(
                fullName: "Ahmet Yılmaz (Teknik Ortak)",
                relationshipRole: "colleague",
                preferencesOrInterests: ["Mimari", "Yapay Zeka", "Kahve"],
                giftIdeas: ["Özel kavrum filtre kahve", "Tasarım kitabı"],
                lastInteractionDate: Calendar.current.date(byAdding: .day, value: -38, to: Date()),
                followUpIntervalDays: 21,
                pendingTopics: ["Proje bütçe revizyonu", "Yeni sürüm mimarisi"]
            ),
            ContactDossier(
                fullName: "Canan Kartal (Aile)",
                relationshipRole: "family",
                birthday: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                preferencesOrInterests: ["Dekorasyon", "Sanat sergileri", "İtalyan mutfağı"],
                giftIdeas: ["El yapımı seramik vazo", "Akşam yemeği rezervasyonu"],
                lastInteractionDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
                followUpIntervalDays: 7
            )
        ]
    }
    
    public func getOverdueFollowUps() -> [ContactDossier] {
        lock.lock()
        defer { lock.unlock() }
        return contacts.filter { $0.isFollowUpOverdue }
    }
    
    public func getApproachingBirthdays() -> [ContactDossier] {
        lock.lock()
        defer { lock.unlock() }
        return contacts.filter { $0.isBirthdayApproaching }
    }
    
    public func getContactDossier(named: String) -> ContactDossier? {
        lock.lock()
        defer { lock.unlock() }
        return contacts.first(where: { $0.fullName.lowercased().contains(named.lowercased()) })
    }
}
