import Foundation
import EventKit

public struct ErisCalendarEvent: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String
    
    public init(id: String, title: String, startDate: Date, endDate: Date, isAllDay: Bool = false, location: String = "") {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
    }
}

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
    
    public func getTodayEvents() -> [ErisCalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return getEvents(from: startOfDay, to: endOfDay)
    }
    
    public func getEvents(from start: Date, to end: Date) -> [ErisCalendarEvent] {
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        return events.map { event in
            ErisCalendarEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Başlıksız Etkinlik",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                location: event.location ?? ""
            )
        }
    }
    
    public func getCalendarContextString() -> String {
        let events = getTodayEvents()
        guard !events.isEmpty else { return "\n[BUGÜNKÜ TAKVİM]: Etkinlik yok (Ajanda boş).\n" }
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        formatter.dateFormat = "HH:mm"
        
        var text = "\n[BUGÜNKÜ TAKVİM (İstanbul)]:\n"
        for ev in events {
            let start = formatter.string(from: ev.startDate)
            let end = formatter.string(from: ev.endDate)
            text += "- \(start) - \(end): \(ev.title)\(ev.location.isEmpty ? "" : " (@ \(ev.location))")\n"
        }
        return text
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
    
    public func deleteEvent(identifier: String) throws {
        if let event = eventStore.event(withIdentifier: identifier) {
            try eventStore.remove(event, span: .thisEvent)
        }
    }
    
    // Doğal dil Türkçe tarih ve saat çözümleme
    // Örnek: "Yarın saat 14:00'te toplantı", "Bugün saat 16:30 kahve"
    public static func parseNaturalLanguageEvent(from text: String) -> (title: String, startDate: Date, endDate: Date)? {
        let lower = text.lowercased()
        let calendar = Calendar.current
        var baseDate = Date()
        
        if lower.contains("yarın") {
            baseDate = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        } else if lower.contains("öbür gün") || lower.contains("sonraki gün") {
            baseDate = calendar.date(byAdding: .day, value: 2, to: baseDate) ?? baseDate
        }
        
        var targetHour: Int = 10
        var targetMinute: Int = 0
        
        // Regex ile saat bulma (örn: 14:30, 15:00 veya 14'te, saat 16)
        if let range = lower.range(of: #"(saat\s*)?([01]?[0-9]|2[0-3])(:([0-5][0-9]))?"#, options: .regularExpression) {
            let match = String(lower[range])
            let digitsOnly = match.replacingOccurrences(of: "saat", with: "").trimmingCharacters(in: .whitespaces)
            let parts = digitsOnly.split(separator: ":")
            if let h = Int(parts[0]) {
                targetHour = h
            }
            if parts.count > 1, let m = Int(parts[1]) {
                targetMinute = m
            }
        } else if lower.contains("öğleden sonra") {
            targetHour = 14
        } else if lower.contains("akşam") {
            targetHour = 19
        } else if lower.contains("sabah") {
            targetHour = 9
        }
        
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = targetHour
        components.minute = targetMinute
        components.timeZone = TimeZone(identifier: "Europe/Istanbul")
        
        guard let startDate = calendar.date(from: components) else { return nil }
        let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate.addingTimeInterval(3600)
        
        // Başlığı temizle
        var cleanTitle = text
        let removals = ["toplantı ekle", "etkinlik ekle", "takvime ekle", "takvime kaydet", "yarın", "bugün", "saat", "lütfen"]
        for r in removals {
            cleanTitle = cleanTitle.replacingOccurrences(of: r, with: "", options: .caseInsensitive)
        }
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty { cleanTitle = "Yeni Etkinlik" }
        
        return (title: cleanTitle, startDate: startDate, endDate: endDate)
    }
}
