import Foundation

/// The same title and dates are carried from the proposal to the calendar write.
public struct CalendarEventPayload: Codable, Equatable, Sendable {
    public let title: String
    public let start: Date
    public let end: Date

    public init(title: String, start: Date, end: Date) {
        self.title = title
        self.start = start
        self.end = end
    }

    public func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CalendarActionError.invalidTitle
        }
        guard start.timeIntervalSince1970.isFinite,
              end.timeIntervalSince1970.isFinite, end > start else {
            throw CalendarActionError.invalidDates
        }
    }

    public func encodedJSON() throws -> String {
        try validate()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw CalendarActionError.invalidPayload
        }
        return json
    }

    public static func decodeJSON(_ json: String) throws -> CalendarEventPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let payload: CalendarEventPayload
        do {
            payload = try decoder.decode(Self.self, from: Data(json.utf8))
        } catch {
            throw CalendarActionError.invalidPayload
        }
        try payload.validate()
        return payload
    }
}

public enum CalendarActionError: LocalizedError {
    case invalidPayload
    case invalidTitle
    case invalidDates
    case permissionDenied
    case noWritableCalendar
    case missingEventIdentifier

    public var errorDescription: String? {
        switch self {
        case .invalidPayload: return "Takvim kaydı çözümlenemedi. Lütfen etkinliği yeniden hazırlayın."
        case .invalidTitle: return "Etkinlik başlığı boş olamaz."
        case .invalidDates: return "Etkinliğin bitişi başlangıcından sonra olmalı."
        case .permissionDenied: return "Takvim yazma izni yok. Sistem ayarlarından Eris için takvim erişimini açın."
        case .noWritableCalendar: return "Yazılabilir bir takvim bulunamadı. Takvim uygulamasında bir takvim oluşturun veya seçin."
        case .missingEventIdentifier: return "Takvim kaydı için kimlik alınamadı. Yeniden denemeden önce takviminizi kontrol edin."
        }
    }
}

public protocol CalendarEventWriting {
    func createEvent(title: String, start: Date, end: Date, notes: String?) throws -> String
}

/// Called by the UI only after the user approves the proposed event.
/// Authorization policy remains the responsibility of the approval flow.
public enum CalendarActionExecutor {
    @discardableResult
    public static func execute(
        payloadJSON: String,
        calendar: any CalendarEventWriting = CalendarCapability.shared
    ) throws -> String {
        let payload = try CalendarEventPayload.decodeJSON(payloadJSON)
        return try calendar.createEvent(title: payload.title, start: payload.start, end: payload.end, notes: nil)
    }
}
