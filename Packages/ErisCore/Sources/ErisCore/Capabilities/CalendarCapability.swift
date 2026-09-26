import Foundation
import EventKit

public final class CalendarCapability: @unchecked Sendable {
    public static let shared = CalendarCapability()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    public func requestAccess() async -> Bool {
        if #available(macOS 14.0, iOS 17.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    public func getEvents(from start: Date, to end: Date) -> [[String: Any]] {
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        return events.map { event in
            [
                "title": event.title ?? "Başlıksız",
                "startDate": event.startDate.description,
                "endDate": event.endDate.description,
                "isAllDay": event.isAllDay,
                "location": event.location ?? ""
            ]
        }
    }
    
    public func createEvent(title: String, start: Date, end: Date, notes: String? = nil) throws -> String {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier ?? UUID().uuidString
    }
}
