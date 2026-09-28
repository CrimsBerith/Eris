import XCTest
@testable import ErisCore

final class ErisIntelligenceEnginesTests: XCTestCase {
    
    // MARK: - 1. Intent Decomposer (DAG Multi-Step Plan)
    func testIntentDecomposerDecomposesMultiStepCommand() {
        let decomposer = ErisIntentDecomposer.shared
        let utterance = "Yarın sabah işe gitmeden benzin al, sonra saat 10'daki toplantıyı hazırla ve Ahmet'e sunum dosyasını gönder"
        
        let plan = decomposer.decomposeUtterance(utterance)
        XCTAssertNotNil(plan, "Complex multi-intent sentence should be decomposed into a plan")
        
        if let plan = plan {
            XCTAssertGreaterThanOrEqual(plan.steps.count, 2, "There should be multiple steps in the plan")
            XCTAssertFalse(plan.openLoopsToCreate.isEmpty, "Plan should extract open loops for follow-up")
            
            // Check step sequencing
            for (idx, step) in plan.steps.enumerated() {
                XCTAssertEqual(step.orderIndex, idx + 1)
                XCTAssertFalse(step.title.isEmpty)
            }
        }
    }
    
    // MARK: - 2. Open Loops Engine
    func testOpenLoopsEngineManagement() {
        let engine = ErisOpenLoopsEngine.shared
        
        let testLoop = OpenLoopItem(
            domain: .workCareer,
            title: "Tedarikçi sözleşmesini imzala",
            detectedSource: "unit_test",
            suggestedAction: "Avukata onay için ilet"
        )
        
        engine.addLoop(testLoop)
        let exp1 = expectation(description: "Loop addition")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(engine.activeLoops.contains(where: { $0.id == testLoop.id }))
            
            // Dismiss loop
            engine.dismissLoop(id: testLoop.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertFalse(engine.activeLoops.contains(where: { $0.id == testLoop.id }))
                exp1.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - 3. Decision Support Engine
    func testDecisionSupportMatrixGeneration() {
        let engine = ErisDecisionSupportEngine.shared
        let matrix = engine.generateDecisionMatrix(
            topic: "Hangi laptop çantasını almalıyım: Deri evrak çantası mı yoksa su geçirmez sırt çantası mı?",
            optionNames: ["Deri Evrak Çantası", "Su Geçirmez Sırt Çantası"]
        )
        
        XCTAssertEqual(matrix.options.count, 2)
        XCTAssertFalse(matrix.userTradeoffSummary.isEmpty)
        
        for option in matrix.options {
            XCTAssertGreaterThan(option.alignmentScore, 0)
            XCTAssertFalse(option.pros.isEmpty)
        }
    }
    
    // MARK: - 4. Life OS Universal Router
    func testLifeOSUniversalRouter() {
        let engine = ErisLifeOSEngine.shared
        
        // Morning briefing intent
        let briefingAction = engine.processIncomingMessage("Bugünkü planlarımız nedir?", isVoice: false)
        if case .morningBriefing = briefingAction {
            // Expected
        } else {
            XCTFail("Expected .morningBriefing action for 'Bugünkü planlarımız nedir?'")
        }
        
        // Open loops intent
        let loopsAction = engine.processIncomingMessage("Askıda kalan açık işlerim neler?", isVoice: false)
        if case .openLoopsSummary(let reply, _) = loopsAction {
            XCTAssertFalse(reply.isEmpty)
        } else {
            XCTFail("Expected .openLoopsSummary action")
        }
        
        // Living checklists intent
        let checklistsAction = engine.processIncomingMessage("Seyahat ve kiler için yaşayan listelerimi göster", isVoice: false)
        if case .livingChecklistsSummary(let reply, _) = checklistsAction {
            XCTAssertFalse(reply.isEmpty)
            XCTAssertTrue(reply.contains("Yaşayan Listeleriniz"))
        } else {
            XCTFail("Expected .livingChecklistsSummary action")
        }
        
        // Pantry and meals intent
        let pantryAction = engine.processIncomingMessage("Evde ne var, bu akşam ne pişirsem?", isVoice: false)
        if case .pantryAndMeals(let reply, _) = pantryAction {
            XCTAssertFalse(reply.isEmpty)
        } else {
            XCTFail("Expected .pantryAndMeals action")
        }
    }
}
