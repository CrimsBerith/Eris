import Foundation
import UserNotifications

public final class MorningBriefingService: @unchecked Sendable {
    public static let shared = MorningBriefingService()
    
    public var isBriefingEnabled: Bool = true
    public var briefingHour: Int = 8
    public var briefingMinute: Int = 30
    
    private init() {}
    
    public func requestNotificationPermission() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    public func scheduleDailyBriefing() {
        guard isBriefingEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["eris_morning_briefing"])
            return
        }
        
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["eris_morning_briefing"])
        
        let content = UNMutableNotificationContent()
        content.title = "Eris — Günlük Brifing Hazır"
        content.body = "Bugünkü ajandanız, piyasa güncellemeleri ve kasanızdaki önemli notlarınız hazır."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = briefingHour
        dateComponents.minute = briefingMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "eris_morning_briefing", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Brifing bildirimi kurulamadı: \(error)")
            }
        }
    }
    
    // Yürüyüş / Kulaklık / Yoldayken: "Bugünkü planlarımız nedir?"
    public func generateWalkingAgendaBriefing() -> String {
        let todayEvents = CalendarCapability.shared.getTodayEvents()
        let markets = ExternalDataService.shared.getMarketSummary()
        let usd = markets.first(where: { $0.symbol == "USDTRY" })?.price ?? "34.18"
        let eur = markets.first(where: { $0.symbol == "EURTRY" })?.price ?? "38.22"
        let marine = ExternalDataService.shared.getMarineWeather()
        
        // 1. Ajandayı saat saat sırala
        var agendaSection = ""
        if todayEvents.isEmpty {
            agendaSection = "Bugün ajandanda planlı bir toplantı görünmüyor, tasarımlarına ve atölyeye odaklanmak için harika bir gün."
        } else {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
            formatter.dateFormat = "HH:mm"
            
            let eventStrings = todayEvents.map { ev in
                let time = formatter.string(from: ev.startDate)
                let loc = ev.location.isEmpty ? "" : " (\(ev.location))"
                return "Saat \(time)'de \(ev.title)\(loc)"
            }
            agendaSection = "Bugünkü planlarımız şöyle: " + eventStrings.joined(separator: ", ") + "."
        }
        
        // 2. Aktif Özel Ajan Perspektifi
        let activeAgent = ErisAgentPersonaManager.shared.activeModule
        let agentPerspectiveTR: String
        let agentPerspectiveEN: String
        if let agent = activeAgent {
            agentPerspectiveTR = "Aktif Ajan (\(agent.title)): \(agent.subtitle)."
            agentPerspectiveEN = "Active Agent (\(agent.title)): \(agent.subtitle)."
        } else {
            agentPerspectiveTR = "Hedeflerin ve projelerin için odaklanma zamanı."
            agentPerspectiveEN = "Prime time to focus on your key objectives and projects."
        }
        
        // 3. Piyasa & Ekonomi Nabzı
        let economyUpdate = "Piyasalar: Dolar \(usd), Euro \(eur) seviyesinde."
        
        // 4. Hafızadaki Önemli Notlar
        let userMemories = ErisMemoryDatabase.shared.getAllMemories().filter { $0.pinned || $0.category == .preference || $0.category == .fabricCost || $0.category == .designIdea }
        
        let lang = ErisLanguageManager.shared.currentLanguage
        if lang == .english {
            var agendaSection = ""
            if todayEvents.isEmpty {
                agendaSection = "No meetings scheduled on your calendar today—a clear runway to focus on deep work and creative goals."
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                let eventStrings = todayEvents.map { ev in
                    let time = formatter.string(from: ev.startDate)
                    let loc = ev.location.isEmpty ? "" : " (\(ev.location))"
                    return "At \(time): \(ev.title)\(loc)"
                }
                agendaSection = "Here is today's schedule: " + eventStrings.joined(separator: ", ") + "."
            }
            
            let economyUpdate = "Market benchmarks: USD/TRY at \(usd), EUR/TRY at \(eur)."
            var memoryNote = ""
            if let top = userMemories.first {
                memoryNote = " Memory note: \(top.content)"
            }
            
            return """
            Hey, you're on the move—here is your daily briefing.
            \(agendaSection)
            \(agentPerspectiveEN)
            \(economyUpdate)
            Weather in \(marine.location): \(Int(marine.airTempCelsius))°C, wind \(marine.windDirection).\(memoryNote)
            You're ready for the day. I'm right beside you.
            """
        }
        
        var memoryNote = ""
        if let top = userMemories.first {
            memoryNote = " Aklında olsun: \(top.content)"
        }
        
        return """
        Selam, yoldasın, hemen planlarımızı geçiyorum.
        \(agendaSection)
        \(agentPerspectiveTR)
        \(economyUpdate)
        Hava \(marine.location) tarafında \(Int(marine.airTempCelsius)) derece, rüzgar \(marine.windDirection).\(memoryNote)
        Güne hazırsın, ben buradayım.
        """
    }
    
    public func generateBriefingText() -> String {
        return generateWalkingAgendaBriefing()
    }
}
