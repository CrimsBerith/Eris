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
    // Örnek: "Yarın saat 14:00'te toplantı", "Bugün 16.30 kahve", "Pazartesi saat 10'da sunum", "Akşam 8 yemek"
    public static func parseNaturalLanguageEvent(from text: String) -> (title: String, startDate: Date, endDate: Date)? {
        let lower = text.lowercased()
        let calendar = Calendar.current
        var baseDate = Date()
        
        // 1. Gün Tespiti
        if lower.contains("yarın") {
            baseDate = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        } else if lower.contains("öbür gün") || lower.contains("sonraki gün") {
            baseDate = calendar.date(byAdding: .day, value: 2, to: baseDate) ?? baseDate
        } else {
            // Haftanın günleri (Pazartesi: 2, Salı: 3, ... Pazar: 1 in Gregorian)
            let weekdays: [(name: String, weekday: Int)] = [
                ("pazartesi", 2), ("salı", 3), ("çarşamba", 4),
                ("perşembe", 5), ("cuma", 6), ("cumartesi", 7), ("pazar", 1)
            ]
            for item in weekdays {
                if lower.contains(item.name) {
                    let currentWeekday = calendar.component(.weekday, from: baseDate)
                    var daysToAdd = item.weekday - currentWeekday
                    if daysToAdd <= 0 { daysToAdd += 7 }
                    baseDate = calendar.date(byAdding: .day, value: daysToAdd, to: baseDate) ?? baseDate
                    break
                }
            }
        }
        
        var targetHour: Int?
        var targetMinute: Int = 0
        var matchedTimeSnippet: String?
        
        // 2. Saat Tespiti (Öncelik: HH:mm veya HH.mm formatı)
        let hhmmPattern = #"(?:saat\s*)?([01]?[0-9]|2[0-3])[:.]([0-5][0-9])(?:'?\s*(?:te|ta|de|da))?"#
        if let regex = try? NSRegularExpression(pattern: hhmmPattern, options: []),
           let match = regex.firstMatch(in: lower, options: [], range: NSRange(location: 0, length: lower.utf16.count)) {
            if let hRange = Range(match.range(at: 1), in: lower),
               let mRange = Range(match.range(at: 2), in: lower),
               let h = Int(lower[hRange]),
               let m = Int(lower[mRange]) {
                targetHour = h
                targetMinute = m
                if let fullRange = Range(match.range, in: lower) {
                    matchedTimeSnippet = String(lower[fullRange])
                }
            }
        }
        
        // 3. Saat Tespiti: "saat 14", "saat 9" veya "14'te", "9'da"
        if targetHour == nil {
            let singleHourPattern = #"(?:saat\s*([01]?[0-9]|2[0-3])|([01]?[0-9]|2[0-3])\s*'?\s*(?:te|ta|de|da)\b)"#
            if let regex = try? NSRegularExpression(pattern: singleHourPattern, options: []),
               let match = regex.firstMatch(in: lower, options: [], range: NSRange(location: 0, length: lower.utf16.count)) {
                let range1 = match.range(at: 1)
                let range2 = match.range(at: 2)
                if range1.location != NSNotFound, let r = Range(range1, in: lower), let h = Int(lower[r]) {
                    targetHour = h
                } else if range2.location != NSNotFound, let r = Range(range2, in: lower), let h = Int(lower[r]) {
                    targetHour = h
                }
                if let fullRange = Range(match.range, in: lower) {
                    matchedTimeSnippet = String(lower[fullRange])
                }
            }
        }
        
        // 4. Günün Vakti Niteleyicileri (sabah, öğlen, akşam)
        let isEvening = lower.contains("akşam") || lower.contains("gece")
        let isAfternoon = lower.contains("öğleden sonra")
        let isMorning = lower.contains("sabah")
        let isNoon = lower.contains("öğle") || lower.contains("öğlen")
        
        if let h = targetHour {
            // Eğer "akşam 7" veya "öğleden sonra 3" dendiyse 12 saat ekle
            if (isEvening || isAfternoon) && h < 12 {
                targetHour = h + 12
            }
        } else {
            // Saat açıkça belirtilmemişse varsayılan saat ata
            if isEvening {
                targetHour = 19
            } else if isAfternoon {
                targetHour = 14
            } else if isNoon {
                targetHour = 12
                targetMinute = 30
            } else if isMorning {
                targetHour = 9
            } else {
                targetHour = 10
            }
        }
        
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = targetHour ?? 10
        components.minute = targetMinute
        components.second = 0
        components.timeZone = TimeZone(identifier: "Europe/Istanbul")
        
        guard let startDate = calendar.date(from: components) else { return nil }
        let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate.addingTimeInterval(3600)
        
        // 5. Başlığı Temizle
        var cleanTitle = text
        if let snippet = matchedTimeSnippet {
            cleanTitle = cleanTitle.replacingOccurrences(of: snippet, with: " ", options: .caseInsensitive)
        }
        let removals = [
            "toplantı ekle", "etkinlik ekle", "takvime ekle", "takvime kaydet", "randevu ekle",
            "yarın", "öbür gün", "sonraki gün", "bugün", "sabah", "öğleden sonra", "akşam", "gece",
            "pazartesi", "salı", "çarşamba", "perşembe", "cuma", "cumartesi", "pazar",
            "saat", "lütfen", "ekle", "kaydet", "'te", "'ta", "'de", "'da"
        ]
        for r in removals {
            cleanTitle = cleanTitle.replacingOccurrences(of: r, with: " ", options: .caseInsensitive)
        }
        // Fazla boşlukları temizle
        cleanTitle = cleanTitle.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        if cleanTitle.isEmpty { cleanTitle = "Yeni Etkinlik" }
        
        return (title: cleanTitle, startDate: startDate, endDate: endDate)
    }
}
