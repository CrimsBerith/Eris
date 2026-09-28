import XCTest
@testable import ErisCore

final class ErisLifeServicesTests: XCTestCase {
    
    // MARK: - 1. Home Pantry & Meal Suggestions (Pillar 4)
    func testHomePantryService() {
        let service = ErisHomePantryService.shared
        let depleted = service.getDepletedItems()
        XCTAssertFalse(depleted.isEmpty, "Default depleted pantry items should exist")
        
        let meal = service.suggestMealFromPantry()
        XCTAssertFalse(meal.isEmpty, "Pantry should suggest a meal based on available ingredients")
    }
    
    // MARK: - 2. Finance & Subscriptions (Pillar 5)
    func testFinanceSubscriptionEngine() {
        let engine = ErisFinanceSubscriptionEngine.shared
        let subscriptions = engine.getSubscriptions()
        XCTAssertFalse(subscriptions.isEmpty, "Active subscriptions should be populated")
        
        let bills = engine.getBills()
        XCTAssertFalse(bills.isEmpty, "Bills should be populated")
        
        let totalCost = engine.totalMonthlyRecurringCost()
        XCTAssertGreaterThan(totalCost, 0)
        
        let unused = engine.unusedSubscriptions()
        XCTAssertFalse(unused.isEmpty, "Unused subscriptions should be detected")
    }
    
    // MARK: - 3. Vault & Document Expirations (Pillar 8)
    func testVaultDocumentService() {
        let service = ErisVaultDocumentService.shared
        let docs = service.getDocuments()
        XCTAssertFalse(docs.isEmpty, "Default vault documents (passport, lease, warranties) should exist")
        
        let expiring = service.getExpiringDocuments(withinDays: 180)
        XCTAssertNotNil(expiring)
    }
    
    func testVaultDocumentUpdate() {
        let service = ErisVaultDocumentService.shared
        guard var firstDoc = service.getDocuments().first else {
            XCTFail("At least one document should exist")
            return
        }
        
        let originalTitle = firstDoc.title
        firstDoc.title = "Güncellenmiş \(originalTitle)"
        firstDoc.notes = "Notlar kullanıcı tarafından güncellendi."
        
        service.updateDocument(firstDoc)
        
        let fetched = service.getDocuments().first(where: { $0.id == firstDoc.id })
        XCTAssertEqual(fetched?.title, "Güncellenmiş \(originalTitle)")
        XCTAssertEqual(fetched?.notes, "Notlar kullanıcı tarafından güncellendi.")
    }
    
    // MARK: - 4. Relationship CRM & Birthdays (Pillar 7)
    func testRelationshipCRMService() {
        let service = ErisRelationshipCRMService.shared
        let overdue = service.getOverdueFollowUps()
        XCTAssertFalse(overdue.isEmpty, "Overdue follow-up contacts should be flagged")
        
        let upcomingBirthdays = service.getApproachingBirthdays()
        XCTAssertFalse(upcomingBirthdays.isEmpty, "Upcoming birthdays should be tracked")
    }
    
    // MARK: - 5. Mobility, Vehicle & Travel Logistics (Pillar 6)
    func testMobilityLogisticsService() {
        let service = ErisMobilityLogisticsService.shared
        let vehicleHealth = service.getVehicleStatus()
        XCTAssertFalse(vehicleHealth.modelName.isEmpty)
        XCTAssertGreaterThan(vehicleHealth.currentKilometers, 0)
        
        let trip = service.getNextUpcomingTrip()
        XCTAssertNotNil(trip, "Upcoming travel itinerary should be tracked")
    }
    
    // MARK: - 6. Health & Wellness (Pillar 6)
    func testHealthWellnessService() {
        let service = ErisHealthWellnessService.shared
        let meds = service.getMedications()
        XCTAssertFalse(meds.isEmpty, "Daily vitamin/med schedule should be configured")
        
        let waterTarget = service.waterStatus.dailyTargetMl
        XCTAssertGreaterThan(waterTarget, 0)
    }
    
    // MARK: - 7. Habits & Vision Goals (Pillar 7)
    func testHabitsGoalsService() {
        let service = ErisHabitsGoalsService.shared
        let habits = service.getHabits()
        XCTAssertFalse(habits.isEmpty, "Habits should be tracked with streaks")
        
        for habit in habits {
            XCTAssertGreaterThanOrEqual(habit.currentStreakDays, 0)
        }
        
        let goals = service.getGoals()
        XCTAssertFalse(goals.isEmpty, "Vision goals should be broken into micro-tasks")
    }
    
    // MARK: - 8. Life Automation Reports (Evening & Weekly)
    func testLifeAutomationEngineReports() {
        let automation = ErisLifeAutomationEngine.shared
        
        let eveningReport = automation.runDailyEveningAutomation()
        XCTAssertEqual(eveningReport.cadence, .dailyEvening)
        XCTAssertFalse(eveningReport.summary.isEmpty)
        
        let weeklyReport = automation.runWeeklyAutomation()
        XCTAssertEqual(weeklyReport.cadence, .weekly)
        XCTAssertFalse(weeklyReport.actionItems.isEmpty)
    }
}
