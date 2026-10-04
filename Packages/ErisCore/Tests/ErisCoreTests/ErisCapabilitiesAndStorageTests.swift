import XCTest
@testable import ErisCore

final class ErisCapabilitiesAndStorageTests: XCTestCase {
    private var databaseDirectory: URL!
    private var database: ErisMemoryDatabase!

    override func setUpWithError() throws {
        databaseDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: databaseDirectory, withIntermediateDirectories: true)
        database = ErisMemoryDatabase(databaseURL: databaseDirectory.appendingPathComponent("test.sqlite"))
    }

    override func tearDownWithError() throws {
        database = nil
        try FileManager.default.removeItem(at: databaseDirectory)
        databaseDirectory = nil
    }
    
    // MARK: - 1. Living Checklist Engine
    func testLivingChecklistEngineOperations() {
        let engine = ErisLivingChecklistEngine.shared
        XCTAssertFalse(engine.checklists.isEmpty, "Initial seed checklists should be loaded")
        
        let initialCount = engine.checklists.count
        engine.createChecklist(
            title: "Test Hafta Sonu Kaçamağı",
            type: .travelPacking,
            items: ["Güneş kremi", "Yürüyüş ayakkabısı", "Powerbank"],
            destinationCity: "Bodrum",
            weatherNote: "26°C ve güneşli"
        )
        
        let exp = expectation(description: "Async checklist creation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(engine.checklists.count, initialCount + 1)
            let created = engine.checklists.first { $0.title == "Test Hafta Sonu Kaçamağı" }
            XCTAssertNotNil(created)
            XCTAssertEqual(created?.items.count, 3)
            XCTAssertEqual(created?.destinationCity, "Bodrum")
            exp.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - 2. Safe Execution Gate (Human-in-the-Loop)
    func testSafeExecutionGateTicketWorkflow() {
        let gate = ErisSafeExecutionGate.shared
        
        let ticket = gate.requestApproval(
            kind: .shareSensitiveData,
            title: "Sözleşme Taslağı Paylaşımı",
            explanation: "Sözleşme taslağını karşı tarafa e-posta ile gönder",
            risk: .critical
        )
        
        let exp = expectation(description: "Ticket submission")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(gate.hasPendingApprovals)
            XCTAssertTrue(gate.pendingTickets.contains(where: { $0.id == ticket.id }))
            
            // Approve ticket
            gate.approve(ticketId: ticket.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let approved = gate.pendingTickets.first(where: { $0.id == ticket.id })
                XCTAssertEqual(approved?.isApproved, true)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - 3. Memory Database (SQLite Persistence)
    func testMemoryDatabasePersistence() {
        let db = database!
        
        // Open Loop Persistence
        let testLoop = OpenLoopItem(
            domain: .learningEducation,
            title: "Fransızca ders kaydını tamamla",
            detectedSource: "database_test"
        )
        db.saveOpenLoopToDB(testLoop)
        let loops = db.getAllOpenLoopsFromDB()
        XCTAssertTrue(loops.contains(where: { $0.id == testLoop.id }))
        
        // Memory Record Persistence
        let memory = ErisMemoryRecord(
            category: .preference,
            title: "Kahve Tercihi",
            content: "Yulaf sütlü filtre kahve veya americano",
            source: "unit_test"
        )
        db.saveMemory(memory)
        let allMemories = db.getAllMemories()
        XCTAssertTrue(allMemories.contains(where: { $0.id == memory.id }))
        
        let searchResults = db.searchMemories(keyword: "Kahve")
        XCTAssertFalse(searchResults.isEmpty)
    }
    
    func testMemoryDatabaseEditRecord() {
        let db = database!
        
        let initialRecord = ErisMemoryRecord(
            category: .document,
            title: "İlk Taslak Notu",
            content: "Bu not henüz düzenlenmedi.",
            source: "unit_test"
        )
        db.saveMemory(initialRecord)
        
        // Update via parameters
        db.updateMemory(
            id: initialRecord.id,
            title: "Güncellenmiş Not Başlığı",
            content: "Bu not başarıyla güncellendi ve genişletildi.",
            category: .preference,
            tags: ["güncel", "önemli"],
            fileName: "duzenlenmis_not.md"
        )
        
        let allMemories = db.getAllMemories()
        let fetched = allMemories.first(where: { $0.id == initialRecord.id })
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Güncellenmiş Not Başlığı")
        XCTAssertEqual(fetched?.content, "Bu not başarıyla güncellendi ve genişletildi.")
        XCTAssertEqual(fetched?.category, .preference)
        XCTAssertEqual(fetched?.fileName, "duzenlenmis_not.md")
        XCTAssertTrue(fetched?.tags.contains("güncel") == true)
        
        // Update via record model
        if var rec = fetched {
            rec.title = "İkinci Düzenleme"
            rec.content = "İkinci düzenleme içeriği."
            db.updateMemory(rec)
            
            let updated = db.getAllMemories().first(where: { $0.id == initialRecord.id })
            XCTAssertEqual(updated?.title, "İkinci Düzenleme")
            XCTAssertEqual(updated?.content, "İkinci düzenleme içeriği.")
        }
    }
    
    // MARK: - 4. 12-Language Manager & Localization
    func test12LanguageSwitchingAndL10n() {
        let manager = ErisLanguageManager.shared
        let originalLang = manager.currentLanguage
        
        // Test switching across all 12 languages
        let allLanguages = ErisLanguage.allCases
        XCTAssertEqual(allLanguages.count, 12, "Must support all 12 world languages")
        
        for lang in allLanguages {
            manager.setLanguage(lang)
            XCTAssertEqual(manager.currentLanguage, lang)
            
            // Verify L10n keys return non-empty strings
            XCTAssertFalse(L10n.tabChat.isEmpty)
            XCTAssertFalse(L10n.tabWidgets.isEmpty)
            XCTAssertFalse(L10n.tabChecklists.isEmpty)
            XCTAssertFalse(L10n.tabMemory.isEmpty)
            XCTAssertFalse(L10n.tabSettings.isEmpty)
            XCTAssertFalse(L10n.openLoopsTitle.isEmpty)
            XCTAssertFalse(L10n.livingChecklistsTitle.isEmpty)
            XCTAssertFalse(L10n.approveAndExecute.isEmpty)
            XCTAssertFalse(L10n.declineAction.isEmpty)
            XCTAssertFalse(L10n.onboardingWelcomeTitle.isEmpty)
            XCTAssertFalse(L10n.getStartedText.isEmpty)
        }
        
        // Restore original language
        manager.setLanguage(originalLang)
    }
}
