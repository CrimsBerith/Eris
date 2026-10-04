import XCTest
@testable import ErisCore

final class ErisStartupAndCalendarActionTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
        directory = nil
    }

    func testFreshDatabaseStartsEmptyWithoutInvokingSync() {
        let database = ErisMemoryDatabase(
            databaseURL: directory.appendingPathComponent("test.sqlite"),
            onMemoriesChanged: { XCTFail("Database initialization must not start cloud sync") }
        )
        XCTAssertTrue(database.getAllMemories().isEmpty)
    }

    func testLocalWriteDoesNotInvokeSyncButUserWriteDoes() {
        let synced = expectation(description: "User write requests sync once")
        synced.assertForOverFulfill = true
        let database = ErisMemoryDatabase(
            databaseURL: directory.appendingPathComponent("test.sqlite"),
            onMemoriesChanged: { synced.fulfill() }
        )
        let item = ErisMemoryRecord(category: .preference, content: "İlk not")
        database.saveMemoryInternal(item)
        XCTAssertEqual(database.getAllMemories().count, 1)
        database.saveMemory(ErisMemoryRecord(category: .preference, content: "İkinci not"))
        wait(for: [synced], timeout: 1)
        XCTAssertEqual(database.getAllMemories().count, 2)
    }

    func testEditAndDeletionSurviveReopeningWithoutRestoringSampleNotes() {
        let url = directory.appendingPathComponent("test.sqlite")
        var item = ErisMemoryRecord(category: .designIdea, title: "Taslak", content: "İlk içerik")
        do {
            let database = ErisMemoryDatabase(databaseURL: url)
            database.saveMemory(item)
            item.title = "Güncel taslak"
            item.content = "Düzenlenmiş içerik"
            database.updateMemory(item)
        }
        do {
            let database = ErisMemoryDatabase(databaseURL: url)
            let loaded = database.getAllMemories()
            XCTAssertEqual(loaded.count, 1)
            XCTAssertEqual(loaded.first?.title, item.title)
            XCTAssertEqual(loaded.first?.content, item.content)
            database.deleteMemory(id: item.id)
        }
        let reopened = ErisMemoryDatabase(databaseURL: url)
        XCTAssertTrue(reopened.getAllMemories().isEmpty)
    }

    func testExecutorWritesExactlyTheProposedTitleAndDates() throws {
        let calendar = RecordingCalendar()
        let payload = CalendarEventPayload(
            title: "\"İpek\" tasarımı\nAtölye toplantısı",
            start: Date(timeIntervalSince1970: 1_800_000_000),
            end: Date(timeIntervalSince1970: 1_800_003_600)
        )
        let identifier = try CalendarActionExecutor.execute(payloadJSON: payload.encodedJSON(), calendar: calendar)
        XCTAssertEqual(identifier, "saved-event")
        XCTAssertEqual(calendar.writes, [payload])
    }

    func testExecutorPropagatesCalendarSaveFailure() throws {
        let calendar = RecordingCalendar()
        calendar.shouldFail = true
        let payload = CalendarEventPayload(title: "Prova", start: Date(), end: Date().addingTimeInterval(3600))
        XCTAssertThrowsError(try CalendarActionExecutor.execute(payloadJSON: payload.encodedJSON(), calendar: calendar)) {
            XCTAssertTrue($0 is RecordingCalendar.SaveFailure)
        }
        XCTAssertTrue(calendar.writes.isEmpty)
    }

    func testInvalidPayloadNeverReachesCalendar() {
        let calendar = RecordingCalendar()
        for json in ["not json", "{}", #"{"title":"Prova","start":20,"end":10}"#, #"{"title":"  ","start":10,"end":20}"#] {
            XCTAssertThrowsError(try CalendarActionExecutor.execute(payloadJSON: json, calendar: calendar))
        }
        XCTAssertTrue(calendar.writes.isEmpty)
    }

    func testCalendarCommandTakesPriorityOverDesignNoteExtraction() {
        let action = ErisLifeOSEngine.shared.processIncomingMessage("Yarın saat 14:00 tasarım toplantı ekle", isVoice: false)
        guard case .calendarEvent = action else {
            return XCTFail("An explicit calendar command must not become a design note")
        }
    }

    func testSaturdayIsNotMatchedAsFriday() throws {
        let timezone = try XCTUnwrap(TimeZone(identifier: "Europe/Istanbul"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        // Sunday 4 October 2026, Istanbul time.
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 12)))
        let event = try XCTUnwrap(CalendarCapability.parseNaturalLanguageEvent(from: "Cumartesi saat 14:30 toplantı ekle", now: now))
        XCTAssertEqual(calendar.component(.day, from: event.startDate), 10)
        XCTAssertEqual(calendar.component(.hour, from: event.startDate), 14)
        XCTAssertEqual(calendar.component(.minute, from: event.startDate), 30)
    }

    func testTomorrowUsesIstanbulDayAtMidnightBoundary() throws {
        let formatter = ISO8601DateFormatter()
        let now = try XCTUnwrap(formatter.date(from: "2026-10-04T22:30:00Z"))
        let event = try XCTUnwrap(CalendarCapability.parseNaturalLanguageEvent(from: "Yarın saat 14:30 toplantı ekle", now: now))
        XCTAssertEqual(event.startDate, formatter.date(from: "2026-10-06T11:30:00Z"))
    }
}

private final class RecordingCalendar: CalendarEventWriting {
    struct SaveFailure: Error {}
    var shouldFail = false
    var writes: [CalendarEventPayload] = []

    func createEvent(title: String, start: Date, end: Date, notes: String?) throws -> String {
        if shouldFail { throw SaveFailure() }
        writes.append(CalendarEventPayload(title: title, start: start, end: end))
        return "saved-event"
    }
}
