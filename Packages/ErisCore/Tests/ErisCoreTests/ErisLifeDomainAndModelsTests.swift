import XCTest
@testable import ErisCore

final class ErisLifeDomainAndModelsTests: XCTestCase {
    
    // MARK: - 1. Life Domains Count
    func testLifeDomainsCountAndDisplay() {
        let allDomains = ErisLifeDomain.allCases
        XCTAssertGreaterThanOrEqual(allDomains.count, 39, "All 39 life domains should be represented")
        
        for domain in allDomains {
            XCTAssertFalse(domain.displayName.isEmpty, "Domain \(domain) must have a non-empty displayName")
            XCTAssertFalse(domain.icon.isEmpty, "Domain \(domain) must have a valid SF Symbol icon")
        }
    }
    
    // MARK: - 2. Open Loop Items
    func testOpenLoopItemLifecycle() throws {
        var loop = OpenLoopItem(
            domain: .billsSubscriptions,
            title: "Ev internet aboneliğini yenile",
            detectedSource: "chat",
            suggestedAction: "Müşteri hizmetlerini ara veya taahhüt teklifini incele"
        )
        
        XCTAssertEqual(loop.status, LoopStatus.detected)
        XCTAssertFalse(loop.isResolved)
        XCTAssertEqual(loop.domain, ErisLifeDomain.billsSubscriptions)
        
        loop.status = .scheduled
        XCTAssertFalse(loop.isResolved)
        
        loop.status = .completed
        XCTAssertTrue(loop.isResolved)
        
        // Codable serialization test
        let encoder = JSONEncoder()
        let data = try encoder.encode(loop)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OpenLoopItem.self, from: data)
        XCTAssertEqual(decoded.id, loop.id)
        XCTAssertEqual(decoded.title, loop.title)
        XCTAssertEqual(decoded.status, LoopStatus.completed)
    }
    
    // MARK: - 3. Contextual Triggers
    func testContextualTriggerTypes() {
        let locTrigger = ContextualTrigger(
            type: .location,
            title: "Ofisten Çıkış",
            promptText: "Ofisten çıkarken evrakları çantaya koy",
            locationName: "Ofis",
            latitude: 41.0082,
            longitude: 28.9784,
            radiusMeters: 200
        )
        XCTAssertEqual(locTrigger.type.displayName, "Konum Tabanlı (Geofence)")
        XCTAssertTrue(locTrigger.isActive)
        
        let weatherTrigger = ContextualTrigger(
            type: .condition,
            title: "Yağmur Uyarısı",
            promptText: "Hava yağmurlu, şemsiyeni unutma",
            weatherConditionRequired: "rain"
        )
        XCTAssertEqual(weatherTrigger.type.displayName, "Koşul / Hava Durumu")
        
        let prepTrigger = ContextualTrigger(
            type: .preparation,
            title: "Uçuş Hazırlığı",
            promptText: "Havalimanına gitmek için evden çıkış vakti",
            minutesBeforeEvent: 180
        )
        XCTAssertEqual(prepTrigger.type.displayName, "Hazırlık & Ön Süre")
    }
    
    // MARK: - 4. Living Checklists & Items
    func testLivingChecklistProgressAndCategories() throws {
        var checklist = LivingChecklist(
            title: "Paris Seyahati Bavul Listesi",
            type: .travelPacking,
            items: [
                ChecklistItem(title: "Pasaport", isCompleted: true, category: "Belgeler"),
                ChecklistItem(title: "Trençkot", isCompleted: false, category: "Giyim"),
                ChecklistItem(title: "Şarj aleti", isCompleted: true, category: "Elektronik"),
                ChecklistItem(title: "Diş fırçası", isCompleted: false, category: "Kişisel")
            ],
            destinationCity: "Paris",
            weatherNote: "12°C ve yağmurlu"
        )
        
        XCTAssertEqual(checklist.completedCount, 2)
        XCTAssertEqual(checklist.items.count, 4)
        XCTAssertEqual(checklist.progressFraction, 0.5, accuracy: 0.001)
        
        // Item check toggle
        checklist.items[1].isCompleted = true
        XCTAssertEqual(checklist.completedCount, 3)
        XCTAssertEqual(checklist.progressFraction, 0.75, accuracy: 0.001)
        
        // Codable test
        let data = try JSONEncoder().encode(checklist)
        let decoded = try JSONDecoder().decode(LivingChecklist.self, from: data)
        XCTAssertEqual(decoded.title, "Paris Seyahati Bavul Listesi")
        XCTAssertEqual(decoded.destinationCity, "Paris")
    }
    
    // MARK: - 5. Safe Action Ticket (Human-in-the-Loop)
    func testSafeActionTicketApprovalGate() {
        var ticket = SafeActionTicket(
            kind: .spendingMoney,
            title: "Yazılım Aboneliği Yenileme",
            explanation: "Yıllık yazılım aboneliğini 180$ karşılığında yenile",
            riskLevel: .high
        )
        
        XCTAssertTrue(ticket.isPending)
        XCTAssertFalse(ticket.isApproved)
        
        ticket.isApproved = true
        XCTAssertTrue(ticket.isApproved)
        XCTAssertFalse(ticket.isPending)
    }
}
