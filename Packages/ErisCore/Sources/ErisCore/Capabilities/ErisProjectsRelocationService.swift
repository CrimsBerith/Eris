//
//  ErisProjectsRelocationService.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct LifeProjectPhase: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var dueDate: Date?
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
    }
}

public struct LifeProject: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var category: String // "creative", "home", "career", "logistics"
    public var phases: [LifeProjectPhase]
    public var targetCompletionDate: Date?
    
    public init(
        id: UUID = UUID(),
        title: String,
        category: String = "creative",
        phases: [LifeProjectPhase] = [],
        targetCompletionDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.phases = phases
        self.targetCompletionDate = targetCompletionDate
    }
    
    public var progressPercent: Int {
        guard !phases.isEmpty else { return 0 }
        let completed = phases.filter { $0.isCompleted }.count
        return Int((Double(completed) / Double(phases.count)) * 100)
    }
}

/// Bölüm 34 & 35 ("Kişisel Projeler & Taşınma / Ev Değiştirme") gereğince:
/// Yaşam projelerini aşamalara bölen, taşınma ve büyük geçiş döngülerini
/// adım adım organize eden Proje & Lojistik Servisi.
public final class ErisProjectsRelocationService: @unchecked Sendable {
    public static let shared = ErisProjectsRelocationService()
    
    private var projects: [LifeProject] = []
    private let lock = NSLock()
    
    private init() {
        loadDefaultSampleProjects()
    }
    
    private func loadDefaultSampleProjects() {
        projects = [
            LifeProject(
                title: "Sonbahar / Kış Kapsül Tasarım Koleksiyonu",
                category: "creative",
                phases: [
                    LifeProjectPhase(title: "Form ve silüet çizimleri", isCompleted: true),
                    LifeProjectPhase(title: "İtalyan & Fransız kumaş numune tedariği", isCompleted: true),
                    LifeProjectPhase(title: "Atölye prova dikimleri ve fit kontrolü", isCompleted: false),
                    LifeProjectPhase(title: "Lookbook çekimi ve lansman", isCompleted: false)
                ],
                targetCompletionDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())
            ),
            LifeProject(
                title: "Stüdyo / Atölye Taşınma ve Yenileme Planı",
                category: "logistics",
                phases: [
                    LifeProjectPhase(title: "Koli ve hassas tekstil ekipmanı tasnifi", isCompleted: true),
                    LifeProjectPhase(title: "Fiber internet ve elektrik abonelik nakli", isCompleted: false),
                    LifeProjectPhase(title: "Resmî adres ve fatura bildirimleri", isCompleted: false),
                    LifeProjectPhase(title: "Anahtar teslim ve depozito iadesi", isCompleted: false)
                ],
                targetCompletionDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
            )
        ]
    }
    
    public func getProjects() -> [LifeProject] {
        lock.lock()
        defer { lock.unlock() }
        return projects
    }
    
    public func togglePhase(projectId: UUID, phaseId: UUID) {
        lock.lock()
        defer { lock.unlock() }
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let phIdx = projects[pIdx].phases.firstIndex(where: { $0.id == phaseId }) else { return }
        
        projects[pIdx].phases[phIdx].isCompleted.toggle()
    }
}
